CREATE OR REPLACE FUNCTION tempus_access.create_pt_route_indicator_layer(
                                                                            indics integer[],
                                                                            gtfs_feeds integer[],
                                                                            route_types integer[], 
                                                                            agencies integer[], 
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

BEGIN

    -- Obligatory parameters
    IF (array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 OR array_length(agencies, 1)=0 OR array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1, 2, 3 and 4 must be non-empty arrays';
    END IF;
    
    -- Facultative parameters
    
    -- Areas filter
    IF (array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 or array_length(agencies, 1)=0 or array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1, 2, 3 and 4 must be non-empty arrays';
    END IF;

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
    
    -- Stops filter : selected trips must serve at least one stop of the parameter set
    IF (stop IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$ 
                        AND routes.id IN
                        (
                            SELECT routes.id
                            FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id)
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
    
    -- Time filter
    IF (time_start IS NULL OR time_end IS NULL)
    THEN time_filter = $$(1=1)$$;
    ELSE time_filter = $$((s.departure_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$') AND (s.departure_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$'))))$$;
    END IF;
    raise notice '%', time_filter;
    
    indics_day_ag = '';
    indics_time_ag = ''; 
    
    
    CREATE SCHEMA IF NOT EXISTS indic; 
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        if (r.col_name = 'serv_num') -- Number of services
        THEN 
            indics_time_ag = indics_time_ag  || '(count(distinct trip_id)) as serv_num, '; 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(serv_num) as serv_num, ';
        END IF; 
        
        IF (r.col_name = 'veh_km') -- Vehicle.km
        THEN
            indics_time_ag = indics_time_ag || 'sum(st_length(st_transform(geom, 2154))/1000) as veh_km, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(veh_km) as veh_km, '; 
        END IF;        
        
    END LOOP; 
    
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2);
    
    
    s = $$DROP TABLE IF EXISTS indic.routes; 
    CREATE TABLE indic.routes AS
    (
        WITH r AS (
            WITH q AS (
                -- Apply filters
                SELECT s.feed_id, 
                       trips.trip_id, 
                       routes.route_id, 
                       routes.route_long_name, 
                       agency.agency_name, 
                       routes.route_type, 
                       calendar_dates.date, 
                       shapes.geom_multi as geom
                FROM tempus_gtfs.stop_times s JOIN tempus_gtfs.stops ON (s.feed_id = stops.feed_id AND s.stop_id = stops.stop_id)
                                              JOIN tempus_gtfs.trips ON (s.feed_id = trips.feed_id AND s.trip_id = trips.trip_id)
                                              JOIN tempus_gtfs.routes ON (routes.route_id = trips.route_id AND routes.feed_id = trips.feed_id)
                                              JOIN tempus_gtfs.shapes ON (shapes.feed_id = trips.feed_id AND shapes.shape_id = trips.shape_id)
                                              JOIN tempus_gtfs.calendar_dates ON (calendar_dates.feed_id = trips.feed_id AND calendar_dates.service_id = trips.service_id)
                                              JOIN tempus_gtfs.agency ON (agency.agency_id = routes.agency_id)
                WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || gtfs_feeds::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[routes.route_type] <@ '$$ || route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency.id] <@ '$$ || agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[calendar_dates.date] <@ '$$ || (SELECT array_agg(days) FROM tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$' -- Days filter
                  AND $$ || time_filter || $$ -- Time filter
                  $$ || areas_filter || $$ -- Facultative : areas filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
                GROUP BY s.feed_id, 
                         trips.trip_id, 
                         routes.route_id, 
                         routes.route_long_name, 
                         agency.agency_name, 
                         routes.route_type, 
                         calendar_dates.date, 
                         shapes.geom_multi
            )
            (
                SELECT feed_id, 
                       route_id, 
                       route_long_name, 
                       agency_name, 
                       route_type, 
                       date, 
                       $$ || indics_time_ag || $$ 
                FROM q
                GROUP BY feed_id, 
                         route_id, 
                         route_long_name, 
                         agency_name, 
                         route_type, 
                         date
            )
        ) 
        SELECT row_number() over() as gid, 
               feed_id, 
               route_id, 
               route_long_name,
               agency_name, 
               route_type, 
               $$ || indics_day_ag || $$ 
        FROM r
        GROUP BY feed_id
                 , route_id
                 , route_long_name
                 , agency_name
                 , route_type
    );
    ALTER TABLE indic.routes ADD CONSTRAINT routes_pkey PRIMARY KEY(gid);
    $$;
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'routes';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,days,day_type,per_type,per_start,per_end,day_ag,time_start,time_end,area_type,areas,stop,gtfs_feeds,agencies,pt_modes,req)
    VALUES ('routes', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'routes')::character varying, 
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
           $$ || coalesce($$'$$ || agencies::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE array[gtfs_route_type]<@ '$$ || route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || gtfs_feeds::character varying || $$')::integer[], 
           '$$ || replace(s, $$'$$, $$''$$) || $$' );$$;
    
    RAISE NOTICE '%', t;
    EXECUTE(t);
    
    
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 
  
  