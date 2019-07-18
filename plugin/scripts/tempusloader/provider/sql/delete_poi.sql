-- Tempus - POI delete Wrapper
-- Parameter %(source_name) : POI source name to delete

-- Predelete
do 
$$
begin
    raise notice '==== Remove road constraints and geometry indexes ===';
end
$$;

ALTER TABLE tempus.road_section 
    DROP CONSTRAINT IF EXISTS road_section_node_from_fkey;
ALTER TABLE tempus.road_section
    DROP CONSTRAINT IF EXISTS road_section_node_to_fkey;
ALTER TABLE tempus.road_section_speed 
    DROP CONSTRAINT IF EXISTS road_section_speed_road_section_id_fkey;

DROP TRIGGER delete_isolated_road_nodes ON tempus.road_section;

SELECT _drop_index('tempus', 'road_node', 'geom');
SELECT _drop_index('tempus', 'road_section', 'geom');
SELECT _drop_index('tempus', 'road_section', 'node_from');
SELECT _drop_index('tempus', 'road_section', 'node_to');


-- Delete
do 
$$
begin
    raise notice '==== Delete POI ===';
end
$$;

DELETE FROM tempus.poi_source
WHERE name = '%(source_name)'; 

-- Post delete

do $$
begin
raise notice '==== Restore road constraints and geometry indexes ===';
end$$;

ALTER TABLE tempus.road_section_speed 
    ADD CONSTRAINT road_section_speed_road_section_id_fkey FOREIGN KEY (road_section_id) REFERENCES tempus.road_section(id);
ALTER TABLE tempus.poi 
    ADD CONSTRAINT poi_road_section_id_fkey FOREIGN KEY (road_section_id) REFERENCES tempus.road_section(id);
ALTER TABLE tempus_gtfs.stops 
    ADD CONSTRAINT stops_road_section_id_fkey FOREIGN KEY (road_section_id) REFERENCES tempus.road_section(id);
ALTER TABLE tempus.road_section 
    ADD CONSTRAINT road_section_node_from_fkey FOREIGN KEY (node_from) REFERENCES tempus.road_node(id);
ALTER TABLE tempus.road_section
    ADD CONSTRAINT road_section_node_to_fkey FOREIGN KEY (node_to) REFERENCES tempus.road_node(id);

CREATE INDEX road_node_geom_idx
  ON tempus.road_node 
  USING gist(geom);
  
CREATE INDEX 
  ON tempus.road_section 
  USING gist(geom);
  
CREATE INDEX ON tempus.road_section(node_from);
CREATE INDEX ON tempus.road_section(node_to);
  
CREATE TRIGGER delete_isolated_road_nodes
  AFTER DELETE
  ON tempus.road_section
  FOR EACH ROW
  EXECUTE PROCEDURE tempus.delete_isolated_road_nodes_f();

VACUUM FULL ANALYSE;


