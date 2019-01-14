CREATE OR REPLACE FUNCTION tempus_access.create_paths_tree_indicator_layer(
                                                                                param_indics integer[], 
                                                                                param_node_type integer, 
                                                                                param_root_node bigint, 
                                                                                param_i_modes integer[], 
                                                                                param_pt_modes integer[],
                                                                                param_day date,
                                                                                param_time_point time, 
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
    indics_str character varying;
    r record;

BEGIN
    
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
    FROM q
    WHERE q.gid = tempus_paths_tree_results.gid;
    
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
    FROM q
    WHERE q.gid = tempus_paths_tree_results.gid;
        
    UPDATE tempus_access.tempus_paths_tree_results
    SET road_section_id = road_section.id
    FROM tempus.transport_mode, tempus.road_section
    WHERE tempus_paths_tree_results.transport_mode = transport_mode.id AND transport_mode.public_transport = FALSE 
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
    FROM q
    WHERE q.gid = tempus_paths_tree_results.gid;
    
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
    FROM q
    WHERE q.gid = tempus_paths_tree_results.gid;
    
    UPDATE tempus_access.tempus_paths_tree_results
    SET pt_section_id = sections.id
    FROM tempus.transport_mode, tempus_gtfs.sections
    WHERE tempus_paths_tree_results.transport_mode = transport_mode.id AND transport_mode.public_transport = FALSE 
      AND ((sections.stop_from = pt_node_from AND sections.stop_to = pt_node_to) OR (sections.stop_to = pt_node_from AND sections.node_from = pt_node_to));
    
    -- Add facultative indicators
    indics_str = ''; 
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics)
    LOOP 
        indics_str = indics_str || (SELECT coalesce(replace(day_ag_paths_trees, '%(day_ag)', indics_str::character varying) || ' AS ' || r.col_name || ', ', '') FROM tempus_access.indicators WHERE col_name = r.col_name);         
    END LOOP;  
    
    -- Create final table
	s=$$
        DROP TABLE IF EXISTS indic.paths_tree;
        CREATE TABLE indic.paths_tree AS
        (
            SELECT 
               uid AS d_node, 
               predecessor AS o_node, 
               CASE WHEN transport_mode.public_transport = TRUE THEN 'Public transport' ELSE transport_mode.name END AS t_mode,
               (total_cost::character varying || ' minutes')::interval::character varying AS d_time, 		
               ((total_cost - cost)::character varying || ' minutes')::interval::character varying AS o_time,    
               $$ || indics_str || $$
               CASE WHEN road_section_id IS NOT NULL THEN road_section.geom
                    WHEN pt_section_id IS NOT NULL THEN sections.geom
               END AS geom_section, 
               st_setsrid(st_makepoint(x, y), 4326) AS geom_point
            FROM tempus_access.tempus_paths_tree_results JOIN tempus.transport_mode ON (tempus_paths_tree_results.transport_mode = transport_mode.id)
                                                         LEFT JOIN tempus.road_section ON (tempus_paths_tree_results.road_section_id = road_section.id)
                                                         LEFT JOIN tempus_gtfs.sections ON (tempus_paths_tree_results.pt_section_id = sections.id)
        );
        ALTER TABLE indic.paths_tree 
        ADD CONSTRAINT paths_tree_pkey PRIMARY KEY(d_node);
            
        ALTER TABLE indic.paths_tree ADD COLUMN symbol_color real; 
    $$;
    RAISE NOTICE '%', s;
    EXECUTE(s); 

    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'paths_tree';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_node,d_node,i_modes,pt_modes,days,time_point,constraint_date_after, max_cost, walk_speed, cycl_speed)
    VALUES ('paths_tree', 
       (SELECT code FROM tempus_access.obj_type WHERE def_name = 'paths_tree'),
       $$ || coalesce($$'$$ || param_indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
       $$ || coalesce(param_node_type::character varying, $$NULL$$) || $$::integer, 
       $$ || CASE WHEN param_constraint_date_after=TRUE THEN param_root_node::character varying ELSE $$NULL$$ END || $$::integer,
       $$ || CASE WHEN param_constraint_date_after=FALSE THEN param_root_node::character varying ELSE $$NULL$$ END || $$::integer,
       $$ || coalesce($$'$$ || param_i_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
       $$ || coalesce($$'$$ || param_pt_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
       $$ || coalesce($$ARRAY['$$ || param_day || $$']$$::character varying, $$NULL$$) || $$::date[], 
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

