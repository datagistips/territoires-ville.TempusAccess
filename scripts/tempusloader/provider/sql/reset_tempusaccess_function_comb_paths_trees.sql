CREATE OR REPLACE FUNCTION tempus_access.create_comb_paths_trees_indicator_layer (
                                                                            indics integer[], 
                                                                            node_type integer, 
                                                                            nodes bigint[], 
                                                                            nodes_ag integer, 
                                                                            tran_modes integer[], 
                                                                            day date,
                                                                            day_type integer,
                                                                            per_type integer, 
                                                                            per_start date, 
                                                                            per_end date, 
                                                                            day_ag integer,
                                                                            time_point time, 
                                                                            time_start time,
                                                                            time_end time, 
                                                                            time_interval integer, 
                                                                            time_ag integer,
                                                                            time_const_after boolean,
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
	IF nodes_ag = 0 THEN nodes_ag = 1; END IF;
    IF time_ag = 0 THEN time_ag = 1; END IF;
    IF day_ag = 0 THEN day_ag = 1; END IF; 
    
    indics_str = ''; 
    CREATE SCHEMA IF NOT EXISTS indic;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics ORDER BY code)
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
                   CASE WHEN $$ || time_ag || $$ = 1 THEN avg(total_time) WHEN $$ || time_ag || $$ = 2 THEN min(total_time) WHEN $$ || time_ag || $$ = 3 THEN max(total_time) END AS total_time, 
                   CASE WHEN $$ || time_ag || $$ = 1 THEN avg(tran_numb) WHEN $$ || time_ag || $$ = 2 THEN min(tran_numb) WHEN $$ || time_ag || $$ = 3 THEN max(tran_numb) END AS tran_numb,
                   CASE WHEN $$ || time_ag || $$ = 1 THEN avg(mode_chang) WHEN $$ || time_ag || $$ = 2 THEN min(mode_chang) WHEN $$ || time_ag || $$ = 3 THEN max(mode_chang) END AS mode_chang, 
                   geom
            FROM
                (
                    SELECT dep_arr_time, 
                           constraint_date_after,
                           CASE WHEN $$ || nodes_ag || $$ = 1 THEN avg(total_cost) WHEN $$ || nodes_ag || $$ = 2 THEN min(total_cost) WHEN $$ || nodes_ag || $$ = 3 THEN max(total_cost) END AS total_time, 
                           CASE WHEN $$ || nodes_ag || $$ = 1 THEN avg(pt_changes) WHEN $$ || nodes_ag || $$ = 2 THEN min(pt_changes) WHEN $$ || nodes_ag || $$ = 3 THEN max(pt_changes) END AS tran_numb, 
                           CASE WHEN $$ || nodes_ag || $$ = 1 THEN avg(mode_changes) WHEN $$ || nodes_ag || $$ = 2 THEN min(mode_changes) WHEN $$ || nodes_ag || $$ = 3 THEN max(mode_changes) END AS mode_chang, 
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
		INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,node_type,o_nodes,d_nodes,nodes_ag,days,day_type,per_type,per_start,per_end,time_start,time_end,time_inter,time_point,constraint_date_after, max_cost, walk_speed, cycl_speed)
		VALUES ('comb_paths_trees', 
		   (SELECT code FROM tempus_access.obj_type WHERE def_name = 'comb_paths_trees')::character varying, 
		   $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
		   $$ || coalesce(node_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || CASE WHEN time_const_after = True THEN $$'$$ || nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],   
		   $$ || CASE WHEN time_const_after = False THEN $$'$$ || nodes::character varying || $$'$$ ELSE $$NULL$$ END || $$::integer[],            
		   $$ || coalesce(nodes_ag::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || (SELECT tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
		   $$ || coalesce(day_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce(per_type::character varying, $$NULL$$) || $$::integer, 
		   $$ || coalesce($$'$$ || per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
		   $$ || coalesce($$'$$ || per_end::character varying || $$'$$, $$NULL$$) || $$::date,
		   $$ || coalesce($$'$$ || time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || coalesce($$'$$ || time_interval::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || time_point::character varying || $$'$$, $$NULL$$) || $$::time, 
		   $$ || time_const_after::character varying || $$::boolean, 
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


