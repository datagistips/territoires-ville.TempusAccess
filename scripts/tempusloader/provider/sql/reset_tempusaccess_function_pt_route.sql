CREATE OR REPLACE FUNCTION tempus_access.create_pt_route_indicator_layer(
                                                                           param_indics integer[],
                                                                           param_pt_networks integer[],
                                                                           param_route_types integer[], 
                                                                           param_agencies integer[], 
                                                                           param_day date,
                                                                           param_day_type integer,
                                                                           param_per_type integer, 
                                                                           param_per_start date, 
                                                                           param_per_end date, 
                                                                           param_day_ag integer,
                                                                           param_time_start time,
                                                                           param_time_end time, 
                                                                           param_time_ag integer,
                                                                           param_indic_zoning integer, 
                                                                           param_zoning_filter integer, 
                                                                           param_zones integer[],
                                                                           param_stop_area integer
                                                                        )
  RETURNS void AS
$BODY$
DECLARE

    s character varying;
    t character varying; 
    indics_time_ag character varying;
    indics_day_ag character varying;
    r record;
    
    days_list character varying;    
    time_ag_str character varying;
    day_ag_str character varying;
    
    zoning_table character varying;
    
    zones_filter character varying;
    stops_filter character varying;
    
    zones_list_indic boolean;
    zones_pop_indic boolean;

