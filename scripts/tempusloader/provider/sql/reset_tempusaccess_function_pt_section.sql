CREATE OR REPLACE FUNCTION tempus_access.create_pt_section_indicator_layer(
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
                                                                            param_zoning_filter integer, 
                                                                            param_zones integer[],
                                                                            param_route integer, 
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
    routes_filter character varying;
    stops_filter character varying;
    
    routes_indic boolean;

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
        RAISE EXCEPTION 'Parameters 1 to 4 must be non-empty arrays';
    END IF;
    
    -- Default values for some parameters
    IF param_day_ag IS NULL THEN param_day_ag = 1; END IF;
    IF param_time_start IS NULL THEN param_time_start = '00:00:00'::time; END IF; 
    IF param_time_end IS NULL THEN param_time_end = '23:59:00'::time; END IF;    
    
    -- Facultative parameters    
    -- Zones filter
    SELECT INTO zoning_table
        name
    FROM zoning.zoning_source WHERE id = param_zoning_filter; 
    
    IF (param_zoning_filter=-1 OR array_length(param_zones,1)=0 OR param_zones IS NULL)
    THEN zones_filter = $$$$;
    ELSE zones_filter = $$ 
                        AND 
                        (
                            (
                            stop_id_from_int IN 
                                (
                                    SELECT stops.id
                                    FROM tempus_gtfs.stops, zoning.$$ || zoning_table || $$ zoning
                                    WHERE st_within(stops.geom, zoning.geom) = TRUE AND ARRAY[zoning.id] <@ '$$ || param_zones::character varying || $$'
                                )
                            )
                        OR 
                            (
                            stop_id_to_int IN 
                                (
                                SELECT stops.id
                                FROM tempus_gtfs.stops, zoning.$$ || zoning_table || $$ zoning
                                WHERE st_within(stops.geom, zoning.geom) = TRUE AND ARRAY[zoning.id] <@ '$$ || param_zones::character varying || $$'
                                )
                            )
                        )
                        $$;
    END IF;

    -- Routes filter : trips must belong to the specified routes
    IF (param_route IS NULL)
    THEN routes_filter = $$$$;
    ELSE routes_filter = $$ AND route_id_int = $$ || param_route::character varying;
    END IF; 
    
    -- Stops filter : sections must begin or end at the specified stops
    IF (param_stop_area IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$
                        AND 
                        (
                            ((feed_id, parent_station_id_from) = (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $$ || param_stop_area::character varying || $$)) 
                        OR 
                            ((feed_id, parent_station_id_to) = (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $$ || param_stop_area::character varying || $$)) 
                        )
                        $$;
    END IF;
    
    SELECT INTO days_list
        CASE WHEN days IS NULL THEN '{}' ELSE days::character varying END
    FROM tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end);
    
    -- Filtered data
    s = $$
        DROP TABLE IF EXISTS filtered_data;
        CREATE TEMPORARY TABLE filtered_data AS
        (
            SELECT section_id_int, 
                   feed_id, 
                   stop_id_from_int, 
                   stop_id_from, 
                   stop_name_from, 
                   stop_id_to_int, 
                   stop_id_to, 
                   stop_name_to, 
                   route_short_name, 
                   route_long_name, 
                   route_type, 
                   date, 
                   trip_id_int, 
                   departure_time, 
                   arrival_time,
                   geom
            FROM tempus_access.sections_indic_complete_data
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || param_pt_networks::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[route_type] <@ '$$ || param_route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency_id_int] <@ '$$ || param_agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[date] <@ '$$ || days_list || $$' -- Days filter
                  AND
                    (
                        (departure_time <= extract(epoch FROM INTERVAL '$$ || param_time_end::character varying || $$')) 
                        AND 
                        (departure_time >= extract(epoch FROM INTERVAL '$$ || param_time_start::character varying || $$'))
                    ) -- Time filter
                  $$ || zones_filter || $$ -- Facultative : areas filter
                  $$ || routes_filter || $$ -- Facultative : routes filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
        )
        $$;
    EXECUTE(s);
    
    -- Building indicators strings
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    routes_indic = False; 
    
    SELECT INTO time_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_time_ag;
    
    SELECT INTO day_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_day_ag;
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics)
    LOOP 
        IF (r.col_name = 'routes')
        THEN routes_indic = True;
        END IF;
        
        indics_time_ag = indics_time_ag || (SELECT coalesce(replace(time_ag_sections, '%(time_ag)', time_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);
        indics_day_ag = indics_day_ag || (SELECT coalesce(replace(day_ag_sections, '%(day_ag)', day_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);         
    END LOOP; 
    
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2); 
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);
    
    -- Building daily aggregated data
    s= $$DROP TABLE IF EXISTS daily_aggregated_data; 
         CREATE TEMPORARY TABLE daily_aggregated_data AS
         (
                WITH all_days AS
                (
                    SELECT DISTINCT section_id_int, route_type, q.day_date
                    FROM filtered_data
                    CROSS JOIN (SELECT unnest('$$ || days_list || $$'::date[]) AS day_date) q
                )
                ( -- Mode by mode
                    SELECT all_days.section_id_int, 
                           feed_id, 
                           stop_id_from_int, 
                           stop_id_from, 
                           stop_name_from, 
                           stop_id_to_int, 
                           stop_id_to, 
                           stop_name_to, 
                           all_days.route_type, 
                           all_days.day_date,
                           $$ || indics_time_ag || $$ , 
                           geom
                    FROM filtered_data RIGHT JOIN all_days ON (all_days.section_id_int = filtered_data.section_id_int AND all_days.route_type = filtered_data.route_type AND all_days.day_date = filtered_data.date) 
                    GROUP BY all_days.section_id_int, 
                             feed_id, 
                             stop_id_from_int, 
                             stop_id_from, 
                             stop_name_from, 
                             stop_id_to_int, 
                             stop_id_to, 
                             stop_name_to, 
                             all_days.route_type, 
                             all_days.day_date, 
                             geom
                )
                -- Considering all modes together has no signification for sections indicators, 
                -- since sections are designed between two physical stops
                -- which should only be served by one mode.
         )$$;
    EXECUTE(s);
    
    -- Building data aggregating all days together
    s = $$
        DROP TABLE IF EXISTS indic.sections;
        CREATE TABLE indic.sections AS
        (
            SELECT row_number() over() as gid, *
            FROM
                (
                    SELECT
                           section_id_int, 
                           min(feed_id) as feed_id, 
                           min(stop_id_from) as stop_id_from, 
                           min(stop_name_from) as stop_name_from, 
                           min(stop_id_to) as stop_id_to, 
                           min(stop_name_to) as stop_name_to, 
                           route_type, 
                           array_remove(array_agg(CASE WHEN stop_id_from IS NOT NULL THEN day_date END ORDER BY day_date), NULL) as services_days,
                           array_agg(day_date ORDER BY day_date) as days, 
                           $$ || indics_day_ag || $$ , 
                           min(geom) as geom
                    FROM daily_aggregated_data
                    GROUP BY section_id_int, route_type
                    ORDER BY section_id_int, route_type
                ) q
        );
        $$;
    EXECUTE(s);
        
    -- Adding facultative routes indicator
    IF (routes_indic = True)
    THEN         
        s = $$
                ALTER TABLE indic.sections 
                ADD COLUMN routes character varying[];
                
                WITH r AS (
                    SELECT section_id_int, unnest(routes) as unnested_routes
                    FROM daily_aggregated_data
                ), q AS (
                    SELECT section_id_int, array_agg(DISTINCT unnested_routes) as routes
                    FROM r
                    GROUP BY section_id_int
                )
                UPDATE indic.sections
                SET routes = q.routes
                FROM q
                WHERE q.section_id_int = sections.section_id_int;
            $$;
        EXECUTE(s);
    END IF;
    
    -- Adding mapping fields
    s = $$
            ALTER TABLE indic.sections ADD COLUMN symbol_size real;
            ALTER TABLE indic.sections ADD COLUMN symbol_color real;
            ALTER TABLE indic.sections ADD CONSTRAINT sections_pkey PRIMARY KEY(gid);
        $$;
    EXECUTE(s);
    
    -- Completing indicators catalog
    t=$$
        DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'sections';
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
                                                    time_ag,
                                                    zoning_filter,
                                                    zones,
                                                    route,
                                                    stop,
                                                    pt_networks,
                                                    agencies,
                                                    pt_modes
                                                )
        VALUES ('sections', 
               (SELECT code FROM tempus_access.obj_type WHERE def_name = 'sections')::character varying, 
               $$ || coalesce($$'$$ || param_indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
               $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
               $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
               $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
               $$ || coalesce(param_day_ag::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
               $$ || coalesce($$'$$ || param_time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
               $$ || coalesce(param_time_ag::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce(param_zoning_filter::character varying, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_zones::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
               $$ || coalesce($$'$$ || param_route::character varying || $$'$$, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_stop_area::character varying || $$'$$, $$NULL$$) || $$::integer, 
               $$ || coalesce($$'$$ || param_pt_networks::character varying || $$'$$, $$NULL$$) || $$::integer[], 
               $$ || coalesce($$'$$ || param_agencies::character varying || $$'$$, $$NULL$$) || $$::integer[], 
               (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE gtfs_feed_id IS NOT NULL AND array[gtfs_route_type]<@ '$$ || param_route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || param_pt_networks::character varying || $$')::integer[]
               );
      $$;
    EXECUTE(t);
    
    RETURN;
END; 

$BODY$
  LANGUAGE plpgsql;



