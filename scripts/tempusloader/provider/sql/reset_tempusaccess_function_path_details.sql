CREATE OR REPLACE FUNCTION tempus_access.create_path_details_indicator_layer(
                                                                                param_indics integer[], 
                                                                                param_node_type integer, 
                                                                                param_o_node bigint, 
                                                                                param_d_node bigint, 
                                                                                param_i_modes integer[], 
                                                                                param_pt_modes integer[],
                                                                                param_day date,
                                                                                param_day_type integer,
                                                                                param_per_type integer, 
                                                                                param_per_start date, 
                                                                                param_per_end date, 
                                                                                param_time_point time, 
                                                                                param_time_start time,
                                                                                param_time_end time, 
                                                                                param_time_inter integer, 
                                                                                param_all_services boolean, 
                                                                                param_constraint_date_after boolean
                                                                            ) 
RETURNS void AS
$BODY$
DECLARE
	s character varying;
	t character varying;
    indics_str character varying;
    r record;

BEGIN
    
    -- Update the temporary results table
    UPDATE tempus_access.tempus_paths_results
    SET pt_o_stop = q2.pt_o_stop, 
        pt_d_stop = q2.pt_d_stop, 
        wait_o_time = q2.wait_o_time, 
        o_time = q2.o_time, 
        d_time = q2.d_time, 
        all_stops = q2.all_stops, 
        pt_route = q2.pt_route, 
        route_type = q2.route_type, 
        step_mode = q2.step_mode, 
        geom = q2.geom
    FROM
    (
        SELECT 
               path_id, 
               step_id, 
               step_mode, 
               wait_o_time, 
               coalesce(
                (starting_date_time::date::character varying || ' ' || (pt_departure)::character varying)::timestamp,
                starting_date_time + ((sum((cost*60)::integer) over(partition by path_id order by path_id, step_id) || ' second')::character varying)::interval - ((cost*60)::integer::character varying || ' second')::interval + coalesce(wait_o_time,'00:00:00')
               ) as o_time, 
               coalesce(
                (starting_date_time::date::character varying || ' ' || (pt_arrival)::character varying)::timestamp, 
                starting_date_time + ((sum((cost*60)::integer) over(partition by path_id order by path_id, step_id) || ' second')::character varying)::interval
               ) as d_time,        
               pt_o_stop, 
               pt_d_stop, 
               all_stops, 
               pt_route, 
               route_type, 
               geom
        FROM
        (
            SELECT path_id, 
                   step_id, 
                   starting_date_time, 
                   unnest(costs) as cost, 
                   stop_o.stop_name as pt_o_stop, 
                   stop_d.stop_name as pt_d_stop, 
                   (((pt_wait_time_min*60)::integer)::character varying || ' second')::interval as wait_o_time,
                   ((pt_departure_time_min*60)::integer || ' second')::interval as pt_departure,                    
                   ((pt_arrival_time_min*60)::integer || ' second')::interval as pt_arrival, 
                   (SELECT array_agg(stop_name order by stop_sequence) FROM (SELECT * FROM tempus_access.pt_all_stops(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer) as (id integer, stop_id character varying, stop_name character varying, stop_sequence integer)) q) as all_stops, 
                   routes.route_long_name as pt_route, 
                   routes.route_type as route_type, 
                   CASE WHEN tempus_paths_results.step_type = 0 THEN 'Attente' WHEN tempus_paths_results.step_type = 1 THEN 'Public transport' WHEN tempus_paths_results.step_type = 2 THEN transport_mode.name END as step_mode, 
                   CASE WHEN tempus_paths_results.step_type = 1 THEN (SELECT st_multi(st_force2d(tempus_access.pt_section(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer)))) 
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE (node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id) OR (node_from = tempus_paths_results.source_road_vertex_id AND node_to = tempus_paths_results.target_road_vertex_id))
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_pt_stop_id IS NOT NULL) THEN (SELECT st_multi(st_force2d(tempus_access.road_section(target_pt_stop_id::integer, source_road_vertex_id::integer))))
                        WHEN tempus_paths_results.step_type = 2 AND (target_road_vertex_id IS NOT NULL AND source_pt_stop_id IS NOT NULL) THEN (SELECT st_multi(st_force2d(tempus_access.road_section(source_pt_stop_id::integer, target_road_vertex_id::integer))))
                   END AS geom
            FROM tempus_access.tempus_paths_results LEFT JOIN tempus.transport_mode ON (transport_mode.id = least(tempus_paths_results.final_mode, tempus_paths_results.initial_mode))
                                LEFT JOIN tempus_gtfs.trips ON (trips.id = tempus_paths_results.pt_trip_id)
                                LEFT JOIN tempus_gtfs.routes ON (trips.route_id = routes.route_id AND trips.feed_id = routes.feed_id)
                                LEFT JOIN tempus_gtfs.stops stop_o ON (stop_o.id = tempus_paths_results.source_pt_stop_id)
                                LEFT JOIN tempus_gtfs.stops stop_d ON (stop_d.id = tempus_paths_results.target_pt_stop_id)
                                LEFT JOIN tempus_gtfs.shapes ON (shapes.shape_id = trips.shape_id AND trips.feed_id = shapes.feed_id)
                                
            ORDER BY path_id, step_id
        ) q
    ) q2
    WHERE q2.path_id = tempus_paths_results.path_id AND q2.step_id = tempus_paths_results.step_id; 

    indics_str = ''; 
    CREATE SCHEMA IF NOT EXISTS indic;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics ORDER BY code)
    LOOP
        IF (r.col_name = 'total_time') -- Total time from the first to the last road node of the path
        THEN
            indics_str = indics_str || $$(d_time - o_time)::time as total_time, $$;
        END IF;
        
        IF (r.col_name = 'total_dist') -- Distance decomposition, by mode
        THEN 
            indics_str = indics_str || $$(st_length(st_transform(geom, 2154))/1000)::numeric(10,3) as total_dist, $$;
        END IF; 
        
        IF (r.col_name = 'all_stops') -- All served stops
        THEN
            indics_str = indics_str || $$all_stops, $$;
        END IF; 
        
        IF (r.col_name = 'speed_kmh') -- Speed in km/h
        THEN 
            indics_str = indics_str || $$((st_length(st_transform(geom, 2154))/1000)/(extract(hour from (d_time - o_time)) + extract(minute from (d_time - o_time))/60.0 + extract(second from (d_time - o_time))/3600.0))::numeric(10,1) as speed_kmh, $$;
        END IF;
    END LOOP; 
        
    s=$$DROP TABLE IF EXISTS indic.paths_details;
    CREATE TABLE indic.paths_details AS
    (
        SELECT row_number() over(ORDER BY path_id, step_id) as gid, 
               path_id, 
               step_id, 
               step_mode, 
               route_type, 
               pt_route,        
               pt_o_stop, 
               pt_d_stop, 
               source_road_vertex_id as road_o_node, 
               target_road_vertex_id as road_d_node, 
               wait_o_time, 
               o_time, 
               d_time, 
               $$ || indics_str || $$
               geom
        FROM tempus_access.tempus_paths_results
        ORDER BY path_id, step_id
    );
    
    ALTER TABLE indic.paths_details ADD CONSTRAINT paths_details_pkey PRIMARY KEY(gid);
    $$; 
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'paths_details';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_node,d_node,i_modes,pt_modes,days,day_type,per_type,per_start,per_end,time_point,time_start,time_end,time_inter,all_services,constraint_date_after)
    VALUES ('paths_details', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'paths_details')::character varying, 
           $$ || coalesce($$'$$ || param_indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce(param_node_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(param_o_node::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(param_d_node::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_i_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce($$'$$ || param_pt_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce($$'$$ || param_time_point::character varying || $$'$$, $$NULL$$) || $$::time,   
           $$ || coalesce($$'$$ || param_time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || param_time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || param_time_inter::character varying || $$'$$, $$NULL$$) || $$::integer,   
           $$ || param_all_services::character varying || $$::boolean,         
           $$ || param_constraint_date_after::character varying || $$::boolean
           );$$;
    RAISE NOTICE '%', t;
    EXECUTE(t);
    
    RETURN;
    
END;
$BODY$
LANGUAGE plpgsql; 

