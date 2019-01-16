CREATE OR REPLACE FUNCTION tempus_access.create_comb_paths_trees_indicator_layer (
                                                                            param_indics integer[], 
                                                                            param_node_type integer, 
                                                                            param_root_nodes bigint[], 
                                                                            param_node_ag integer, 
                                                                            param_i_modes integer[], 
                                                                            param_pt_modes integer[],
                                                                            param_day date,
                                                                            param_day_type integer,
                                                                            param_per_type integer, 
                                                                            param_per_start date, 
                                                                            param_per_end date, 
                                                                            param_day_ag integer,
                                                                            param_time_point time, 
                                                                            param_time_start time,
                                                                            param_time_end time, 
                                                                            param_time_interval integer, 
                                                                            param_time_ag integer,
                                                                            param_constraint_date_after boolean,
                                                                            param_max_cost integer, 
                                                                            param_walking_speed double precision,
                                                                            param_cycling_speed double precision
                                                                           )
RETURNS void AS
$BODY$

DECLARE
    t character varying;
    s character varying;
    indics_time_ag character varying;
    indics_day_ag character varying;      
    indics_node_ag character varying;  
    time_ag_str character varying;
    day_ag_str character varying;
    node_ag_str character varying;
    r record;

BEGIN
	IF param_node_ag = 0 THEN param_node_ag = 1; END IF;
    IF param_time_ag = 0 THEN param_time_ag = 1; END IF;
    IF param_day_ag = 0 THEN param_day_ag = 1; END IF; 
    
    -- Update nodes and edges geometries
	UPDATE tempus_access.tempus_paths_tree_results 
	SET x_from = pred.x, y_from = pred.y
	FROM tempus_access.tempus_paths_tree_results pred
	WHERE pred.uid = tempus_paths_tree_results.predecessor AND pred.path_tree_id = tempus_paths_tree_results.path_tree_id; 
    
    UPDATE tempus_access.tempus_paths_tree_results
    SET geom_from = st_setsrid(st_makepoint(x_from, y_from), 4326),
        geom_to = st_setsrid(st_makepoint(x, y), 4326);
    
    -- Update road nodes and sections
    WITH q AS
    (
	SELECT tempus_paths_tree_results.gid, road_node.id
	FROM tempus_access.tempus_paths_tree_results
	CROSS JOIN LATERAL
		(
			SELECT id
			FROM tempus.road_node
			ORDER BY tempus_paths_tree_results.geom_from <-> road_node.geom
			LIMIT 1
		) AS road_node
    )
    UPDATE tempus_access.tempus_paths_tree_results
    SET road_node_from = q.id
    FROM q, tempus.transport_mode
    WHERE q.gid = tempus_paths_tree_results.gid 
      AND transport_mode.id = tempus_paths_tree_results.transport_mode 
      AND transport_mode.public_transport = False;
    
    WITH q AS
    (
	SELECT tempus_paths_tree_results.gid, road_node.id
	FROM tempus_access.tempus_paths_tree_results
	CROSS JOIN LATERAL
		(
			SELECT id
			FROM tempus.road_node
			ORDER BY tempus_paths_tree_results.geom_to <-> road_node.geom
			LIMIT 1
		) AS road_node
    )
    UPDATE tempus_access.tempus_paths_tree_results
    SET road_node_to = q.id
    FROM q, tempus.transport_mode
    WHERE q.gid = tempus_paths_tree_results.gid 
      AND transport_mode.id = tempus_paths_tree_results.transport_mode 
      AND transport_mode.public_transport = False;
        
    UPDATE tempus_access.tempus_paths_tree_results
    SET road_section_id = road_section.id, 
        ft = CASE WHEN (road_section.node_from = road_node_from AND road_section.node_to = road_node_to) THEN True ELSE False END, 
        geom_to = CASE WHEN (road_section.node_from = road_node_from AND road_section.node_to = road_node_to) THEN st_force2d(st_endpoint(road_section.geom)) ELSE st_force2d(st_startpoint(road_section.geom)) END
    FROM tempus.transport_mode, tempus.road_section
    WHERE tempus_paths_tree_results.transport_mode = transport_mode.id 
      AND transport_mode.public_transport = False 
      AND ((road_section.node_from = road_node_from AND road_section.node_to = road_node_to) OR (road_section.node_to = road_node_from AND road_section.node_from = road_node_to));
    
    -- Update PT nodes and sections
    WITH q AS
    (
	SELECT tempus_paths_tree_results.gid, stop.id
	FROM tempus_access.tempus_paths_tree_results
	CROSS JOIN LATERAL
		(
			SELECT id
			FROM tempus_gtfs.stops
			ORDER BY tempus_paths_tree_results.geom_from <-> stops.geom
			LIMIT 1
		) AS stop
    )
    UPDATE tempus_access.tempus_paths_tree_results
    SET pt_node_from = q.id
    FROM q, tempus.transport_mode
    WHERE q.gid = tempus_paths_tree_results.gid AND transport_mode.id = tempus_paths_tree_results.transport_mode AND transport_mode.public_transport = True;
    
    WITH q AS
    (
	SELECT tempus_paths_tree_results.gid, stop.id
	FROM tempus_access.tempus_paths_tree_results
	CROSS JOIN LATERAL
		(
			SELECT id
			FROM tempus_gtfs.stops
			ORDER BY tempus_paths_tree_results.geom_to <-> stops.geom
			LIMIT 1
		) AS stop
    )
    UPDATE tempus_access.tempus_paths_tree_results
    SET pt_node_to = q.id
    FROM q, tempus.transport_mode
    WHERE q.gid = tempus_paths_tree_results.gid AND transport_mode.id = tempus_paths_tree_results.transport_mode AND transport_mode.public_transport = True;
    
    UPDATE tempus_access.tempus_paths_tree_results
    SET pt_section_id = sections.section_id, route_type = sections.route_type, 
        ft = CASE WHEN (sections.stop_from = pt_node_from AND sections.stop_to = pt_node_to) THEN True ELSE False END,         
        geom_to = CASE WHEN (sections.stop_from = pt_node_from AND sections.stop_to = pt_node_to) THEN st_endpoint(st_force2d(sections.geom)) ELSE st_startpoint(st_force2d(sections.geom)) END
    FROM tempus.transport_mode, tempus_gtfs.sections_by_mode sections
    WHERE tempus_paths_tree_results.transport_mode = transport_mode.id AND transport_mode.public_transport = True
      AND ((sections.stop_from = pt_node_from AND sections.stop_to = pt_node_to) OR (sections.stop_to = pt_node_from AND sections.stop_from = pt_node_to));
    
    -- Add facultative indicators
    SELECT INTO node_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_node_ag;
    
    SELECT INTO day_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_day_ag;

    SELECT INTO time_ag_str 
                func_name 
    FROM tempus_access.agregates WHERE code = param_time_ag; 
    
    indics_node_ag= '';
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics)
    LOOP 
        indics_node_ag = indics_node_ag || (SELECT coalesce(replace(node_ag_comb_paths_trees, '%(node_ag)', node_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name); 
        indics_time_ag = indics_time_ag || (SELECT coalesce(replace(day_ag_comb_paths_trees, '%(day_ag)', time_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);
        indics_day_ag = indics_day_ag || (SELECT coalesce(replace(day_ag_comb_paths_trees, '%(day_ag)', day_ag_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);      
    END LOOP; 
    
    
    indics_node_ag = substring(indics_day_ag from 1 for length(indics_node_ag) - 2); 
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2); 
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2); 
    
    
	s=$$DROP TABLE IF EXISTS indic.comb_paths_trees;
	CREATE TABLE indic.comb_paths_trees AS
	(
        SELECT row_number() over() as gid, 
               $$ || indics_day_ag || $$, 
               geom
        FROM   
        (
            SELECT cast(dep_arr_time as date) as day,
                   $$ || indics_time_ag || $$, 
                   geom
            FROM
                (
                    SELECT dep_arr_time, 
                           constraint_date_after,
                           $$ || indics_node_ag || $$, 
                           st_setsrid(st_makepoint(x, y), 4326) as geom
                    FROM tempus_access.tempus_paths_tree_results
                    GROUP BY x, y, constraint_date_after, dep_arr_time
                ) node_agregation
            GROUP BY geom, cast(dep_arr_time as date)
        ) time_agregation
        GROUP BY geom -- days agregation
	);
    ALTER TABLE indic.comb_paths_trees ADD COLUMN symbol_color real; 
    $$;
    RAISE NOTICE '%', s;
    EXECUTE(s);
    
    -- Update of the indicators catalog 
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'comb_paths_trees';
		INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_nodes,d_nodes,i_modes,pt_modes,nodes_ag,days,day_type,per_type,per_start,per_end,time_start,time_end,time_inter,time_point,constraint_date_after, max_cost, walk_speed, cycl_speed)
		VALUES ('comb_paths_trees', 
		   (SELECT code FROM tempus_access.obj_type WHERE def_name = 'comb_paths_trees')::character varying, 
		   $$ || coalesce($$'$$ || param_indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
		   $$ || coalesce(param_node_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || CASE WHEN param_constraint_date_after = True THEN $$'$$ || param_root_nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],   
		   $$ || CASE WHEN param_constraint_date_after = False THEN $$'$$ || param_root_nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],            
		   $$ || coalesce($$'$$ || param_i_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce($$'$$ || param_pt_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce(param_node_ag::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
		   $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
		   $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
		   $$ || coalesce($$'$$ || param_time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || param_time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || param_time_interval::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_time_point::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || param_constraint_date_after::character varying || $$::boolean, 
		   $$ || coalesce(param_max_cost::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce(param_walking_speed::character varying, $$NULL$$) || $$::double precision, 
		   $$ || coalesce(param_cycling_speed::character varying, $$NULL$$) || $$::double precision
		);$$; 
    RAISE NOTICE '%', t;
    EXECUTE(t);
    
    
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 


