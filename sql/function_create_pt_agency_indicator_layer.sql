CREATE OR REPLACE FUNCTION tempus_access.create_pt_agency_indicator_layer(
                                                                                indics integer[],
                                                                                gtfs_feeds integer[],
                                                                                route_types integer[], 
                                                                                day date,
                                                                                day_type integer,
                                                                                per_type integer, 
                                                                                per_start date, 
                                                                                per_end date, 
                                                                                day_ag integer,
                                                                                time_start time,
                                                                                time_end time, 
                                                                                area_type integer, 
                                                                                areas character varying[],
                                                                                stop integer
                                                                         )
RETURNS void AS
$BODY$

DECLARE
s character varying;
t character varying; 
r record; 
indics_day_ag character varying;
indics_time_ag character varying;
time_filter character varying;
areas_filter character varying;
stops_filter character varying;
from_table_day_ag character varying;
from_table_time_ag character varying;

area2 boolean;
join_area character varying;
indics_str character varying;

BEGIN
    -- Obligatory parameters
    IF (array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 OR array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1, 2, 3 and 4 must be non-empty arrays';
    END IF;
    
    -- Facultative parameters
    
    -- Time filter
    IF (time_start IS NULL OR time_end IS NULL)
    THEN time_filter = $$(1=1)$$;
    ELSE time_filter = $$((s.departure_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$') AND (s.departure_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$'))))$$;
    END IF;  
    
    indics_time_ag='';
    indics_day_ag = '';
    from_table_time_ag = ''; 
    from_table_day_ag = ''; 
    
    -- Areas filter
    IF (area_type = -1 OR array_length(areas, 1)=0 OR areas IS NULL)
    THEN areas_filter = $$$$;
    ELSE areas_filter = $$ 
                        AND routes.id IN 
                        (
                            SELECT routes.id
                            FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id)
                                                    JOIN tempus_gtfs.stop_times ON (trips.trip_id = stop_times.trip_id AND trips.feed_id = stop_times.feed_id)
                                                    JOIN tempus_gtfs.stops ON (stop_times.stop_id = stops.stop_id AND stop_times.feed_id = stops.feed_id)
                            WHERE stops.id IN 
                                (
                                    SELECT stops.id
                                    FROM tempus_gtfs.stops JOIN tempus_access.area_type$$ || area_type::character varying || $$ area ON st_within(stops.geom, area.geom)
                                    WHERE ARRAY[area.char_id] <@ '$$ || areas::character varying || $$'
                                )
                        )
                        $$;
    END IF;
    
    -- Stops filter : selected agencies must serve at least one stop of the parameter set
    IF (stop IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$ 
                        AND agency.id IN
                        (
                            SELECT agency.id
                            FROM tempus_gtfs.agency JOIN tempus_gtfs.routes ON (agency.agency_id = routes.agency_id AND agency.feed_id = routes.feed_id)
                                                    JOIN tempus_gtfs.trips ON (trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id)
                                                    JOIN tempus_gtfs.stop_times ON (trips.trip_id = stop_times.trip_id AND trips.feed_id = stop_times.feed_id)
                                                    JOIN tempus_gtfs.stops ON (stop_times.stop_id = stops.stop_id AND stop_times.feed_id = stops.feed_id)
                            WHERE stops.id IN (
                                    SELECT stops.id 
                                    FROM tempus_gtfs.stops JOIN tempus_gtfs.stops parent_stops ON (parent_stops.feed_id = stops.feed_id AND parent_stops.stop_id = stops.parent_station_id) 
                                    WHERE parent_stops.id = $$ || stop::character varying || $$
                                    )
                        ) 
                        $$;
    END IF;
    
    CREATE SCHEMA IF NOT EXISTS indic; 
    
    area2=False;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        if (r.col_name = 'veh_km') -- Vehicles.km
        THEN 
            indics_time_ag = indics_time_ag || 'sum(dist_km) as veh_km, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(veh_km)::double precision as veh_km, '; 
        END IF; 
        
        IF ((area2 = False) AND ((r.col_name = 'area2_list') OR (r.col_name = 'area2_pop'))) -- List of type 2 areas 2 served by public transport
        THEN
            area2=True;
            indics_str = ', array_agg(DISTINCT char_id ORDER BY char_id) AS area2_list';
            join_area = ' LEFT JOIN tempus_access.area_type2 area ON (st_within(stops.geom, area.geom)) ';   
            indics_day_ag = indics_day_ag || 'array_agg(DISTINCT unnested_area2_list ORDER BY unnested_area2_list) AS area2_list, ';
            from_table_day_ag = ', unnest(r.area2_list) as unnested_area2_list'; 
            indics_time_ag = indics_time_ag || 'array_agg(DISTINCT unnested_area2_list) as area2_list, '; 
            from_table_time_ag = ', unnest(area2_list) as unnested_area2_list'; 
        END IF;        
        
    END LOOP; 
    
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2);
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);
    
    
    
    s = $$
        DROP TABLE IF EXISTS indic.agencies;
        CREATE TABLE indic.agencies AS
        (
            WITH r AS (
                 WITH q AS (
                    -- Apply filters
                    SELECT s.feed_id, 
                           agency.agency_id, 
                           agency.agency_name, 
                           trips.trip_id, 
                           routes.route_type, 
                           calendar_dates.date, 
                           st_length(st_transform(shapes.geom_multi, 2154))/1000 as dist_km
                           $$ || indics_str || $$ -- Communes
                    FROM tempus_gtfs.stop_times s JOIN tempus_gtfs.stops ON (s.feed_id = stops.feed_id AND s.stop_id = stops.stop_id)
                                                  JOIN tempus_gtfs.trips ON (s.feed_id = trips.feed_id AND s.trip_id = trips.trip_id)
                                                  JOIN tempus_gtfs.routes ON (routes.route_id = trips.route_id AND routes.feed_id = trips.feed_id)
                                                  JOIN tempus_gtfs.shapes ON (shapes.feed_id = trips.feed_id AND shapes.shape_id = trips.shape_id)
                                                  JOIN tempus_gtfs.calendar_dates ON (calendar_dates.feed_id = trips.feed_id AND calendar_dates.service_id = trips.service_id)
                                                  JOIN tempus_gtfs.agency ON (agency.agency_id = routes.agency_id)
                                                  $$ || join_area || $$ 
                WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || gtfs_feeds::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[calendar_dates.date] <@ '$$ || (SELECT array_agg(days) FROM tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$' -- Days filter
                  AND $$ || time_filter || $$ -- Time filter
                  $$ || areas_filter || $$ -- Facultative : areas filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
                    GROUP BY s.feed_id, 
                             agency.agency_id, 
                             agency.agency_name, 
                             trips.trip_id, 
                             routes.route_type, 
                             routes.route_id, 
                             calendar_dates.date, 
                             shapes.geom_multi
                )
                -- Aggregate day by day
                (-- Mode by mode
                    SELECT feed_id, 
                           agency_id, 
                           agency_name, 
                           route_type, 
                           date, 
                           $$ || indics_time_ag || $$ 
                    FROM q $$ || from_table_time_ag || $$ 
                    GROUP BY feed_id, agency_id, agency_name, route_type, date
                )
                UNION
                ( -- Group modes together
                    SELECT feed_id, 
                           agency_id, 
                           agency_name, 
                           8, 
                           date, 
                           $$ || indics_time_ag || $$ 
                    FROM q $$ || from_table_time_ag || $$ 
                    GROUP BY feed_id, agency_id, agency_name, date
                )
            )
            SELECT row_number() over() as gid, 
                   feed_id, 
                   agency_id, 
                   agency_name, 
                   route_type, 
                   $$ || indics_day_ag || $$ 
            FROM r $$ || from_table_day_ag || $$ 
            GROUP BY feed_id, 
                     agency_id, 
                     agency_name, 
                     route_type
        );
    ALTER TABLE indic.agencies ADD CONSTRAINT agencies_pkey PRIMARY KEY(gid);
    $$;
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        IF (r.col_name = 'area2_pop')
        THEN
            t=$$ALTER TABLE indic.agencies ADD COLUMN area2_pop double precision;
            UPDATE indic.agencies SET area2_pop = q.population
            FROM
            (
                SELECT agencies.gid, sum(area.population) as population
                FROM indic.agencies JOIN tempus_access.area_type2 area ON ARRAY[area.char_id] <@ agencies.area2_list
                GROUP BY agencies.gid
            ) q
            WHERE q.gid = agencies.gid;
            UPDATE indic.agencies SET area2_pop = NULL WHERE TRUE = ANY (SELECT unnest(area2_list) IS NULL);
            $$;
            EXECUTE(t);
            RAISE NOTICE '%', t; 
        END IF; 
    END LOOP; 
    
    
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'agencies';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,days,day_type,per_type,per_start,per_end,day_ag,time_start,time_end,area_type,areas,stop,gtfs_feeds,pt_modes,req)
    VALUES ('agencies', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'agencies')::character varying, 
           $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce(day_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce(area_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || areas::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
           $$ || coalesce($$'$$ || stop::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || gtfs_feeds::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE array[gtfs_route_type]<@ '$$ || route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || gtfs_feeds::character varying || $$')::integer[], 
           '$$ || replace(s, $$'$$, $$''$$) || $$' );$$;
    RAISE NOTICE '%', t;
    EXECUTE(t);
    
    
    
    RETURN;
    
END; 

$BODY$
LANGUAGE plpgsql;
  
  
