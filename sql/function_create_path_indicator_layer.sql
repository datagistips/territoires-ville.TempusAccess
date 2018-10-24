CREATE OR REPLACE FUNCTION tempus_access.create_path_indicator_layer(
                                                                        indics integer[], 
                                                                        node_type integer, 
                                                                        o_node bigint, 
                                                                        d_node bigint,
                                                                        tran_modes integer[], 
                                                                        day date,
                                                                        day_type integer,
                                                                        per_type integer, 
                                                                        per_start date, 
                                                                        per_end date, 
                                                                        time_point time, 
                                                                        time_start time,
                                                                        time_end time, 
                                                                        time_inter integer, 
                                                                        all_services boolean, 
                                                                        constraint_date_after boolean
                                                                       )
  RETURNS void AS
$BODY$

DECLARE
    r record;
    indics_str character varying;
    s character varying;
    t character varying;

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
                   CASE WHEN tempus_paths_results.step_type = 1 THEN 'Public transport' 
                        ELSE transport_mode.name 
                   END AS step_mode, 
                   CASE WHEN tempus_paths_results.step_type = 0 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) -- Road section
                                THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE (node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id) OR (node_to = tempus_paths_results.source_road_vertex_id AND node_from = tempus_paths_results.target_road_vertex_id))
                        WHEN tempus_paths_results.step_type = 1 -- PT section
                                THEN (SELECT st_multi(st_force2d(tempus_access.pt_section(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer)))) 
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) -- Transfer section
                                THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE (node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id) OR (node_to = tempus_paths_results.source_road_vertex_id AND node_from = tempus_paths_results.target_road_vertex_id))
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_pt_stop_id IS NOT NULL) THEN (SELECT st_multi(st_force2d(tempus_access.road_section(target_pt_stop_id::integer, source_road_vertex_id::integer))))
                        WHEN tempus_paths_results.step_type = 2 AND (target_road_vertex_id IS NOT NULL AND source_pt_stop_id IS NOT NULL) THEN (SELECT st_multi(st_force2d(tempus_access.road_section(source_pt_stop_id::integer, target_road_vertex_id::integer))))
                   END::Geometry(Multilinestring, 4326) AS geom 
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
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics ORDER BY code)
    LOOP
        IF (r.col_name = 't_modes') -- Transport modes
        THEN
            indics_str = indics_str || $$array_agg(step_mode order by step_mode) as t_modes, $$;
        END IF;
        
        IF (r.col_name = 'stops_time') -- Total time from the first to the last stop of the path
        THEN
            indics_str = indics_str || $$max(case when step_mode = 'Public transport' then (last_d_time - first_o_time)::time end) as stops_time, $$;
        END IF;
        
        IF (r.col_name = 'total_dist') -- Distance decomposition, by mode
        THEN 
            indics_str = indics_str || $$sum(distance/1000) as total_dist, $$;
        END IF; 
        
        IF (r.col_name = 'wait_time') -- Waiting time
        THEN 
            indics_str = indics_str || $$max(wait_o_time::time) as wait_time, $$;
        END IF;
        
        IF (r.col_name = 'dep_stop') -- Departure time from the first road node
        THEN 
            indics_str = indics_str || $$min(CASE WHEN step_mode = 'Public transport' THEN first_o_time ELSE NULL END) as dep_stops, $$;
        END IF; 
        
        IF (r.col_name = 'arr_stop') -- Arrival time to the last road node
        THEN 
            indics_str = indics_str || $$max(CASE WHEN step_mode= 'Public transport' THEN last_d_time ELSE NULL END) as arr_stops, $$;
        END IF;
                
        IF (r.col_name = 'compo_time') -- Time decomposition, by mode
        THEN 
            indics_str = indics_str || $$array_agg(travel_time::time order by step_mode) as compo_time, $$;
        END IF;
        
        IF (r.col_name = 'compo_dist') -- Distance decomposition, by mode
        THEN 
            indics_str = indics_str || $$array_agg(distance/1000 order by step_mode) as compo_dist, $$;
        END IF; 
        
        IF (r.col_name = 'tran_stops') -- Transfer stops
        THEN 
            indics_str = indics_str || $$(max(tran_stops))[2:] as tran_stops, $$;
        END IF;
        
        IF (r.col_name = 'all_stops') -- All served stops
        THEN
            indics_str = indics_str || $$max(all_stops.all_stops) as all_stops, $$;
        END IF; 
        
        IF (r.col_name = 'routes') -- List of used routes
        THEN
            indics_str = indics_str || $$max(routes) as routes, $$;
        END IF; 
        
    END LOOP;
    
    s = $$DROP TABLE IF EXISTS indic.paths; 
        CREATE TABLE indic.paths AS
        (
            SELECT a.path_id as gid, min(first_o_time) as dep, max(last_d_time) as arr, (max(last_d_time) - min(first_o_time))::time as total_time, 
                   $$ || indics_str || $$
                   st_multi(st_force2d(st_linemerge(st_union(geom)))) as the_geom
            FROM
            (
                SELECT path_id,
                       step_mode,
                       min(o_time) as first_o_time, 
                       max(d_time) as last_d_time, 
                       max(d_time) - min(o_time) as total_travel_time, 
                       sum(d_time - o_time) as travel_time, 
                       sum(wait_o_time) as wait_o_time, 
                       sum(case when tempus_paths_results.geom is null then 0 else st_length(st_transform(tempus_paths_results.geom, 2154)) end) as distance, 
                       array_remove(array_agg(CASE WHEN wait_o_time is null THEN null ELSE stops.stop_name END ORDER BY tempus_paths_results.step_id), NULL) as tran_stops, 
                       array_remove(array_agg(routes.route_long_name || '-' || route_desc ORDER BY tempus_paths_results.step_id), NULL) as routes, 
                       st_multi(st_force2d(st_linemerge(st_union(tempus_paths_results.geom)))) as geom
                FROM tempus_access.tempus_paths_results LEFT JOIN tempus_gtfs.stops ON (tempus_paths_results.source_pt_stop_id = stops.id)
                                                        LEFT JOIN tempus_gtfs.trips ON (tempus_paths_results.pt_trip_id = trips.id)
                                                        LEFT JOIN tempus_gtfs.routes ON (trips.route_id = routes.route_id)
                WHERE step_mode is not null 
                GROUP BY path_id, step_mode
            ) a LEFT JOIN (SELECT path_id, array_remove(array_agg(f.stop_name order by path_id, step_id, stop_order), NULL) all_stops FROM tempus_access.tempus_paths_results LEFT JOIN LATERAL unnest(tempus_paths_results.all_stops) WITH ORDINALITY AS f(stop_name, stop_order) ON true GROUP BY path_id) all_stops
							    ON (all_stops.path_id = a.path_id)
            GROUP BY a.path_id
        );
        ALTER TABLE indic.paths ADD CONSTRAINT paths_pkey PRIMARY KEY(gid);
        $$;
    
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'paths';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_node,d_node,days,day_type,per_type,per_start,per_end,time_point,time_start,time_end,time_inter,all_services,constraint_date_after, req)
    VALUES ('paths', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'paths')::character varying, 
           $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce(node_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(o_node::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(d_node::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce($$'$$ || time_point::character varying || $$'$$, $$NULL$$) || $$::time,   
           $$ || coalesce($$'$$ || time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || time_inter::character varying || $$'$$, $$NULL$$) || $$::integer,   
           $$ || all_services::character varying || $$::boolean,         
           $$ || constraint_date_after::character varying || $$::boolean, 
           '$$ || replace(s, $$'$$, $$''$$) || $$' );$$;
    RAISE NOTICE '%', t;
    EXECUTE(t);

    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 

