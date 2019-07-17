

do $$
begin
raise notice '==== Cleaning data';
end
$$;

-- Delete stops, when not involved in a section
DELETE FROM tempus_gtfs.stops
WHERE id IN 
(
    SELECT p.id
    FROM tempus_gtfs.stops as p
    LEFT JOIN tempus_gtfs.transfers as s1 ON (p.id = s1.from_stop_id_int)
    LEFT JOIN tempus_gtfs.transfers as s2 ON (p.id = s2.to_stop_id_int)
    LEFT JOIN tempus_gtfs.stop_times ON (p.id = stop_times.stop_id_int)
    LEFT JOIN tempus_gtfs.stops as pp ON (p.stop_id = pp.parent_station_id AND p.feed_id = pp.feed_id)
    WHERE s1.from_stop_id_int is null
      AND s2.to_stop_id_int is null
      AND stop_times.stop_id is null
      AND pp.parent_station_id is null
); 

-- Delete useless artificial road sections (more efficient than keeping the triggers active)
DELETE FROM tempus.road_section 
WHERE network_id = 0 AND road_section.id IN 
(
	SELECT road_section.id
	FROM tempus.road_section
	LEFT JOIN tempus_gtfs.stops 
	ON road_section.id = stops.road_section_id
	LEFT JOIN tempus.poi
	ON road_section.id = poi.road_section_id
	WHERE stops.road_section_id IS NULL AND poi.road_section_id IS NULL
);

DELETE FROM tempus.road_node
WHERE id IN
(
    SELECT road_node.id
    FROM tempus.road_node
    LEFT JOIN tempus.road_section AS s1
    ON s1.node_from = road_node.id
    LEFT JOIN tempus.road_section AS s2
    ON s2.node_to = road_node.id
    WHERE s1.node_from is null AND s2.node_to is null
);




-- Insert nice sections following shapes data
/*UPDATE tempus_gtfs.sections
SET geom = t.geom
FROM
(
    SELECT
      DISTINCT ON (st1.stop_id, st2.stop_id)
      stops1.id as stop1
      , stops2.id as stop2
      , st1.trip_id
      , trips.shape_id
      , st_linesubstring(shapes.geom, 
      least(st_linelocatepoint(shapes.geom, stops1.geom), st_linelocatepoint(shapes.geom, stops2.geom)), 
      greatest(st_linelocatepoint(shapes.geom, stops1.geom), st_linelocatepoint(shapes.geom, stops2.geom))) as geom
    FROM
      tempus_gtfs.stop_times st1 JOIN tempus_gtfs.stop_times st2 ON (st1.trip_id = st2.trip_id) and (st1.feed_id = st2.feed_id) and (st2.stop_sequence = st1.stop_sequence + 1)
                                 JOIN tempus_gtfs.trips on (st1.trip_id = trips.trip_id) and (st1.feed_id = trips.feed_id)
                                 JOIN tempus_gtfs.shapes on (trips.shape_id = shapes.shape_id) and (trips.feed_id = shapes.feed_id)
                                 JOIN tempus_gtfs.stops stops1 on (st1.stop_id = stops1.stop_id) and (st1.feed_id = stops1.feed_id)
                                 JOIN tempus_gtfs.stops stops2 on (st2.stop_id = stops2.stop_id) and (st2.feed_id = stops2.feed_id)
) t
WHERE t.stop1 = sections.stop_from AND t.stop2 = sections.stop_to;  */


do $$
begin
raise notice '==== Restore road constraints and geometry indexes ===';
end$$;

ALTER TABLE tempus_gtfs.stops ADD CONSTRAINT stops_road_section_id_fkey FOREIGN KEY (road_section_id) REFERENCES tempus.road_section(id) ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE tempus_gtfs.stops ADD CONSTRAINT stops_zone_id_int_fkey FOREIGN KEY (zone_id_int) REFERENCES tempus_gtfs.zones (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE tempus_gtfs.routes ADD CONSTRAINT routes_agency_id_int_fkey FOREIGN KEY (agency_id_int) REFERENCES tempus_gtfs.agency (id) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
--ALTER TABLE tempus_gtfs.sections ADD  CONSTRAINT sections_shape_id_int_fkey FOREIGN KEY (shape_id_int) REFERENCES tempus_gtfs.shapes (id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tempus_gtfs.sections ADD CONSTRAINT sections_stop_from_fkey FOREIGN KEY (stop_from) REFERENCES tempus_gtfs.stops (id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tempus_gtfs.sections ADD CONSTRAINT sections_stop_to_fkey FOREIGN KEY (stop_to) REFERENCES tempus_gtfs.stops (id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE tempus_gtfs.trips ADD CONSTRAINT trips_route_id_int_fkey FOREIGN KEY (route_id_int) REFERENCES tempus_gtfs.routes (id) ON UPDATE CASCADE ON DELETE CASCADE;
--ALTER TABLE tempus_gtfs.trips ADD CONSTRAINT trips_service_id_int_fkey FOREIGN KEY (service_id_int) REFERENCES tempus_gtfs.calendar (id) ON UPDATE CASCADE ON DELETE CASCADE;
--ALTER TABLE tempus_gtfs.trips ADD CONSTRAINT trips_shape_id_int_fkey FOREIGN KEY (shape_id_int) REFERENCES tempus_gtfs.shapes (id) ON UPDATE CASCADE ON DELETE CASCADE;
   
CREATE INDEX road_node_geom_idx
  ON tempus.road_node 
  USING gist(geom);
  
CREATE INDEX 
  ON tempus.road_section 
  using gist(geom);
CREATE INDEX 
  ON tempus.road_section(node_from);
CREATE INDEX 
  ON tempus.road_section(node_to);
  
CREATE TRIGGER delete_isolated_road_nodes
  AFTER DELETE
  ON tempus.road_section
  FOR EACH ROW
  EXECUTE PROCEDURE tempus.delete_isolated_road_nodes_f();

CREATE TRIGGER delete_artificial_stop_road_section
  AFTER DELETE
  ON tempus_gtfs.stops
  FOR EACH ROW
  EXECUTE PROCEDURE tempus.delete_artificial_stop_road_section_f();
  
CREATE TRIGGER retrace_section
  AFTER UPDATE
  ON tempus_gtfs.stops
  FOR EACH ROW
  WHEN ((old.geom IS DISTINCT FROM new.geom))
  EXECUTE PROCEDURE tempus_gtfs.retrace_section_f();

CREATE INDEX ON tempus_gtfs.stops(id);
CREATE INDEX ON tempus_gtfs.stops(parent_station_id_int);
CREATE INDEX ON tempus_gtfs.stops USING gist(geom);

REFRESH MATERIALIZED VIEW tempus_gtfs.stops_by_mode;
REFRESH MATERIALIZED VIEW tempus_gtfs.sections_by_mode;
REFRESH MATERIALIZED VIEW tempus_gtfs.trips_by_mode;
REFRESH MATERIALIZED VIEW tempus_gtfs.shapes;

DROP SCHEMA %(temp_schema) CASCADE;

--vacuum full analyse; 
