DROP TABLE IF EXISTS tempus_access.ign_rte500_troncon_voie_ferree_simplif;
CREATE table tempus_access.ign_rte500_troncon_voie_ferree_simplif AS
(
    SELECT id_rte500::integer, nature, energie, classement, st_transform(st_force2D(geom), 2154) as geom, null::integer as source, null::integer as target
    FROM tempus_access.ign_rte500_troncon_voie_ferree
);
CREATE INDEX ign_rte500_troncon_voie_ferree_simplif_geom_idx
ON tempus_access.ign_rte500_troncon_voie_ferree_simplif
USING gist(geom);


DROP TABLE IF EXISTS tempus_access.ign_rte500_troncon_voie_ferree_simplif_vertices_pgr;
SELECT pgr_createTopology('tempus_access.ign_rte500_troncon_voie_ferree_simplif', 10, 'geom', 'id_rte500');
CREATE INDEX ign_rte500_troncon_voie_ferree_simplif_vertices_pgr_geom_idx
ON tempus_access.ign_rte500_troncon_voie_ferree_simplif_vertices_pgr
USING gist(the_geom);


ALTER TABLE tempus_access.appariement_ign_arrets_fer
ADD COLUMN IF NOT EXISTS id_pgr integer; 

UPDATE tempus_access.appariement_ign_arrets_fer
SET id_pgr = null; 

UPDATE tempus_access.appariement_ign_arrets_fer
SET id_pgr = noeuds_pgr.id 
FROM tempus_access.ign_rte500_troncon_voie_ferree_simplif_vertices_pgr noeuds_pgr JOIN tempus_access.ign_rte500_noeud_ferre ON (st_distance(st_transform(ign_rte500_noeud_ferre.geom, 2154), noeuds_pgr.the_geom)=0)
WHERE ign_rte500_noeud_ferre.id_rte500 = appariement_ign_arrets_fer.id_rte500 ;

WITH q AS
(
	WITH t AS
	(
        SELECT sections_by_mode.section_id, sections_by_mode.geom, t_from.id_pgr as id_pgr_from, t_to.id_pgr as id_pgr_to
        FROM tempus_access.sections_by_mode JOIN tempus_gtfs.stops stop_from ON (stop_from.id = sections_by_mode.stop_from)
                                            JOIN tempus_access.appariement_ign_arrets_fer t_from ON (stop_from.parent_station_id = t_from.stop_id)
                                            JOIN tempus_gtfs.stops stop_to ON (stop_to.id = sections_by_mode.stop_to)
                                            JOIN tempus_access.appariement_ign_arrets_fer t_to ON (stop_to.parent_station_id= t_to.stop_id) 
        WHERE sections_by_mode.feed_id = 'sncf' AND sections_by_mode.route_type = 2
	)
	SELECT t.section_id, st_force3d(st_geometryn(st_multi(st_linemerge(st_union(section.geom))), 1))::Geometry('LinestringZ', 2154) as geom
	FROM t, tempus_access.ign_rte500_troncon_voie_ferree_simplif section, pgr_dijkstra('select id_rte500 as id, source, target, st_length(geom) as cost from tempus_access.ign_rte500_troncon_voie_ferree_simplif'::text, t.id_pgr_from::bigint, t.id_pgr_to::bigint, false) dijkstra
	WHERE t.id_pgr_from <> t.id_pgr_to AND dijkstra.edge<>-1 AND section.id_rte500=dijkstra.edge
	GROUP BY t.section_id
)
UPDATE tempus_gtfs.sections
SET geom = st_transform(q.geom, 4326)
FROM q
WHERE q.section_id = sections.id; 

-- Création d''une table géographique correspondant à la table "shapes"

UPDATE tempus_gtfs.trips
SET shape_id = null
WHERE feed_id = 'sncf'; 

DROP TABLE IF EXISTS tempus_access.tmp_shapes_desc; 
CREATE TABLE tempus_access.tmp_shapes_desc AS
(
    SELECT row_number() over() as shape_id, stops, array_agg(trip_id) as trips, route_type
    FROM 
    (
	SELECT stop_times.trip_id, array_agg(stops.id order by stop_sequence) as stops, routes.route_type
	FROM tempus_gtfs.stop_times JOIN tempus_gtfs.stops ON (stops.stop_id = stop_times.stop_id AND stops.feed_id = stop_times.feed_id)
				    JOIN tempus_gtfs.trips ON ((stop_times.feed_id = trips.feed_id) AND (trips.trip_id = stop_times.trip_id))
				    JOIN tempus_gtfs.routes ON ((trips.feed_id = routes.feed_id) AND (routes.route_id = trips.route_id))
				    WHERE stop_times.feed_id = 'sncf'
	GROUP BY stop_times.trip_id, routes.route_type
    ) q 
    GROUP BY stops, route_type
);  

DROP TABLE IF EXISTS tempus_access.tmp_shapes_geom;
CREATE TABLE tempus_access.tmp_shapes_geom AS 
( 
    WITH shapes_stops AS
    (
	    SELECT shape_id, unnest(stops) as id, generate_subscripts(stops, 1) AS stop_sequence, route_type
	    FROM tempus_access.tmp_shapes_desc
	    ORDER BY shape_id, stop_sequence
    )
    SELECT s1.shape_id, st_force2d(st_multi(st_linemerge(st_union(array_agg(sections.geom)))))::Geometry('Multilinestring', 4326) as geom
    FROM tempus_gtfs.sections, shapes_stops s1, shapes_stops s2
    WHERE s1.shape_id = s2.shape_id AND s1.stop_sequence = s2.stop_sequence-1 
      AND sections.feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = 'sncf') AND s1.id = sections.stop_from AND s2.id = sections.stop_to
    GROUP BY s1.shape_id
); 

DELETE FROM tempus_gtfs.shapes
WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.shapes(feed_id, shape_id, geom_multi)
SELECT 'sncf'::character varying as feed_id, shape_id, st_multi(st_linemerge(geom)) as geom
FROM tempus_access.tmp_shapes_geom;

UPDATE tempus_gtfs.trips
SET shape_id = tmp_shapes_desc.shape_id
FROM tempus_access.tmp_shapes_desc
WHERE trips.trip_id = ANY(tmp_shapes_desc.trips) AND trips.feed_id = 'sncf';

DROP TABLE tempus_access.tmp_shapes_geom; 
DROP TABLE tempus_access.tmp_shapes_desc; 

DROP TRIGGER IF EXISTS retrace_section ON tempus_gtfs.stops;

UPDATE tempus_gtfs.stops
SET geom = st_transform(ign_rte500_noeud_ferre.geom, 4326)
FROM tempus_access.ign_rte500_noeud_ferre, tempus_access.appariement_ign_arrets_fer
WHERE appariement_ign_arrets_fer.feed_id = stops.feed_id AND appariement_ign_arrets_fer.stop_id || '-2' = stops.stop_id AND ign_rte500_noeud_ferre.id_rte500 = appariement_ign_arrets_fer.id_rte500; 

CREATE TRIGGER retrace_section
  AFTER UPDATE
  ON tempus_gtfs.stops
  FOR EACH ROW
  WHEN ((old.geom IS DISTINCT FROM new.geom))
  EXECUTE PROCEDURE tempus_gtfs.retrace_section_f();

REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode;
REFRESH MATERIALIZED VIEW tempus_access.sections_by_mode;
REFRESH MATERIALIZED VIEW tempus_access.trips_by_mode;
