
-- Deleting road sections with no traffic rules allowed
DELETE FROM tempus.road_section
WHERE traffic_rules_ft=0 AND traffic_rules_tf=0;

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
WHERE valid.valid_direction=FALSE AND valid.id = road_section.id;

-- Set "bifurcation" to NULL when the intersection has two adjacent edges with no attributes variation => can be fusionned
WITH sections AS
(
    SELECT rn.id as road_node_id, array_agg(rs.id) as road_sections_id
        FROM tempus.road_node as rn JOIN tempus.road_section as rs ON (rs.node_from = rn.id OR rs.node_to = rn.id)
        WHERE rn.bifurcation=False
        GROUP BY rn.id
)
UPDATE tempus.road_node
SET bifurcation = NULL
FROM sections, tempus.road_section as road_section1, tempus.road_section AS road_section2
WHERE array_length(sections.road_sections_id, 1)=1 OR
(
      array_length(sections.road_sections_id, 1)=2 AND 
      road_node.id=sections.road_node_id AND 
      road_section1.id = sections.road_sections_id[1] AND 
      road_section2.id = sections.road_sections_id[2] AND 
      road_section1.road_type = road_section2.road_type AND 
      road_section1.traffic_rules_ft = road_section2.traffic_rules_ft AND 
      road_section1.traffic_rules_tf = road_section2.traffic_rules_tf AND 
      road_section1.tollway = road_section2.tollway AND 
      road_section1.car_speed_limit = road_section2.car_speed_limit AND 
      road_section1.road_name = road_section2.road_name AND 
      road_section1.lane = road_section2.lane
);

