CREATE OR REPLACE FUNCTION tempus_access.create_paths_tree_indicator_layer(
                                                                                indics integer[], 
                                                                                node_type integer, 
                                                                                root_node bigint, 
                                                                                tran_modes integer[], 
                                                                                day date,
                                                                                time_point time, 
                                                                                const_date_after boolean,
                                                                                max_cost integer, 
                                                                                walk_speed double precision,
                                                                                cycl_speed double precision
                                                                          )
RETURNS void AS
$BODY$

DECLARE
    t character varying;
    s character varying;
    indics_str character varying;
    r record;

BEGIN
    
	-- Update of the temporary results table
	UPDATE tempus_access.tempus_paths_tree_results 
	SET x_from = pred.x, y_from = pred.y
	FROM tempus_access.tempus_paths_tree_results pred
	WHERE pred.uid = tempus_paths_tree_results.predecessor AND pred.path_tree_id = tempus_paths_tree_results.path_tree_id; 

    
    indics_str = ''; 
    CREATE SCHEMA IF NOT EXISTS indic;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics ORDER BY code)
    LOOP
        IF (r.col_name = 'total_time2') -- Total time to the destination node of the section
        THEN
            indics_str = indics_str || $$total_cost AS total_time2, $$;
        END IF;
        
        IF (r.col_name = 'tran_numb') -- Number of PT transfers
        THEN 
            indics_str = indics_str || $$pt_changes AS tran_numb, $$;
        END IF; 
        
        IF (r.col_name = 'mode_chang') -- Number of mode changes
        THEN
            indics_str = indics_str || $$CASE WHEN mode_changes=-1 THEN 0 ELSE mode_changes END AS mode_chang, $$;
        END IF; 
        
        IF (r.col_name = 'speed_kmh') -- Speed (km/h)
        THEN 
            indics_str = indics_str || $$CASE WHEN cost>0 THEN (st_length(st_transform(st_makeline(st_setsrid(st_makepoint(x_from, y_from), 4326), st_setsrid(st_makepoint(x, y), 4326)), 2154))/(cost*60))*3.6 END AS speed_kmh, $$;
        END IF;
    END LOOP; 
    
    
	s=$$DROP TABLE IF EXISTS indic.paths_tree;
	CREATE TABLE indic.paths_tree AS
	(
		SELECT 
		   uid AS d_node, 
		   predecessor AS o_node, 
		   CASE WHEN transport_mode.public_transport = TRUE THEN 'Public transport' ELSE transport_mode.name END AS t_mode,
           (total_cost::character varying || ' minutes')::interval::character varying as d_time, 		
		   ((total_cost - cost)::character varying || ' minutes')::interval::character varying AS o_time,    
           $$ || indics_str || $$
		   st_makeline(st_setsrid(st_makepoint(x_from, y_from), 4326), st_setsrid(st_makepoint(x, y), 4326)) as geom_section, 
		   st_setsrid(st_makepoint(x, y), 4326) as geom_point
		FROM tempus_access.tempus_paths_tree_results JOIN tempus.transport_mode ON (tempus_paths_tree_results.transport_mode = transport_mode.id) 
	);
    ALTER TABLE indic.paths_tree 
    ADD CONSTRAINT paths_tree_pkey PRIMARY KEY(d_node);
        
    ALTER TABLE indic.paths_tree ADD COLUMN symbol_color real; 
    $$;
    RAISE NOTICE '%', s;
    EXECUTE(s); 

    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'paths_tree';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_node,d_node,days,time_point,constraint_date_after, max_cost, walk_speed, cycl_speed)
    VALUES ('paths_tree', 
       (SELECT code FROM tempus_access.obj_type WHERE def_name = 'paths_tree'),
       $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
       $$ || coalesce(node_type::character varying, $$NULL$$) || $$::integer, 
       $$ || CASE WHEN const_date_after=TRUE THEN root_node::character varying ELSE $$NULL$$ END || $$::integer,
       $$ || CASE WHEN const_date_after=FALSE THEN root_node::character varying ELSE $$NULL$$ END || $$::integer,
       $$ || coalesce($$ARRAY['$$ || day || $$']$$::character varying, $$NULL$$) || $$::date[], 
       $$ || coalesce($$'$$ || time_point::character varying || $$'$$, $$NULL$$) || $$::time,   
       $$ || const_date_after::character varying || $$::boolean, 
       $$ || coalesce(max_cost::character varying, $$NULL$$) || $$::integer, 
       $$ || coalesce(walk_speed::character varying, $$NULL$$) || $$::double precision, 
       $$ || coalesce(cycl_speed::character varying, $$NULL$$) || $$::double precision
    );$$;
    RAISE NOTICE '%', t;
    EXECUTE(t); 
    
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 

