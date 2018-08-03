CREATE OR REPLACE FUNCTION tempus_access.create_pt_stop_indicator_layer(
                                                                            indics integer[], 
                                                                            gtfs_feeds integer[],
                                                                            route_types integer[], 
                                                                            agencies integer[], 
                                                                            location_type integer, 
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
                                                                            route integer
                                                                        )
RETURNS void AS
$BODY$
DECLARE
    s character varying;
    t character varying; 
    indics_time_ag character varying;
    indics_day_ag character varying;
    indic_map character varying;
    join_area character varying; 
    r record;
    layer character varying; 
    
    time_filter character varying;
    areas_filter character varying;
    routes_filter character varying;

    indics_str character varying;
    area2 boolean;

BEGIN
    
    -- Obligatory parameters
    IF (gtfs_feeds is null or route_types is null or agencies is null or indics is null or location_type is null or array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 OR array_length(agencies, 1)=0 OR array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1 to 5 must be non-empty arrays';
    END IF;
    
    -- Facultative parameters
    
    -- Areas filter
    IF (area_type=-1 OR array_length(areas,1)=0 OR areas IS NULL)
    THEN areas_filter = $$$$;
    ELSE areas_filter = $$ 
                        AND stops.id IN 
                        (
                            SELECT stops.id 
                            FROM tempus_gtfs.stops, tempus_access.area_type$$ || area_type::character varying || $$ area
                            WHERE st_within(stops.geom, area.geom) = TRUE AND ARRAY[area.char_id] <@ '$$ || areas::character varying || $$'
                        )
                        $$;
    END IF;
    
    -- Routes filter : trips must belong to the specified routes
    IF (route IS NULL)
    THEN routes_filter = $$$$;
    ELSE routes_filter = $$ 
                         AND routes.id = $$ || route::character varying || $$
                         $$;
    END IF;
    
    -- Time filter
    IF (time_start IS NULL OR time_end IS NULL)
    THEN time_filter = $$(1=1)$$;
    ELSE time_filter = $$(
                            ((stop_times.departure_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$')) AND (stop_times.departure_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$')))
                         OR ((stop_times.arrival_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$')) AND (stop_times.arrival_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$')))
                         )$$;
    END IF; 
    
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    join_area = '';
    indics_str='';
    
    CREATE SCHEMA IF NOT EXISTS indic; 

    IF location_type=0 THEN layer = 'stops';
    ELSE layer = 'stop_areas';
    END IF; 
    
    area2 = False;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        IF (r.col_name = 'serv_num') -- Number of services
        THEN 
            indics_time_ag = indics_time_ag  || '(count(distinct trip_id))::integer as serv_num, '; 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(serv_num)::double precision as serv_num, ';
        END IF; 
        
        IF (r.col_name = 'first_serv') -- First service
        THEN 
            indics_time_ag = indics_time_ag || 'least(min(arrival_time), min(departure_time)) as first_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(first_serv))::character varying || '' seconds'')::interval)::character varying as first_serv, ';
        END IF; 
        
        IF (r.col_name = 'last_serv') -- Last service
        THEN 
            indics_time_ag = indics_time_ag || 'greatest(max(arrival_time), max(departure_time)) as last_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv))::character varying || '' seconds'')::interval)::character varying as last_serv, ';
        END IF;
        
        IF (r.col_name = 'time_ampl') -- Time amplitude
        THEN 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv-first_serv)/3600::double precision as time_ampl, ';
        END IF;
        
        IF ((area2 = False) AND ((r.col_name = 'area2_list') OR (r.col_name = 'area2_pop'))) -- List of type 2 areas 2 served by public transport
        THEN
            area2=True;
            indics_str = indics_str || ', area.char_id as area2_list';
            join_area = ' LEFT JOIN tempus_access.area_type2 area ON (st_within(stops.geom, area.geom)) ';   
            indics_time_ag = indics_time_ag || 'min(area2_list) as area2_list, ';
            indics_day_ag = indics_day_ag || 'min(area2_list) as area2_list, '; 
        END IF;
        
        IF (r.col_name = 'area2_pop') -- Population of the type 2 area served by the stop
        THEN
            indics_str = indics_str || ', area.population as area2_pop';
            indics_time_ag = indics_time_ag || 'min(area2_pop) as area2_pop, ';
            indics_day_ag = indics_day_ag || 'min(area2_pop) as area2_pop, ';
        END IF; 
        
    END LOOP; 
    
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2); 
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);

    s = $$
    DROP TABLE IF EXISTS indic.$$ || layer || $$ ;
    CREATE TABLE indic.$$ || layer || $$ AS
    (
        WITH r AS (        
            WITH q AS (
                -- Apply filters
                SELECT CASE WHEN $$ || location_type::character varying || $$=0 THEN stops.stop_id 
                            WHEN $$ || location_type::character varying || $$=1 THEN stops.parent_station_id 
                       END as stop_id, 
                       CASE WHEN $$ || location_type::character varying || $$=0 THEN stops.stop_name 
                            WHEN $$ || location_type::character varying || $$=1 THEN (SELECT stop_name FROM tempus_gtfs.stops parent WHERE (stops.parent_station_id = parent.stop_id AND parent.feed_id = stops.feed_id))
                       END as stop_name, 
                       CASE WHEN $$ || location_type::character varying || $$=0 THEN stops.geom
                            WHEN $$ || location_type::character varying || $$=1 THEN (SELECT geom FROM tempus_gtfs.stops parent WHERE (stops.parent_station_id = parent.stop_id AND parent.feed_id = stops.feed_id))
                       END as the_geom, 
                       routes.feed_id, 
                       routes.route_type, 
                       calendar_dates.date, 
                       stop_times.trip_id, 
                       stop_times.arrival_time, 
                       stop_times.departure_time
                       $$ || indics_str || $$ -- Communes
                FROM tempus_gtfs.stops JOIN tempus_gtfs.stop_times ON (stop_times.stop_id=stops.stop_id AND stop_times.feed_id = stops.feed_id)
                                       JOIN tempus_gtfs.trips ON (trips.trip_id=stop_times.trip_id AND trips.feed_id=stop_times.feed_id)
                                       JOIN tempus_gtfs.calendar_dates ON (calendar_dates.feed_id = trips.feed_id AND calendar_dates.service_id = trips.service_id)
                                       JOIN tempus_gtfs.routes ON (routes.route_id=trips.route_id AND routes.feed_id=trips.feed_id)
                                       JOIN tempus_gtfs.agency ON (agency.feed_id = routes.feed_id AND agency.agency_id = routes.agency_id)
                                       $$ || join_area || $$ 
                WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || gtfs_feeds::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[routes.route_type] <@ '$$ || route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency.id] <@ '$$ || agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[calendar_dates.date] <@ '$$ || (SELECT array_agg(days) FROM tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$' -- Days filter
                  AND $$ || time_filter || $$ -- Time filter
                  $$ || areas_filter || $$ -- Facultative : areas filter
	              $$ || routes_filter || $$ -- Facultative : routes filter
            )
            (
                -- Aggregate day by day
                (-- Mode by mode
                    SELECT feed_id, 
                           stop_id, 
                           stop_name, 
                           st_force2D(the_geom)::Geometry(Point, 4326) as the_geom, 
                           route_type, 
                           date, 
                           $$ || indics_time_ag || $$ 
                    FROM q
                    GROUP BY feed_id, stop_id, stop_name, the_geom, route_type, date
                )
                UNION
                ( -- Group modes together
                    SELECT feed_id, 
                           stop_id, 
                           stop_name, 
                           st_force2D(the_geom)::Geometry(Point, 4326) as the_geom, 
                           8, 
                           date, 
                           $$ || indics_time_ag || $$ 
                    FROM q
                    GROUP BY feed_id, stop_id, stop_name, the_geom, date
                )
            )
        )
        -- Aggregate days together
        SELECT row_number() over() as gid, feed_id, stop_id, stop_name, the_geom, route_type, $$ || indics_day_ag || $$ 
        FROM r
        GROUP BY feed_id, stop_id, stop_name, the_geom, route_type
    );
    
    ALTER TABLE indic.$$ || layer || $$ ADD COLUMN symbol_size real;
    ALTER TABLE indic.$$ || layer || $$ ADD COLUMN symbol_color real;
    ALTER TABLE indic.$$ || layer || $$ ADD CONSTRAINT $$ || layer || $$_pkey PRIMARY KEY(gid);
    $$;
    
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = '$$ || layer || $$';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,days,day_type,per_type,per_start,per_end,day_ag,time_start,time_end,area_type,areas,route,gtfs_feeds,agencies,pt_modes, req)
    VALUES ('$$ || layer || $$', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = '$$ || layer || $$')::character varying, 
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
           $$ || coalesce($$'$$ || route::character varying || $$'$$, $$NULL$$) || $$::integer, 
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