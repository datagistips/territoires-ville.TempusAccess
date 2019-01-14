CREATE OR REPLACE FUNCTION tempus_access.create_comb_paths_trees_indicator_layer (
                                                                            param_indics integer[], 
                                                                            param_node_type integer, 
                                                                            param_nodes bigint[], 
                                                                            param_nodes_ag integer, 
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
                                                                            param_time_const_after boolean,
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
	IF param_nodes_ag = 0 THEN param_nodes_ag = 1; END IF;
    IF param_time_ag = 0 THEN param_time_ag = 1; END IF;
    IF param_day_ag = 0 THEN param_day_ag = 1; END IF; 
    
    indics_str = ''; 
    CREATE SCHEMA IF NOT EXISTS indic;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ param_indics ORDER BY code)
    LOOP
        IF (r.col_name = 'total_time2') -- Total time to the destination node of the section
        THEN
            indics_str = indics_str || $$round(CASE WHEN $$ || day_ag || $$ = 1 THEN avg(total_time) WHEN $$ || day_ag || $$ = 2 THEN min(total_time) WHEN $$ || day_ag || $$ = 3 THEN max(total_time) END::numeric, 2) AS total_time2, $$;
        END IF;
        
        IF (r.col_name = 'tran_numb') -- Number of PT transfers
        THEN 
            indics_str = indics_str || $$round(CASE WHEN $$ || day_ag || $$ = 1 THEN avg(tran_numb) WHEN $$ || day_ag || $$ = 2 THEN min(tran_numb) WHEN $$ || day_ag || $$ = 3 THEN max(tran_numb) END::numeric,2) AS tran_numb, $$;
        END IF; 
        
        IF (r.col_name = 'mode_chang') -- Number of mode changes
        THEN
            indics_str = indics_str || $$round(CASE WHEN $$ || day_ag || $$ = 1 THEN avg(mode_chang) WHEN $$ || day_ag || $$ = 2 THEN min(mode_chang) WHEN $$ || day_ag || $$ = 3 THEN max(mode_chang) END::numeric, 2) AS mode_chang, $$;
        END IF; 
    END LOOP; 
    
	s=$$DROP TABLE IF EXISTS indic.comb_paths_trees;
	CREATE TABLE indic.comb_paths_trees AS
	(
        SELECT row_number() over() as gid, 
               $$ || indics_str || $$
               geom
        FROM   
        (
            SELECT cast(dep_arr_time as date) as day,
                   CASE WHEN $$ || param_time_ag || $$ = 1 THEN avg(total_time) WHEN $$ || time_ag || $$ = 2 THEN min(total_time) WHEN $$ || time_ag || $$ = 3 THEN max(total_time) END AS total_time, 
                   CASE WHEN $$ || param_time_ag || $$ = 1 THEN avg(tran_numb) WHEN $$ || time_ag || $$ = 2 THEN min(tran_numb) WHEN $$ || time_ag || $$ = 3 THEN max(tran_numb) END AS tran_numb,
                   CASE WHEN $$ || param_time_ag || $$ = 1 THEN avg(mode_chang) WHEN $$ || time_ag || $$ = 2 THEN min(mode_chang) WHEN $$ || time_ag || $$ = 3 THEN max(mode_chang) END AS mode_chang, 
                   geom
            FROM
                (
                    SELECT dep_arr_time, 
                           constraint_date_after,
                           CASE WHEN $$ || param_nodes_ag || $$ = 1 THEN avg(total_cost) WHEN $$ || nodes_ag || $$ = 2 THEN min(total_cost) WHEN $$ || nodes_ag || $$ = 3 THEN max(total_cost) END AS total_time, 
                           CASE WHEN $$ || param_nodes_ag || $$ = 1 THEN avg(pt_changes) WHEN $$ || nodes_ag || $$ = 2 THEN min(pt_changes) WHEN $$ || nodes_ag || $$ = 3 THEN max(pt_changes) END AS tran_numb, 
                           CASE WHEN $$ || param_nodes_ag || $$ = 1 THEN avg(mode_changes) WHEN $$ || nodes_ag || $$ = 2 THEN min(mode_changes) WHEN $$ || nodes_ag || $$ = 3 THEN max(mode_changes) END AS mode_chang, 
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
		   $$ || CASE WHEN param_time_const_after = True THEN $$'$$ || nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],   
		   $$ || CASE WHEN param_time_const_after = False THEN $$'$$ || nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],            
		   $$ || coalesce($$'$$ || param_i_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce($$'$$ || param_pt_modes::character varying || $$'$$, $$NULL$$) || $$::integer[],
           $$ || coalesce(param_nodes_ag::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || (SELECT tempus_access.days(param_day, param_day_type, param_per_type, param_per_start, param_per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
		   $$ || coalesce(param_day_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce(param_per_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || param_per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
		   $$ || coalesce($$'$$ || param_per_end::character varying || $$'$$, $$NULL$$) || $$::date,
		   $$ || coalesce($$'$$ || param_time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || param_time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || param_time_interval::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || param_time_point::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || param_time_const_after::character varying || $$::boolean, 
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


