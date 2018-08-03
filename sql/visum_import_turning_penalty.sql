CREATE TEMPORARY TABLE temp AS
(
	SELECT row_number() over() as id, ARRAY[road_section1.id, road_section2.id] as sections, tempus_access.road_network_turning_mov.t0ti as time_penalty
	FROM tempus_access.road_network_turning_mov JOIN tempus.road_section as road_section1 ON (road_section1.node_from = road_network_turning_mov.numnoeudo AND road_section1.node_to = road_network_turning_mov.numvianoeud)
						 JOIN tempus.road_section as road_section2 ON (road_section2.node_from = road_network_turning_mov.numvianoeud AND road_section2.node_to = road_network_turning_mov.numnoeudd)
);

INSERT INTO tempus.road_restriction(id, sections)
SELECT id, sections
FROM temp;

INSERT INTO tempus.road_restriction_time_penalty(restriction_id, time_value, period_id, traffic_rules)
SELECT id, time_penalty, 0, 4
FROM temp;

DROP TABLE temp;