BEGIN

    IF (
            param_pt_networks is null OR 
            param_route_types is null OR
            param_agencies is null OR
            param_indics is null OR
            array_length(param_pt_networks, 1)=0 OR 
            array_length(param_route_types, 1)=0 OR 
            array_length(param_agencies, 1)=0 OR 
            array_length(param_indics, 1)=0
       )
    THEN 
        RAISE EXCEPTION 'Parameters 1 to 4 must be non-empty arrays';
    END IF;
    
    -- Default values for some parameters
    IF param_day_ag IS NULL THEN param_day_ag = 1; END IF;
    IF param_time_ag IS NULL THEN param_time_ag = 1; END IF;
    IF param_time_start IS NULL THEN param_time_start = '00:00:00'::time; END IF; 
    IF param_time_end IS NULL THEN param_time_end = '23:59:00'::time; END IF;    
    
    -- Facultative parameters    
    -- Zones filter
    SELECT INTO zoning_table
        name
    FROM zoning.zoning_source WHERE id = param_zoning_filter; 
        
    IF (param_zoning_filter IS NULL OR array_length(param_zones,1)=0 OR param_zones IS NULL)
    THEN zones_filter = $$$$;
    ELSE zones_filter = $$ 
                        AND route_id_int IN 
                        (
                            SELECT routes.id
                            FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.route_id_int = routes.id)
                                                    JOIN tempus_gtfs.stop_times ON (trips.id = stop_times.trip_id_int)
                                                    JOIN tempus_gtfs.stops ON (stop_times.stop_id_int = stops.id)
                            WHERE stops.id IN 
                            (
                                SELECT stops.id 
                                FROM tempus_gtfs.stops, zoning.$$ || zoning_table || $$ zoning
                                WHERE st_within(stops.geom, zoning.geom) = TRUE AND ARRAY[zoning.id] <@ '$$ || param_zones::character varying || $$'
                            )
                        )
                        $$;
    END IF;
    
    -- Stops filter : selected trips must serve at least one stop of the parameter set
    IF (param_stop_area IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$ 
                        AND routes_id_int IN
                        (
                            SELECT routes.id
                            FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id)
                                                    JOIN tempus_gtfs.stop_times ON (trips.trip_id = stop_times.trip_id AND trips.feed_id = stop_times.feed_id)
                                                    JOIN tempus_gtfs.stops ON (stop_times.stop_id = stops.stop_id AND stop_times.feed_id = stops.feed_id)
                            WHERE stops.id IN (
                                    SELECT stops.id 
                                    FROM tempus_gtfs.stops 
                                        JOIN tempus_gtfs.stops parent_stops 
                                            ON (parent_stops.feed_id = stops.feed_id AND parent_stops.stop_id = stops.parent_station_id) 
                                    WHERE parent_stops.id = $$ || param_stop_area || $$
                                    )
                        )
                        $$;
    END IF;
    
    SELECT INTO days_list
        CASE WHEN days IS NULL THEN '{}' ELSE days::character varying END
    FROM tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end);
    
    --Filtered data
    s = $$
        DROP TABLE IF EXISTS filtered_data;
        CREATE TEMPORARY TABLE filtered_data AS
        (
            -- Apply filters
                SELECT route_id_int,
                       feed_id, 
                       route_id, 
                       route_short_name, 
                       route_long_name, 
                       route_type,
                       agency_id_int,
                       agency_id,
                       agency_name, 
                       trip_id_int,
                       trip_id, 
                       date,
                       geom_trip
                FROM tempus_access.indic_complete_data 
                WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || param_pt_networks::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[route_type] <@ '$$ || param_route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency_id_int] <@ '$$ || param_agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[date] <@ '$$ || days_list || $$' -- Days filter
                  AND
                    (
                        (
                            (departure_time <= extract(epoch FROM INTERVAL '$$ || param_time_end::character varying || $$')) 
                            AND 
                            (departure_time >= extract(epoch FROM INTERVAL '$$ || param_time_start::character varying || $$'))
                        )
                        OR 
                        (
                            (arrival_time <= extract(epoch FROM INTERVAL '$$ || param_time_end::character varying || $$'))
                            AND 
                            (arrival_time >= extract(epoch FROM INTERVAL '$$ || param_time_start::character varying || $$'))
                        )
                    ) -- Time filter
                  $$ || zones_filter || $$ -- Facultative : areas filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
        );
    $$; 
    RAISE NOTICE '%', s;
    EXECUTE(s);
    
    -- Building indicators strings
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    zones_list_indic = False; 
    zones_pop_indic = False;
    
    SELECT INTO time_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_time_ag;
    
    SELECT INTO day_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_day_ag;
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics)
    LOOP 
        IF (r.col_name = 'zones_list')
        THEN zones_list_indic = True;
        ELSIF (r.col_name = 'zones_pop')
        THEN zones_pop_indic = True;
        ELSE
            indics_time_ag = indics_time_ag || (SELECT coalesce(replace(time_ag_routes, '%(time_ag)', time_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);
            indics_day_ag = indics_day_ag || (SELECT coalesce(replace(day_ag_routes, '%(day_ag)', day_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);         
        END IF;
    END LOOP; 
    
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2); 
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);

    -- Building daily aggregated data
    s= $$DROP TABLE IF EXISTS daily_aggregated_data; 
         CREATE TEMPORARY TABLE daily_aggregated_data AS
         (
                WITH all_days AS
                (
                    SELECT DISTINCT s.route_id_int, s.route_type, q.day_date
                    FROM 
                    (
                    SELECT DISTINCT route_id_int, route_type
                    FROM filtered_data
                    UNION
                    SELECT DISTINCT route_id_int, 8
                    FROM filtered_data
                    ) s
                    CROSS JOIN (SELECT unnest('$$ || days_list || $$'::date[]) AS day_date) q
                    ORDER BY 1, 2, 3
                ) 
                ( -- Mode by mode
                    SELECT feed_id, 
                           all_days.route_id_int, 
                           route_id, 
                           route_short_name, 
                           route_long_name, 
                           all_days.route_type, 
                           agency_id_int, 
                           agency_id, 
                           agency_name, 
                           all_days.day_date,
                           $$ || indics_time_ag || $$
                    FROM filtered_data RIGHT JOIN all_days ON (all_days.route_id_int = filtered_data.route_id_int AND all_days.route_type = filtered_data.route_type AND all_days.day_date = filtered_data.date) 
                    WHERE all_days.route_type != 8
                    GROUP BY feed_id, 
                           all_days.route_id_int, 
                           route_id, 
                           route_short_name, 
                           route_long_name, 
                           all_days.route_type, 
                           agency_id_int, 
                           agency_id, 
                           agency_name, 
                           all_days.day_date
                )
                UNION
                ( -- All modes together
                    SELECT feed_id, 
                           all_days.route_id_int, 
                           route_id, 
                           route_short_name, 
                           route_long_name, 
                           8, 
                           agency_id_int, 
                           agency_id, 
                           agency_name, 
                           all_days.day_date, 
                           $$ || indics_time_ag || $$
                    FROM filtered_data RIGHT JOIN all_days ON (all_days.route_id_int = filtered_data.route_id_int AND all_days.day_date = filtered_data.date)
                    WHERE all_days.route_type = 8 
                    GROUP BY feed_id, 
                           all_days.route_id_int, 
                           route_id, 
                           route_short_name, 
                           route_long_name, 
                           agency_id_int, 
                           agency_id, 
                           agency_name,
                           all_days.day_date
                )
         )$$;
    EXECUTE(s);
    
    
    
    -- Building data aggregating all days together
    s = $$
        DROP TABLE IF EXISTS indic.routes;
        CREATE TABLE indic.routes AS
        (
            SELECT row_number() over() as gid, *
            FROM
                (
                SELECT
                   min(feed_id) as feed_id, 
                   route_id_int, 
                   min(route_id) as route_id, 
                   min(route_short_name) as route_short_name, 
                   min(route_long_name) as route_long_name, 
                   route_type, 
                   min(agency_id_int) as agency_id_int, 
                   min(agency_id) as agency_id, 
                   min(agency_name) as agency_name, 
                   array_remove(array_agg(CASE WHEN route_id IS NOT NULL THEN day_date END ORDER BY day_date), NULL) as services_days,
                   array_agg(day_date ORDER BY day_date) as days, 
                   $$ || indics_day_ag || $$
                FROM daily_aggregated_data
                GROUP BY   route_id_int, 
                           route_type
                ORDER BY route_id_int, 
                         route_type
                ) q
        ); 
        ALTER TABLE indic.routes ADD CONSTRAINT routes_pkey PRIMARY KEY(gid);
        $$;
    RAISE NOTICE '%', s;
    EXECUTE(s);    
        
    -- Adding facultative zones indicator
    IF (zones_list_indic = True) and (param_indic_zoning is not null)
    THEN 
        SELECT INTO zoning_table
                    name
        FROM zoning.zoning_source WHERE id = param_indic_zoning; 
        
        s = $$
                ALTER TABLE indic.routes
                ADD COLUMN zones_list character varying[];
                
                WITH stops_zones AS (
                    SELECT routes.id, array_agg(DISTINCT zoning.vendor_id) as zones_list
                    FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.route_id_int = routes.id)
                                            JOIN tempus_gtfs.stop_times ON (trips.id = stop_times.trip_id_int)
                                            JOIN tempus_gtfs.stops ON (stops.id = stop_times.stop_id_int)
                                            JOIN zoning.$$ || zoning_table || $$ zoning ON (st_within(stops.geom, zoning.geom))
                    GROUP BY routes.id
                )
                UPDATE indic.routes
                SET zones_list = stops_zones.zones_list
                FROM stops_zones
                WHERE stops_zones.id = routes.route_id_int;
            $$;
        EXECUTE(s);
    END IF; 
    
    IF (zones_pop_indic = True) and (param_indic_zoning is not null)
    THEN 
        SELECT INTO zoning_table
                    name
        FROM zoning.zoning_source WHERE id = param_indic_zoning; 
        
        s = $$
                ALTER TABLE indic.routes
                ADD COLUMN zones_pop bigint;
                
                WITH stops_zones AS (
                    SELECT routes.id, array_agg(DISTINCT zoning.vendor_id) as zones_list
                    FROM tempus_gtfs.routes JOIN tempus_gtfs.trips ON (trips.route_id_int = routes.id)
                                            JOIN tempus_gtfs.stop_times ON (trips.id = stop_times.trip_id_int)
                                            JOIN tempus_gtfs.stops ON (stops.id = stop_times.stop_id_int)
                                            JOIN zoning.$$ || zoning_table || $$ zoning ON (st_within(stops.geom, zoning.geom))
                    GROUP BY routes.id
                ), stops_pop AS (
                    SELECT stops_zones.id, sum(zoning.population) as population
                    FROM stops_zones JOIN zoning.$$ || zoning_table || $$ zoning ON (ARRAY[zoning.vendor_id] <@ stops_zones.zones_list)
                    GROUP BY stops_pop.id
                )
                UPDATE indic.routes
                SET zones_pop = stops_pop.population
                FROM stops_pop
                WHERE stops_pop.id = routes.route_id_int;
        $$;
        EXECUTE(s);
    END IF;
    
    t=$$
      DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'routes';
      INSERT INTO tempus_access.indic_catalog(
                                                layer_name,
                                                obj_type,
                                                indics,
                                                days,
                                                day_type,
                                                per_type,
                                                per_start,
                                                per_end,
                                                day_ag,
                                                time_start,
                                                time_end,
                                                zoning_filter, 
                                                indic_zoning, 
                                                zones,
                                                stop,
                                                pt_networks,
                                                agencies,
                                                pt_modes
                                             )
    VALUES ('routes', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'routes')::character varying, 
           $$ || coalesce($$'$$ || param_indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce(param_day_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || param_time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce(param_zoning_filter::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(param_indic_zoning::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_zones::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
           $$ || coalesce($$'$$ || param_stop_area::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_pt_networks::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || param_agencies::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE gtfs_feed_id IS NOT NULL AND array[gtfs_route_type]<@ '$$ || param_route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || param_pt_networks::character varying || $$')::integer[]
           );$$; 
    
    RAISE NOTICE '%', t;
    EXECUTE(t);
        
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 
  
  