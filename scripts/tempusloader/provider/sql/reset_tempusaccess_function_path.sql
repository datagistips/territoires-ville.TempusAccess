CREATE OR REPLACE FUNCTION tempus_access.create_path_indicator_layer(
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
                   CASE WHEN tempus_paths_results.step_type = 0 THEN 'Attente' 
                        WHEN tempus_paths_results.step_type = 1 THEN 'Public transport' 
                        WHEN tempus_paths_results.step_type = 2 THEN transport_mode.name
                   END as step_mode, 
                   CASE WHEN tempus_paths_results.road_edge_id IS NOT NULL 
                            THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE road_edge_id = road_section.id)
                        WHEN tempus_paths_results.step_type = 1 
                            THEN (SELECT st_multi(st_force2d(tempus_access.pt_section(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer)))) 
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) 
                            THEN COALESCE(
                                         (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE node_from = tempus_paths_results.source_road_vertex_id AND node_to = tempus_paths_results.target_road_vertex_id), 
                                         (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id)
                                         )
                        WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_pt_stop_id IS NOT NULL) 
                            THEN (SELECT st_multi(st_force2d(tempus_access.road_section(target_pt_stop_id::integer, source_road_vertex_id::integer))))
                        WHEN tempus_paths_results.step_type = 2 AND (target_road_vertex_id IS NOT NULL AND source_pt_stop_id IS NOT NULL) 
                            THEN (SELECT st_multi(st_force2d(tempus_access.road_section(source_pt_stop_id::integer, target_road_vertex_id::integer))))
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
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics)
    LOOP 
        indics_str = indics_str || (SELECT coalesce(replace(day_ag_paths, '%(day_ag)', indics_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);         
    END LOOP; 
    
    s = $$DROP TABLE IF EXISTS indic.paths; 
        CREATE TABLE indic.paths AS
        (
            SELECT a.path_id as gid, min(first_o_time) as dep, max(last_d_time) as arr, (max(last_d_time) - min(first_o_time))::time as total_time, 
                   $$ || indics_str || $$
                   st_multi(st_force2d(st_linemerge(st_union(geom)))) as geom
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
            ) a 
            LEFT JOIN 
            (
                SELECT path_id, array_remove(array_agg(f.stop_name order by path_id, step_id, stop_order), NULL) all_stops 
                FROM tempus_access.tempus_paths_results
                LEFT JOIN LATERAL unnest(tempus_paths_results.all_stops) WITH ORDINALITY AS f(stop_name, stop_order) 
                    ON true GROUP BY path_id
            ) all_stops
            ON (all_stops.path_id = a.path_id)
            GROUP BY a.path_id
        );
        ALTER TABLE indic.paths ADD CONSTRAINT paths_pkey PRIMARY KEY(gid);
        $$;
    
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'paths';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_node,d_node,i_modes,pt_modes,days,day_type,per_type,per_start,per_end,time_point,time_start,time_end,time_inter,all_services,constraint_date_after)
    VALUES ('paths', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'paths')::character varying, 
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

