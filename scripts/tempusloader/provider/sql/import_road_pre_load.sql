do $$
begin
raise notice '==== Reset import schema ===';
end$$;

/* Drop import schema and recreate it */
DROP SCHEMA IF EXISTS %(temp_schema) CASCADE;
CREATE SCHEMA %(temp_schema);

do $$
begin
raise notice '==== Pre-load : remove constraints and indexes (performances concern) ===';
end$$;

-- Remove all related constraints
ALTER TABLE tempus.road_section 
    DROP CONSTRAINT IF EXISTS road_section_node_from_fkey;
ALTER TABLE tempus.road_section
    DROP CONSTRAINT IF EXISTS road_section_node_to_fkey;
ALTER TABLE tempus.road_section_speed 
    DROP CONSTRAINT IF EXISTS road_section_speed_road_section_id_fkey;
ALTER TABLE tempus.poi 
    DROP CONSTRAINT IF EXISTS poi_road_section_id_fkey;
ALTER TABLE tempus_gtfs.stops 
    DROP CONSTRAINT IF EXISTS stops_road_section_id_fkey;

do $$
begin
raise notice '==== Dropping road nodes and sections indexes ===';
end
$$;

SELECT _drop_index('tempus', 'road_node', 'geom');
SELECT _drop_index('tempus', 'road_section', 'geom');
SELECT _drop_index('tempus', 'road_section', 'node_from');
SELECT _drop_index('tempus', 'road_section', 'node_to');

DROP TRIGGER IF EXISTS delete_isolated_road_nodes ON tempus.road_section;

DELETE FROM tempus.road_network
WHERE name='%(source_name)';

INSERT INTO tempus.road_network(name, comment)
VALUES('%(source_name)', '%(source_comment)');

