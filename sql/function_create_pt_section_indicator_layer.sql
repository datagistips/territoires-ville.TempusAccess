CREATE OR REPLACE FUNCTION tempus_access.create_pt_section_indicator_layer(
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
    time_start time without time zone,
    time_end time without time zone,
    time_ag integer,
    area_type integer,
    areas character varying[],
    route integer,
    stop_area integer)
  RETURNS void AS
$BODY$
DECLARE
    s character varying;
    t character varying; 
    indics_time_ag character varying;
    indics_day_ag character varying;
    from_table_day_ag character varying;
    r record;
    
    time_filter character varying;
    areas_filter character varying;
    routes_filter character varying;
    stops_filter character varying;

BEGIN
-- Obligatory parameters
    IF (gtfs_feeds is null or route_types is null or agencies is null or indics is null or array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 OR array_length(agencies, 1)=0 OR array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1 to 4 must be non-empty arrays';
    END IF;
    
    -- Facultative parameters
    
    -- Areas filter
    IF (area_type=-1 OR array_length(areas,1)=0 OR areas IS NULL)
    THEN areas_filter = $$$$;
    ELSE areas_filter = $$ 
                        AND (
                        (stops1.stop_id IN 
                        (
                            SELECT stop_id 
                            FROM tempus_gtfs.stops, tempus_access.area_type$$ || area_type::character varying || $$ area
                            WHERE st_within(stops.geom, area.geom) = TRUE AND ARRAY[area.char_id] <@ '$$ || areas::character varying || $$'
                        ))
                        OR 
                        (stops2.stop_id IN 
                        (
                            SELECT stop_id 
                            FROM tempus_gtfs.stops, tempus_access.area_type$$ || area_type::character varying || $$ area
                            WHERE st_within(stops.geom, area.geom) = TRUE AND ARRAY[area.char_id] <@ '$$ || areas::character varying || $$'
                        ))
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
    
    -- Stops filter : sections must begin or end at the specified stops
    IF (stop_area IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$
                        AND 
                        (
                        ((stops1.feed_id, stops1.parent_station_id) = (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $$ || stop_area::character varying || $$)) 
                        OR 
                        ((stops2.feed_id, stops2.parent_station_id) = (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $$ || stop_area::character varying || $$)) 
                        )
                        $$; 
    END IF;
    
    -- Time filter
    IF (time_start IS NULL OR time_end IS NULL)
    THEN time_filter = $$(1=1)$$;
    ELSE time_filter = $$((s1.departure_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$') AND (s1.departure_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$'))))$$;
    END IF; 
    
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    from_table_day_ag = ''; 
    
    CREATE SCHEMA IF NOT EXISTS indic; 
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        IF (r.col_name = 'serv_num') -- Number of services
        THEN 
            indics_time_ag = indics_time_ag  || '(count(distinct trip_id))::integer as serv_num, '; 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(serv_num)::double precision as serv_num, ';
        END IF; 
        
        IF (r.col_name = 'first_serv') -- First service
        THEN 
            indics_time_ag = indics_time_ag || 'min(departure_time) as first_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(first_serv))::character varying || '' seconds'')::interval)::character varying as first_serv, ';
        END IF; 
        
        IF (r.col_name = 'last_serv') -- Last service
        THEN 
            indics_time_ag = indics_time_ag || 'max(departure_time) as last_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv))::character varying || '' seconds'')::interval)::character varying as last_serv, ';
        END IF;
        
        IF (r.col_name = 'time_ampl') -- Time amplitude
        THEN 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv-first_serv)/3600::double precision as time_ampl, ';
        END IF;
        
        IF (r.col_name = 'total_time') -- Total travel time
        THEN 
            indics_time_ag = indics_time_ag || (CASE WHEN time_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = time_ag) END)::character varying || '(arrival_time-departure_time) as total_time, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(total_time))::character varying || '' seconds'')::interval)::character varying as total_time, '; 
        END IF; 
        
        IF (r.col_name = 'total_dist') -- Total distance
        THEN 
            indics_time_ag = indics_time_ag || '(st_length(st_transform(geom, 2154))/1000)::double precision as total_dist, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(total_dist)::double precision as total_dist, '; 
        END IF;
        
        IF (r.col_name = 'veh_km') -- Vehicle.km
        THEN
            indics_time_ag = indics_time_ag || '(st_length(st_transform(geom, 2154))/1000*count(distinct trip_id))::double precision as veh_km, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(veh_km) as veh_km, '; 
        END IF; 
        
        IF (r.col_name = 'routes') -- List of used routes
        THEN 
            indics_time_ag = indics_time_ag || 'array_agg(DISTINCT route_long_name) as routes, ';
            indics_day_ag = indics_day_ag || 'array_agg(DISTINCT unnested_routes) as routes, '; 
            from_table_day_ag = ', unnest(routes) as unnested_routes'; 
        END IF; 
        
    END LOOP;
    
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2);
    
    s = $$
    DROP TABLE IF EXISTS indic.sections; 
    CREATE TABLE indic.sections AS
    (
        WITH r AS (
            WITH q AS (
                -- Apply filters
                SELECT s1.feed_id, 
                       s1.stop_id as stop_id_from, 
                       stops1.stop_name as stop_name_from, 
                       s2.stop_id as stop_id_to, 
                       stops2.stop_name as stop_name_to, 
                       s1.trip_id, 
                       s1.departure_time, 
                       s2.arrival_time, 
                       routes.route_id, 
                       routes.route_long_name, 
                       routes.route_type, 
                       calendar_dates.date, 
                       st_force2D(sections.geom)::Geometry(Linestring, 4326) as geom
                FROM tempus_gtfs.sections JOIN tempus_gtfs.feed_info ON (sections.feed_id = feed_info.id)
                                          JOIN tempus_gtfs.stops stops1 ON (stops1.feed_id = feed_info.feed_id AND sections.stop_from = stops1.id)
                                          JOIN tempus_gtfs.stops stops2 ON (stops2.feed_id = feed_info.feed_id AND sections.stop_to = stops2.id)
                                          JOIN tempus_gtfs.stop_times s1 ON (s1.feed_id = feed_info.feed_id AND s1.stop_id = stops1.stop_id)
                                          JOIN tempus_gtfs.stop_times s2 ON (s2.feed_id = feed_info.feed_id AND s2.stop_id = stops2.stop_id AND s1.trip_id = s2.trip_id AND s1.stop_sequence=s2.stop_sequence - 1)
                                          JOIN tempus_gtfs.trips ON (trips.feed_id = feed_info.feed_id AND trips.trip_id = s1.trip_id)
                                          JOIN tempus_gtfs.routes ON (routes.feed_id = feed_info.feed_id AND routes.route_id = trips.route_id)
                                          JOIN tempus_gtfs.calendar_dates ON (calendar_dates.feed_id = feed_info.feed_id AND calendar_dates.service_id = trips.service_id)
                                          JOIN tempus_gtfs.agency ON (agency.feed_id = routes.feed_id AND agency.agency_id = routes.agency_id)
                WHERE stops1.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || gtfs_feeds::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[routes.route_type] <@ '$$ || route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency.id] <@ '$$ || agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[calendar_dates.date] <@ '$$ || (SELECT array_agg(days) FROM tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$' -- Days filter
                  AND $$ || time_filter || $$ -- Time filter
                  $$ || areas_filter || $$ -- Facultative : areas filter
                  $$ || routes_filter || $$ -- Facultative : routes filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
            )
            (
            -- Aggregate day by day
                ( -- Mode by mode
                    SELECT feed_id, 
                           stop_id_from, 
                           stop_name_from, 
                           stop_id_to, 
                           stop_name_to, 
                           route_type, 
                           date, 
                           $$ || indics_time_ag || $$ , 
                           geom
                    FROM q
                    GROUP BY feed_id, 
                             stop_id_from, 
                             stop_name_from, 
                             stop_id_to, 
                             stop_name_to, 
                             route_type, 
                             date, 
                             geom
                ) 
            )
        )
        -- Aggregate days together
        SELECT row_number() over() as gid, 
               feed_id, 
               stop_id_from, 
               stop_name_from, 
               stop_id_to, 
               stop_name_to, 
               route_type, 
               $$ || indics_day_ag || $$ , 
               geom as the_geom
        FROM r $$ || from_table_day_ag || $$ 
        GROUP BY feed_id, 
                 stop_id_from, 
                 stop_name_from, 
                 stop_id_to, 
                 stop_name_to, 
                 geom, 
                 route_type
    );
    
    ALTER TABLE indic.sections ADD COLUMN symbol_size real;
    ALTER TABLE indic.sections ADD COLUMN symbol_color real;
    ALTER TABLE indic.sections ADD CONSTRAINT sections_pkey PRIMARY KEY(gid);
    $$;
    
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'sections';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,days,day_type,per_type,per_start,per_end,day_ag,time_start,time_end,time_ag,area_type,areas,route,stop,gtfs_feeds,agencies,pt_modes,req)
    VALUES ('sections', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'sections')::character varying, 
           $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce(day_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce(time_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(area_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || areas::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
           $$ || coalesce($$'$$ || route::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || stop_area::character varying || $$'$$, $$NULL$$) || $$::integer, 
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
