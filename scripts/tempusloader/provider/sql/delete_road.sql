-- Tempus - Road delete Wrapper
-- Parameter %(source_name) : POI source name to delete

-- Predelete
do 
$$
begin
    raise notice '==== Remove trigger and geometry indexes ===';
end
$$;

DROP TRIGGER IF EXISTS delete_isolated_road_nodes ON tempus.road_section;

SELECT _drop_index('tempus', 'road_section', 'id');
SELECT _drop_index('tempus', 'road_node', 'geom');
SELECT _drop_index('tempus', 'road_node', 'network_id');
SELECT _drop_index('tempus', 'road_section', 'geom');
SELECT _drop_index('tempus', 'road_section', 'network_id');
SELECT _drop_index('tempus', 'road_section', 'node_from');
SELECT _drop_index('tempus', 'road_section', 'node_to');


-- Delete
do 
$$
begin
    raise notice '==== Delete road elements ===';
end
$$;

DELETE FROM tempus.road_network
WHERE name = '%(source_name)';

-- Post delete

do 
$$
begin
    raise notice '==== Restore trigger and geometry indexes ===';
end
$$;

CREATE INDEX road_node_geom_idx ON tempus.road_node USING gist(geom);
  
CREATE INDEX ON tempus.road_node(network_id);
  
CREATE INDEX ON tempus.road_section USING gist(geom);
  
CREATE INDEX ON tempus.road_section(node_from);
CREATE INDEX ON tempus.road_section(node_to);
CREATE INDEX ON tempus.road_section(network_id); 

CREATE TRIGGER delete_isolated_road_nodes
  AFTER DELETE
  ON tempus.road_section
  FOR EACH ROW
  EXECUTE PROCEDURE tempus.delete_isolated_road_nodes_f();

VACUUM FULL ANALYSE;

