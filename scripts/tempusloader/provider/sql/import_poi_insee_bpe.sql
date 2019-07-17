/*

INSEE BPE POIs import

POI import needs the following templated fields :
%(poi_type): integer, type of the POI (1 - car park, 4 - shared cycle point, etc.), default to 5 (user POI)
%(source_name): string, name of the service (Bicloo, Velov, Marguerite)
%(filter): string, WHERE clause of the import, default to 'true' (no filter)

*/

INSERT INTO tempus.poi_source(name)
    VALUES ('%(source_name)');

INSERT INTO tempus.poi(
			    source_id, 
                poi_type, 
			    name, 
			    parking_transport_modes, 
			    geom)
    SELECT (SELECT max(id) FROM tempus.poi_source WHERE name = '%(source_name)'),
            '%(poi_type)', 
            'BPE INSEE - ' || varmod.modlibelle, 
            ARRAY[3], -- Only cars allowed to park (mode ID = 3)
            st_force3d(st_transform(st_setsrid(st_makepoint(bpe.lambert_x, bpe.lambert_y), 2154), 4326)) as geom
    FROM %(temp_schema).bpe_ensemble_xy bpe JOIN %(temp_schema).varmod_ensemble_xy varmod ON (varmod.modalite = bpe.typequ)
    WHERE varmod.variable = 'TYPEQU' AND bpe.lambert_x is not null AND bpe.lambert_y is not null AND %(filter); 


-- Attach each POI to a road section

-- first, CREATE an INDEX ON road_section geography 
CREATE INDEX ON tempus.road_section using gist(geography(geom));

-- reset sequences
DROP SEQUENCE IF EXISTS tempus.seq_road_node_id;
CREATE SEQUENCE tempus.seq_road_node_id start WITH 1;
SELECT setval('tempus.seq_road_node_id', (SELECT max(id) FROM tempus.road_node));

DROP SEQUENCE IF EXISTS tempus.seq_road_section_id;
CREATE SEQUENCE tempus.seq_road_section_id start WITH 1;
SELECT setval('tempus.seq_road_section_id', (SELECT max(id) FROM tempus.road_section));

DO
$$
DECLARE
    l_road_section_id bigint;
    l_node1_id bigint;
    l_node2_id bigint;
    l_abscissa_road_section float8;
    l_artificial boolean;
    point record;
BEGIN
    -- Use a loop here in order to make sure stops are compared to road sections
    -- while new road sections are created.
    FOR point IN
    SELECT * FROM tempus.poi WHERE source_id = (SELECT max(id) FROM tempus.poi_source WHERE name = '%(source_name)')
    LOOP
        l_road_section_id := null;
        -- get the closest road section (if any)
        SELECT INTO l_road_section_id, l_abscissa_road_section, l_artificial
                    road_section_id, abscissa, false
        FROM
        (
            SELECT 
                rs.id AS road_section_id
                , st_linelocatepoint(rs.geom, point.geom) AS abscissa
                , false
                , st_distance(rs.geom, point.geom) dist
            FROM tempus.road_section rs
            WHERE st_dwithin(geography(point.geom), geography(rs.geom), 50)
                -- attach to roads walkable by pedestrians
                AND ((rs.traffic_rules_ft & 1) > 0 OR (rs.traffic_rules_tf & 1) > 0)
            ORDER BY dist
            LIMIT 1
        ) t ;

        IF l_road_section_id IS NULL THEN
            -- no section, CREATE a fake one, FROM the stop geometry
            l_road_section_id := nextval('tempus.seq_road_section_id');
            l_abscissa_road_section := 0.5;
            l_artificial := true;
            l_node1_id := nextval('tempus.seq_road_node_id')::bigint;
            l_node2_id := nextval('tempus.seq_road_node_id')::bigint;

            -- new nodes
            INSERT INTO tempus.road_node(id, network_id, bifurcation, geom)
            (
            SELECT
                l_node1_id
                , 0
                , false AS bifurcation
                , st_translate(point.geom, -0.0001, 0, 0)
            UNION ALL
            SELECT
                l_node2_id
                , 0
                , false AS bifurcation
                , st_translate(point.geom, +0.0001, 0, 0)
            );

            -- new section
            INSERT INTO tempus.road_section (id, network_id, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, geom)
            (
                SELECT
                    l_road_section_id AS id,
                    0 AS network_id, 
                    l_node1_id AS node_from,
                    l_node2_id AS node_to,
                    1 AS traffic_rules_ft,
                    1 AS traffic_rules_tf,
                    0 AS length, 
                    -- create an artificial line around the stop
                    st_makeline(st_translate(point.geom, -0.0001,0,0), st_translate(point.geom, 0.0001,0,0)) AS geom
            );
        END IF;

        -- attach the stop to the road section
        UPDATE tempus.poi
        SET road_section_id = l_road_section_id, abscissa_road_section = l_abscissa_road_section
        WHERE id = point.id;
    END LOOP;    
END;
$$;

DROP INDEX tempus.road_section_geography_idx;



    