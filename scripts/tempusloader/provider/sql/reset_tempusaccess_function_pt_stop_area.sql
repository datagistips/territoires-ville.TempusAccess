CREATE OR REPLACE FUNCTION tempus_access.create_pt_stop_area_indicator_layer(
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
                                                                            param_time_start time without time zone,
                                                                            param_time_end time without time zone, 
                                                                            param_indic_zoning integer, 
                                                                            param_zoning_filter integer, 
                                                                            param_zones integer[],
                                                                            param_route integer
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
    day_ag_str character varying;
    
    zoning_table character varying;
    
    zones_filter character varying;
    routes_filter character varying;
    
    zones_list_indic boolean;
    zones_pop_indic boolean;

BEGIN
    
    -- Mandatory parameters
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
        RAISE EXCEPTION 'Parameters 1 to 5 must be non-empty arrays';
    END IF;
    
    -- Default values for some parameters
    IF param_day_ag IS NULL THEN param_day_ag = 1; END IF;
    IF param_time_start IS NULL THEN param_time_start = '00:00:00'::time; END IF; 
    IF param_time_end IS NULL THEN param_time_end = '23:59:00'::time; END IF;
        
    -- Facultative parameters
    -- Zones filter
    SELECT INTO zoning_table
                name
    FROM zoning.zoning_source 
    WHERE id = param_zoning_filter; 
    
    IF (
            param_zoning_filter is null OR 
            array_length(param_zones,1)=0 OR 
            param_zones is null
       )
    THEN zones_filter = $$$$;
    ELSE zones_filter = $$ 
                        AND stop_id_int IN 
                            (
                                SELECT stops.id 
                                FROM tempus_gtfs.stops, zoning.$$ || zoning_table || $$ zoning
                                WHERE st_within(stops.geom, zoning.geom) = TRUE AND ARRAY[zoning.id] <@ '$$ || param_zones::character varying || $$'
                            )
                        $$;
    END IF;
    
    -- Route filter
    IF (param_route IS NULL)
    THEN routes_filter = $$$$;
    ELSE routes_filter = $$ AND route_id_int = $$ || param_route::character varying;
    END IF;
    
    SELECT INTO days_list
        CASE WHEN days IS NULL THEN '{}' ELSE days::character varying END
    FROM tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end);
    
    -- Filtered data
    s = $$
        DROP TABLE IF EXISTS filtered_data;
        CREATE TEMPORARY TABLE filtered_data AS
        (
            SELECT parent_stop_id_int as stop_id_int, 
                   feed_id, 
                   parent_stop_id as stop_id, 
                   parent_stop_name as stop_name, 
                   geom_parent_stop as geom_stop, 
                   route_type, 
                   date, 
                   arrival_time, 
                   departure_time, 
                   route_long_name, 
                   trip_id_int
            FROM tempus_access.indic_complete_data
            WHERE parent_stop_id IS NOT NULL 
              AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || param_pt_networks::character varying || $$') -- GTFS feeds filter
              AND ARRAY[route_type] <@ '$$ || param_route_types::character varying || $$' -- Route types filter
              AND ARRAY[agency_id_int] <@ '$$ || param_agencies::character varying || $$' -- Agencies filter
              AND ARRAY[date] <@ '$$ || days_list || $$' -- Days filter
              AND (
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
                  )
              $$ || zones_filter || $$ -- Facultative : zones filter
              $$ || routes_filter || $$ -- Facultative : routes filter
        )
        $$;
    RAISE NOTICE 'Filtered data:\n%', s; 
    EXECUTE(s);
    
    -- Building indicators strings
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    zones_list_indic = False;
    zones_pop_indic = False;
    
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
            indics_time_ag = indics_time_ag || (SELECT coalesce(time_ag_stops || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name) ; 
            indics_day_ag = indics_day_ag || (SELECT coalesce(replace(day_ag_stops || ' AS ' || r.col_name || ', ', '%(day_ag)', day_ag_str::character varying), '') FROM tempus_access.indicators WHERE col_name = r.col_name);
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
                SELECT DISTINCT s.stop_id_int, s.route_type, q.day_date
                FROM 
                (
                SELECT DISTINCT stop_id_int, route_type
                FROM filtered_data
                UNION
                SELECT DISTINCT stop_id_int, 8
                FROM filtered_data
                ) s
                CROSS JOIN (SELECT unnest('$$ || days_list || $$'::date[]) AS day_date) q
                ORDER BY 1, 2, 3
            ) 
            (-- Mode by mode
                SELECT all_days.stop_id_int, 
                       feed_id, 
                       stop_id, 
                       stop_name, 
                       st_force2D(geom_stop)::Geometry(Point, 4326) as geom, 
                       all_days.route_type, 
                       all_days.day_date, 
                       $$ || indics_time_ag || $$ 
                FROM filtered_data RIGHT JOIN all_days ON (all_days.stop_id_int = filtered_data.stop_id_int AND all_days.route_type = filtered_data.route_type AND all_days.day_date = filtered_data.date)
                WHERE all_days.route_type != 8
                GROUP BY all_days.stop_id_int, feed_id, stop_id, stop_name, geom, all_days.route_type, all_days.day_date
            )
            UNION
            ( -- All modes together
                SELECT all_days.stop_id_int, 
                       feed_id, 
                       stop_id, 
                       stop_name, 
                       st_force2D(geom_stop)::Geometry(Point, 4326) as geom, 
                       8, 
                       all_days.day_date, 
                       $$ || indics_time_ag || $$ 
                FROM filtered_data RIGHT JOIN all_days ON (all_days.stop_id_int = filtered_data.stop_id_int AND all_days.day_date = filtered_data.date)
                WHERE all_days.route_type = 8
                GROUP BY all_days.stop_id_int, feed_id, stop_id, stop_name, geom, all_days.day_date
            )
            ORDER BY stop_id_int, route_type, day_date
        );$$;
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    -- Building data aggregating all days together
    s = $$

        DROP TABLE IF EXISTS indic.stop_areas;
        CREATE TABLE indic.stop_areas AS
        (
            -- Aggregate days together
            SELECT row_number() over() as gid, *
            FROM (
                  SELECT stop_id_int, 
                         min(feed_id) as feed_id, 
                         min(stop_id) as stop_id,
                         min(stop_name) as stop_name, 
                         min(geom) as geom, 
                         route_type, 
                         array_remove(array_agg(CASE WHEN stop_id IS NOT NULL THEN day_date END ORDER BY day_date), NULL) as services_days,
                         array_agg(day_date ORDER BY day_date) as days, 
                         $$ || indics_day_ag || $$ 
                  FROM daily_aggregated_data
                  GROUP BY stop_id_int, route_type 
                  ORDER BY stop_id_int, route_type
                 ) q
        );
        $$;
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    -- Adding facultative zonal indicators
    IF (zones_list_indic = True) and (param_indic_zoning is not null)
    THEN 
        SELECT INTO zoning_table
                    name
        FROM zoning.zoning_source WHERE id = param_indic_zoning; 
        
        s = $$
                ALTER TABLE indic.stop_areas 
                ADD COLUMN zones_list character varying;
                
                UPDATE indic.stop_areas
                SET zones_list = zoning.vendor_id
                FROM zoning.$$ || zoning_table || $$ zoning
                WHERE st_within(stop_areas.geom, zoning.geom)
            $$;
        EXECUTE(s);
    END IF;
        
    
    IF (zones_pop_indic = True) and (param_indic_zoning is not null)
    THEN 
        SELECT INTO zoning_table
                    name
        FROM zoning.zoning_source WHERE id = param_indic_zoning; 
        
        s = $$
                ALTER TABLE indic.stop_areas 
                ADD COLUMN zones_pop integer;
                
                UPDATE indic.stop_areas
                SET zones_pop = zoning.population
                FROM zoning.$$ || zoning_table || $$ zoning
                WHERE st_within(stop_areas.geom, zoning.geom)
        $$;
        EXECUTE(s);
    END IF;
    
    -- Adding mapping fields
    s = $$
            ALTER TABLE indic.stop_areas ADD COLUMN symbol_size real;
            ALTER TABLE indic.stop_areas ADD COLUMN symbol_color real;
            ALTER TABLE indic.stop_areas ADD CONSTRAINT stop_areas_pkey PRIMARY KEY(gid);
        $$;
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    -- Completing indicators catalog
    t=$$
        DELETE FROM tempus_access.indic_catalog 
        WHERE layer_name = 'stop_areas';
        
        INSERT INTO tempus_access.indic_catalog (
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
                                                    indic_zoning,
                                                    zoning_filter,
                                                    zones,
                                                    route,
                                                    pt_networks,
                                                    agencies,
                                                    pt_modes
                                                )
        VALUES ('stop_areas', 
               (SELECT code FROM tempus_access.obj_type WHERE def_name = 'stop_areas')::character varying, 
               '$$ || param_indics::character varying || $$'::integer[], 
               $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
               $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
               $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
               $$ || coalesce(param_day_ag::character varying, $$NULL$$) || $$::integer, 
               '$$ || param_time_start::character varying || $$'::time, 
               '$$ || param_time_end::character varying || $$'::time, 
               $$ || coalesce(param_indic_zoning::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce(param_zoning_filter::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_zones::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
               $$ || coalesce(param_route::character varying, $$NULL$$)|| $$::integer, 
               '$$ || param_pt_networks::character varying || $$'::integer[], 
               '$$ || param_agencies::character varying || $$'::integer[], 
               (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE gtfs_feed_id is not null AND array[gtfs_route_type]<@ '$$ || param_route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || param_pt_networks::character varying || $$')::integer[]
               );
      $$;
    RAISE NOTICE '%', t;
    EXECUTE(t);         
    RETURN;
    
END;
$BODY$
LANGUAGE plpgsql; 
