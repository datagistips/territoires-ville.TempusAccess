


do $$
begin
raise notice '==== Clean road network ===';
end$$;

--
-- clean up a road network
-- remove cycles
DELETE FROM tempus.road_section as rs
WHERE node_from = node_to;

-- Correction of digitalization direction
WITH valid AS
(
	SELECT road_section.id, (st_distance(st_startpoint(road_section.geom), road_node.geom) < st_distance(st_endpoint(road_section.geom), road_node.geom)) as valid_direction
	FROM tempus.road_section join tempus.road_node 
	on (road_section.node_from = road_node.id)
	order by 2
)
UPDATE tempus.road_section
SET geom=st_reverse(geom)
FROM valid
WHERE valid.valid_direction=FALSE AND valid.id=road_section.id;

-- Delete turning restrictions not referencing existing road_sections
DELETE FROM tempus.road_restriction_time_penalty 
WHERE restriction_id IN
(
	SELECT distinct id
	FROM
	(
		SELECT q.id, q.road_section, q.rang, s.node_from, s.node_to
		FROM
		(SELECT road_restriction.id, unnest(road_restriction.sections) as road_section, tempus.array_search(unnest(road_restriction.sections), sections) as rang
		  FROM tempus.road_restriction) as q
		LEFT JOIN tempus.road_section as s
			ON s.id=q.road_section
	) t
	WHERE node_from IS NULL
);

DELETE FROM tempus.road_restriction 
WHERE id IN
(
	SELECT distinct id
	FROM
	(
		SELECT q.id, q.road_section, q.rang, s.node_from, s.node_to
		FROM
		(
		SELECT road_restriction.id, unnest(road_restriction.sections) as road_section, tempus.array_search(unnest(road_restriction.sections), sections) as rang
		  FROM tempus.road_restriction) as q
		LEFT JOIN tempus.road_section as s
			ON s.id=q.road_section
	) t
	WHERE node_from is null
);

-- Update road nodes bifurcation flag
UPDATE tempus.road_node
SET bifurcation = true
WHERE id IN
(
        SELECT
                rn.id AS id
        FROM
                tempus.road_node AS rn,
                tempus.road_section AS rs
        WHERE
                rs.node_from = rn.id
        OR
                rs.node_to = rn.id
        GROUP BY
	        rn.id
        HAVING count(*) > 2
);

-- Delete unconnected road sections
WITH r AS
(
    SELECT node_id, count(*)
    FROM
    (
        SELECT node_from as node_id
        FROM tempus.road_section
        UNION ALL
        SELECT node_to
        FROM tempus.road_section
    ) q
    GROUP BY node_id
) 
DELETE FROM tempus.road_section
WHERE node_from IN (SELECT node_id FROM r WHERE count=1) AND node_to IN (SELECT node_id FROM r WHERE count=1); 

-- Delete unconnected road nodes 
WITH r AS
(
    SELECT node_id
    FROM
    (
        SELECT node_from as node_id
        FROM tempus.road_section
        UNION
        SELECT node_to
        FROM tempus.road_section
    ) q
    GROUP BY node_id
) 
DELETE FROM tempus.road_node WHERE id not in (SELECT node_id FROM r); 


CREATE TRIGGER delete_isolated_road_nodes
  AFTER DELETE
  ON tempus.road_section
  FOR EACH ROW
  EXECUTE PROCEDURE tempus.delete_isolated_road_nodes_f();


do $$
begin
raise notice '==== Restore road constraints and geometry indexes ===';
end$$;

ALTER TABLE tempus.road_section_speed 
    ADD CONSTRAINT road_section_speed_road_section_id_fkey FOREIGN KEY (road_section_id) REFERENCES tempus.road_section(id) ON DELETE CASCADE ON UPDATE CASCADE; 
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
  
create index 
  on tempus.road_section 
  using gist(geom);
create index 
  on tempus.road_section(node_from);
create index 
  on tempus.road_section(node_to);
  
  
VACUUM FULL ANALYSE;
