/*UPDATE tempus_gtfs.stops
SET road_section_id = q.road_section_id, abscissa_road_section = 0.5
FROM
(
	SELECT DISTINCT ON (feed_id, stop_id) feed_id, stop_id, road_section_id
	FROM tempus_gtfs.stops
	WHERE parent_station_id is null
	ORDER BY feed_id, stop_id
) q
WHERE q.feed_id = stops.feed_id AND (q.stop_id = stops.parent_station_id OR q.stop_id = stops.stop_id); */

DELETE FROM tempus.road_section
WHERE id NOT IN (SELECT road_section_id FROM tempus_gtfs.stops); 

delete from tempus.road_node
where id not in
(
select distinct road_node.id
from tempus.road_node join tempus.road_section on (road_section.node_from = road_node.id)
union 
select distinct road_node.id
from tempus.road_node join tempus.road_section on (road_section.node_to = road_node.id)
);

