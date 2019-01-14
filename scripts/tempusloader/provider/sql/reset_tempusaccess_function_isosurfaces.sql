CREATE OR REPLACE FUNCTION tempus_access.create_isosurfaces_indicator_layer(
                                                                                param_indics integer,
                                                                                param_parent_layer character varying,
                                                                                param_classes_num integer, 
                                                                                param_param double precision,
                                                                                param_rep_meth integer
                                                                           )
RETURNS void AS
$BODY$

DECLARE
    s character varying;
    t character varying;
    r record;
    counter integer;
    min_cost double precision;
    max_cost double precision;

BEGIN
    -- Calcul du plus petit coût pour lequel on a au moins trois points
    s=$$SELECT min(cost)
        FROM
        (
            SELECT i as cost, 
                   (SELECT count(gid) FROM indic.$$ || param_parent_layer || $$ WHERE $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = indic)::character varying || $$ <= i) as count
            FROM generate_series(1, (SELECT max($$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$)+1 FROM indic.$$ || param_parent_layer || $$)::integer, 1) i
        ) q
        WHERE count>3
      $$;
    RAISE NOTICE '%', s;
    
    counter=0;
    FOR r IN EXECUTE(s)
    LOOP
        counter=counter+1;
        min_cost = r.min;
    END LOOP;

    s=$$SELECT max($$ || (SELECT col_name FROM tempus_access.indicators WHERE code = indic) || $$) FROM indic.$$ || param_parent_layer;
    RAISE NOTICE '%', s;
    FOR r IN EXECUTE(s)
    LOOP
        max_cost = r.max;
    END LOOP; 
    RAISE NOTICE '%', max_cost; 
    
    -- Si on a au moins trois points et moins de classes que la valeur maximum du coût, on peut construire les surfaces
    IF (counter>0) AND (max_cost > param_classes_num)
    THEN 
	    DROP TABLE IF EXISTS indic.isosurfaces;
	    IF (param_rep_meth=1) THEN
            s=$$CREATE TABLE indic.isosurfaces AS
            (
                SELECT row_number() over() AS gid, 
                       i AS $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$, 
                       i/$$ || max_cost || $$ AS symbol_color, 
                       st_setsrid(pgr_pointsAsPolygon(
                                                        'SELECT gid::integer as id, st_x(geom) as x, st_y(geom) as y, $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$ FROM indic.$$ || param_parent_layer || $$ WHERE $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$ <= ' || greatest(i, $$ || min_cost::character varying || $$)::text, 
                                                        $$ || param_param::character varying || $$
                                                     )
                                 , 4326) AS geom
                FROM generate_series(1,
                                    $$ || max_cost+1 || $$,
                                     greatest(1,$$ || max_cost || $$/$$ || param_classes_num::character varying || $$::double precision)::integer
                                    ) i
                WHERE i>=$$ || min_cost::character varying || $$
                ORDER BY i DESC LIMIT $$ || param_classes_num::character varying || $$
            );
            ALTER TABLE indic.isosurfaces
            ADD CONSTRAINT isosurfaces_pkey PRIMARY KEY(gid);
            $$;
        ELSIF (param_rep_meth=2) THEN
            s=$$CREATE TABLE indic.isosurfaces AS
            (
                SELECT row_number() over() AS gid, 
                       i AS $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$, 
                       i/$$ || max_cost || $$ AS symbol_color, 
                       st_setsrid(st_concavehull(
                                                (SELECT st_collect(geom) FROM indic.$$ || param_parent_layer || $$ WHERE $$ || (SELECT col_name FROM tempus_access.indicators WHERE code = $1)::character varying || $$ <= greatest(i, $$ || min_cost::character varying || $$)), 
                                                $$ || param_param || $$,
                                                true
                                                )
                                 , 4326) AS geom
                FROM generate_series(1,
                                     $$ || max_cost+1 || $$,
                                     greatest(1,$$ || max_cost || $$/$$ || param_classes_num::character varying || $$::double precision)::integer
                                    ) i
                WHERE i>=$$ || min_cost::character varying || $$
                ORDER BY i DESC LIMIT $$ || param_classes_num::character varying || $$
            );
            ALTER TABLE indic.isosurfaces
            ADD CONSTRAINT isosurfaces_pkey PRIMARY KEY(gid);
            $$;
        END IF;
		RAISE NOTICE '%', s;
		EXECUTE(s); 

		t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'isosurfaces';
		    INSERT INTO tempus_access.indic_catalog(obj_type, layer_name, indics, parent_layer, classes_num, param, rep_meth)
		    VALUES ((SELECT obj_type FROM tempus_access.indic_catalog WHERE layer_name = '$$ || param_parent_layer || $$'), 
                    'isosurfaces', 
                    ARRAY[$$ || indic::character varying || $$], 
                    '$$ || param_parent_layer || $$', 
                    $$ || param_classes_num::character varying || $$, 
                    $$ || param_param::character varying || $$, 
                    $$ || param_rep_meth::character varying || $$
                    );$$;
		RAISE NOTICE '%', t;
		EXECUTE(t); 
    END IF;

    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 