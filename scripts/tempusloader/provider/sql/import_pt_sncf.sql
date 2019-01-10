/*
        Substitutions options
        %source_name: name of the PT network created (after data fusion)
*/

VACUUM FULL ANALYSE;

do $$
begin
raise notice '==== Data fusion between TER and IC sources ===';
end
$$;

do $$
begin
raise notice '==== Build new feed ===';
end
$$;

INSERT INTO tempus_gtfs.feed_info(feed_id)
SELECT '%(source_name)'; 

do $$
begin
raise notice '==== Build temporary stop times data ===';
end
$$;

-- Temporary table containing joined stop times, trips, routes and agencies data. 
-- When stop times exist in both sources (normally only for TER buses), stop times are attributed to TER agency. 
-- When a route exists in both sources, but with different trip ids and stop times, the route is duplicated. 
DROP TABLE IF EXISTS _tempus_import.stop_times; 
CREATE TABLE _tempus_import.stop_times AS
(
    SELECT max(stop_times.feed_id) as feed_id, 
           stop_times.trip_id, 
           stop_sequence, 
           stop_id, 
           substring(stop_id FROM length(stop_id) - 7 FOR 8) || '-' || route_type AS new_stop_id, 
           substring(stop_id FROM position(':' in stop_id)+1 FOR position('-' in stop_id) - position(':' in stop_id)-1) as trip_type, 
           arrival_time, 
           departure_time, 
           interpolated, 
           shape_dist_traveled, 
           timepoint, pickup_type, 
           drop_off_type, 
           stop_headsign, 
           route_type, 
           max(routes.route_id) as route_id, 
           max(agency.agency_id) as agency_id, 
           string_agg((trips.service_id || ' - ' || trips.feed_id)::character varying, ';') as service_id
    FROM tempus_gtfs.stop_times JOIN tempus_gtfs.trips ON (trips.id = stop_times.trip_id_int)
		                        JOIN tempus_gtfs.routes ON (routes.id = trips.route_id_int)
		                        JOIN tempus_gtfs.agency ON (agency.id = routes.agency_id_int )
    WHERE stop_times.feed_id = any(ARRAY['ter', 'ic'])
    GROUP BY stop_times.trip_id, 
           stop_sequence, 
           stop_id, 
           substring(stop_id FROM length(stop_id) - 7 FOR 8) || '-'  || route_type, 
           substring(stop_id FROM position(':' in stop_id)+1 FOR position('-' in stop_id) - position(':' in stop_id)-1), 
           arrival_time, 
           departure_time, 
           interpolated, 
           shape_dist_traveled, 
           timepoint, 
           pickup_type, 
           drop_off_type, 
           stop_headsign, 
           route_type
); 

CREATE INDEX feed_id_idx ON _tempus_import.stop_times (feed_id); 
CREATE INDEX route_id_idx ON _tempus_import.stop_times (route_id); 
CREATE INDEX trip_id_idx ON _tempus_import.stop_times (trip_id); 
CREATE INDEX stop_id_idx ON _tempus_import.stop_times (stop_id); 



do $$
begin
raise notice '==== Build agencies ===';
end
$$;

-- Agency
DELETE FROM tempus_gtfs.agency 
WHERE feed_id = '%(source_name)'; 
SELECT setval('tempus_gtfs.agency_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.agency), false);
INSERT INTO tempus_gtfs.agency(feed_id, agency_id, agency_name, agency_url, agency_timezone, agency_lang)
(
    SELECT DISTINCT ON (stop_times.agency_id || ' - ' || agency.feed_id) 
			'%(source_name)' as feed_id, 
			agency.agency_id || ' - ' || agency.feed_id as agency_id, 
			agency.agency_name || ' (' || agency.feed_id || ')' as agency_name, 
			agency_url, 
			agency_timezone, 
			agency_lang
    FROM _tempus_import.stop_times JOIN tempus_gtfs.agency ON (stop_times.feed_id = agency.feed_id AND stop_times.agency_id = agency.agency_id)
); 

do $$
begin
raise notice '==== Build routes ===';
end
$$;

-- Routes
DELETE FROM tempus_gtfs.routes 
WHERE feed_id = '%(source_name)';

SELECT setval('tempus_gtfs.routes_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.routes), false);
INSERT INTO tempus_gtfs.routes (feed_id, route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color, agency_id_int)
(
    SELECT DISTINCT ON (stop_times.feed_id, stop_times.route_id) 
			'%(source_name)', 
			routes.route_id || ' - ' || routes.feed_id, 
			routes.agency_id || ' - ' || routes.feed_id, 
			route_short_name, 
			route_long_name, 
			stop_times.trip_type as route_desc, 
			routes.route_type, 
			route_url, 
			route_text_color, 
			(SELECT id FROM tempus_gtfs.agency WHERE feed_id = '%(source_name)' AND agency.agency_id = routes.agency_id || ' - ' || routes.feed_id) as agency_id_int
    FROM _tempus_import.stop_times JOIN tempus_gtfs.routes ON (stop_times.feed_id = routes.feed_id AND stop_times.route_id = routes.route_id AND stop_times.agency_id = routes.agency_id)
    ORDER BY stop_times.route_id, stop_times.feed_id
);



do $$
begin
raise notice '==== Build calendars ===';
end
$$;

-- Calendar
DELETE FROM tempus_gtfs.calendar WHERE feed_id = '%(source_name)';
SELECT setval('tempus_gtfs.calendar_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.calendar), false);
INSERT INTO tempus_gtfs.calendar(feed_id, service_id)
(
    SELECT DISTINCT '%(source_name)', service_id
    FROM _tempus_import.stop_times
);


do $$
begin
raise notice '==== Build trips ===';
end
$$;

-- Trips
DELETE FROM tempus_gtfs.trips WHERE feed_id = '%(source_name)'; 

SELECT setval('tempus_gtfs.trips_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.trips), false);
INSERT INTO tempus_gtfs.trips (feed_id, trip_id, route_id, service_id, shape_id, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_headsign, trip_short_name, direction_id, block_id)
( 
    SELECT DISTINCT ON (stop_times.feed_id, stop_times.trip_id, trips.service_id) 
			'%(source_name)' as feed_id, 
			stop_times.trip_id, 
			trips.route_id || ' - ' || trips.feed_id as route_id, 
			stop_times.service_id, 
			shape_id, 
			wheelchair_accessible, 
			bikes_allowed, 
			exact_times, 
			frequency_generated, 
			trip_type, 
			trip_short_name, 
			direction_id, 
			block_id            
        FROM _tempus_import.stop_times JOIN tempus_gtfs.trips ON (stop_times.feed_id = trips.feed_id AND stop_times.trip_id = trips.trip_id) 
        WHERE stop_times.feed_id = any(ARRAY['ter', 'ic'])
    ORDER BY stop_times.feed_id, stop_times.trip_id, trips.service_id DESC  
);

UPDATE tempus_gtfs.trips
SET route_id_int = routes.id
FROM tempus_gtfs.routes
WHERE trips.feed_id = '%(source_name)' AND trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id;

UPDATE tempus_gtfs.trips
SET service_id_int = calendar.id
FROM tempus_gtfs.calendar
WHERE trips.feed_id = '%(source_name)' AND calendar.feed_id = trips.feed_id AND calendar.service_id = trips.service_id;

do $$
begin
raise notice '==== Build stops ===';
end
$$;

-- Stops
DELETE FROM tempus_gtfs.stops 
WHERE feed_id = '%(source_name)';
SELECT setval('tempus_gtfs.stops_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.stops), false);
INSERT INTO tempus_gtfs.stops (
				feed_id, 
				stop_id, 
				parent_station_id, 
				location_type, 
				stop_name, 
				stop_lat, 
				stop_lon, 
				wheelchair_boarding, 
				stop_code, 
				stop_desc, 
				zone_id, 
				stop_url, 
				stop_timezone, 
				geom, 
				road_section_id, 
				abscissa_road_section)
(       
        SELECT DISTINCT ON (CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) END, substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8))
                '%(source_name)', 
                CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id 
                     ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
                END AS stop_id, 
                substring(stops.parent_station_id FROM length(stops.parent_station_id) - 7 FOR 8) as parent_station_id, 
                stops.location_type, 
                stops.stop_name, 
                stops.stop_lat, 
                stops.stop_lon, 
                stops.wheelchair_boarding, 
                stops.stop_code, 
                stops.stop_desc, 
                stops.zone_id, 
                stops.stop_url, 
                stops.stop_timezone, 
                st_force3d(
				CASE WHEN (stops.parent_station_id IS NOT NULL) AND (stop_times.new_stop_id LIKE '%-%')
					THEN st_setsrid(st_makepoint(st_x(stops.geom)--+0.0001*stop_times.route_type
								   , st_y(stops.geom)), 4326) 
				     ELSE stops.geom
			        END
		          ) as geom, 
                road_section_id, 
                abscissa_road_section
        FROM _tempus_import.stop_times RIGHT JOIN tempus_gtfs.stops ON substring(stop_times.new_stop_id FROM 1 FOR 8) = substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
        WHERE stops.feed_id = any(ARRAY['ter', 'ic']) 
          AND (
              CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id 
                   ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
              END IS NOT NULL
              )
        ORDER BY CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id 
                      ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) 
                 END, 
                 substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
); 

UPDATE tempus_gtfs.stops
SET parent_station_id_int = stops2.id
FROM tempus_gtfs.stops stops2
WHERE stops.feed_id = stops2.feed_id AND stops2.stop_id = stops.parent_station_id; 

do $$
begin
raise notice '==== Build calendar dates ===';
end
$$;

-- Calendar dates
DELETE FROM tempus_gtfs.calendar_dates WHERE feed_id = '%(source_name)'; 
SELECT setval('tempus_gtfs.calendar_dates_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.calendar_dates), false);
INSERT INTO tempus_gtfs.calendar_dates(feed_id, service_id, date, service_id_int)
(
    SELECT DISTINCT '%(source_name)', stop_times.service_id, calendar_dates.date, 
           (SELECT id FROM tempus_gtfs.calendar WHERE feed_id = '%(source_name)' AND calendar.service_id = stop_times.service_id) 
    FROM _tempus_import.stop_times JOIN tempus_gtfs.calendar_dates ON (calendar_dates.service_id || ' - ' || calendar_dates.feed_id = split_part(stop_times.service_id, ';', 1)) 
    WHERE calendar_dates.feed_id = any(ARRAY['ter', 'ic'])
    UNION DISTINCT
    SELECT DISTINCT '%(source_name)', stop_times.service_id, calendar_dates.date, 
    (SELECT id FROM tempus_gtfs.calendar WHERE feed_id = '%(source_name)' AND calendar.service_id = stop_times.service_id) 
    FROM _tempus_import.stop_times JOIN tempus_gtfs.calendar_dates ON (calendar_dates.service_id || ' - ' || calendar_dates.feed_id = split_part(stop_times.service_id, ';', 2)) 
    WHERE calendar_dates.feed_id = any(ARRAY['ter', 'ic'])	
);

do $$
begin
raise notice '==== Build stop times ===';
end
$$;

-- Stop times
DELETE FROM tempus_gtfs.stop_times 
WHERE feed_id = '%(source_name)';
SELECT setval('tempus_gtfs.stop_times_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.stop_times), false);
INSERT INTO tempus_gtfs.stop_times(feed_id, trip_id, stop_sequence, stop_id, arrival_time, departure_time, interpolated, shape_dist_traveled, timepoint, pickup_type, drop_off_type, stop_headsign, trip_id_int, stop_id_int)
(
    SELECT '%(source_name)', trip_id, stop_sequence, new_stop_id, arrival_time, departure_time, interpolated, shape_dist_traveled, timepoint, pickup_type, drop_off_type, stop_headsign, 
    (SELECT id FROM tempus_gtfs.trips WHERE feed_id = '%(source_name)' AND trips.trip_id = stop_times.trip_id), 
    (SELECT id FROM tempus_gtfs.stops WHERE feed_id = '%(source_name)' AND stops.stop_id =  stop_times.new_stop_id)
    FROM _tempus_import.stop_times
    ORDER BY trip_id, stop_sequence
); 

do $$
begin
raise notice '==== Correct stops positions ===';
end
$$;

UPDATE tempus_gtfs.stops
SET geom = st_force3d(st_transform(ref_stops.geom, 4326)), 
    stop_name = ref_stops.stop_name
FROM _tempus_import.ref_stops ref_stops
WHERE stops.feed_id = '%(source_name)' AND ref_stops.feed_id = '%(source_name)' AND (substring(stops.stop_id FROM 1 FOR 8)=ref_stops.stop_id) ; 

REFRESH MATERIALIZED VIEW tempus_gtfs.stops_by_mode; 

UPDATE tempus_gtfs.stops
SET geom = st_force3d(st_transform(noeud_ferre.geom, 4326))
FROM _tempus_import.noeud_ferre, _tempus_import.appariement_ign_arrets_fer ign
WHERE ign.id_rte500 = noeud_ferre.id_rte500 AND ign.stop_id = stops.parent_station_id AND stops.id IN
(
    SELECT id FROM tempus_gtfs.stops_by_mode
    WHERE feed_id = '%(source_name)' AND route_type = 2
);

-- Set stop areas position at the gravity centre of its stops
UPDATE tempus_gtfs.stops
SET geom = st_force3d(st_translate(q.geom, 0.000005, 0.000005))
FROM 
(
SELECT stops.id, st_centroid(st_collect(stops2.geom)) as geom
FROM tempus_gtfs.stops JOIN tempus_gtfs.stops AS stops2 ON (stops2.feed_id = stops.feed_id AND stops2.parent_station_id = stops.stop_id)
WHERE stops.feed_id = '%(source_name)' AND stops.parent_station_id IS NULL
GROUP BY stops.id, stops.stop_name, stops.location_type
) q
WHERE q.id = stops.id;


UPDATE tempus_gtfs.stops
SET stop_lon = st_x(geom), stop_lat =st_y(geom); 



do $$
begin
raise notice '==== Insert artificial road sections ===';
end
$$;

-- Insert artificial road sections
-- 1. attach each stop to the closest road section in a 50 meters radius
--

-- create an index on road_section geography 
CREATE INDEX ON tempus.road_section using gist(geography(geom));

-- reset sequences on road nodes and sections
DROP SEQUENCE IF EXISTS tempus.seq_road_node_id;
CREATE SEQUENCE tempus.seq_road_node_id start with 1;
SELECT setval('tempus.seq_road_node_id', (SELECT max(id) from tempus.road_node));

DROP SEQUENCE IF EXISTS tempus.seq_road_section_id;
CREATE SEQUENCE tempus.seq_road_section_id start with 1;
SELECT setval('tempus.seq_road_section_id', (SELECT max(id) from tempus.road_section));

DO
$$
DECLARE
    l_road_section_id bigint;
    l_node1_id bigint;
    l_node2_id bigint;
    l_abscissa_road_section float8;
    l_artificial boolean;
    stop record;
BEGIN
    -- Use a loop here in order to make sure stops are compared to road sections
    -- while new road sections are created.
    FOR stop IN
        SELECT * FROM tempus_gtfs.stops WHERE feed_id = '%(source_name)'
    LOOP
        l_road_section_id := null;
        -- get the closest road section (if any)
        SELECT INTO l_road_section_id, l_abscissa_road_section, l_artificial
                    road_section_id, abscissa, false
        FROM
        (
            SELECT 
            rs.id AS road_section_id
            , st_linelocatepoint(rs.geom, stop.geom) AS abscissa
            , false
            , st_distance(rs.geom, stop.geom) dist
            FROM tempus.road_section rs
            WHERE st_dwithin(geography(stop.geom), geography(rs.geom), 50)
            -- attach to roads waklable by pedestrians
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
                , st_translate(stop.geom, -0.0001, 0, 0)
            UNION ALL
            SELECT
                l_node2_id
                , 0
                , false AS bifurcation
                , st_translate(stop.geom, +0.0001, 0, 0)
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
                    st_makeline(st_translate(stop.geom, -0.0001,0,0), st_translate(stop.geom, 0.0001,0,0)) AS geom
            );
        END IF;

        -- attach the stop to the road section
        UPDATE tempus_gtfs.stops
        SET road_section_id = l_road_section_id
          , abscissa_road_section = l_abscissa_road_section
        WHERE id = stop.id;
    END LOOP;    
END;
$$;

-- Stops position is set to an abscissa of 1 on each articial road section 
UPDATE tempus_gtfs.stops
SET abscissa_road_section = 1
FROM tempus.road_section
WHERE road_section.id = stops.road_section_id AND road_section.network_id = 0; 

do $$
begin
raise notice '==== Build straight lines sections ===';
end
$$;

-- Création des sections en ligne droite
DELETE FROM tempus_gtfs.sections WHERE feed_id IN (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)'); 
SELECT setval('tempus_gtfs.sections_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.sections), false);
INSERT INTO tempus_gtfs.sections (feed_id, stop_from, stop_to, geom)
(
    SELECT
      (select id from tempus_gtfs.feed_info WHERE feed_id = '%(source_name)')
      , st1.id
      , st2.id
      , st_makeline(st1.geom, st2.geom)
    FROM
    (
        SELECT DISTINCT ON (st1.new_stop_id, st2.new_stop_id)
          st1.new_stop_id as stop1, 
          st2.new_stop_id as stop2
        FROM _tempus_import.stop_times st1 JOIN _tempus_import.stop_times st2 ON ((st1.trip_id = st2.trip_id) and (st1.feed_id = st2.feed_id) and (st2.stop_sequence = st1.stop_sequence + 1))
    ) t
    JOIN tempus_gtfs.stops st1 on st1.stop_id = t.stop1 AND st1.feed_id = '%(source_name)'
    JOIN tempus_gtfs.stops st2 on st2.stop_id = t.stop2 AND st2.feed_id = '%(source_name)'
); 

do $$
begin
raise notice '==== Add new transport modes ===';
end
$$;

-- Shapes will be built after retracing train sections
SELECT setval('tempus.transport_mode_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus.transport_mode), false);
INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, gtfs_feed_id)
SELECT 'Tram (%(source_name))', True, 0, (select id from tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') as gtfs_feed_id
union
select 'Train (%(source_name))', True, 2, (select id from tempus_gtfs.feed_info WHERE feed_id = '%(source_name)')
union 
select 'Bus (%(source_name))', True, 3, (select id from tempus_gtfs.feed_info WHERE feed_id = '%(source_name)')
union
select 'Funicular (%(source_name))', True, 7, (select id from tempus_gtfs.feed_info WHERE feed_id = '%(source_name)'); 

do $$
begin
raise notice '==== Delete temporary data ===';
end
$$;

-- Delete temporary %(source_name) data
DROP TABLE _tempus_import.stop_times;

-- Delete temporary TER and IC data
DELETE FROM tempus_gtfs.feed_info
WHERE feed_id = 'ter' or feed_id = 'ic';

DELETE FROM tempus.road_network
WHERE name in ('transfers_ter', 'transfers_ic');

DROP INDEX tempus.road_section_geography_idx;

-- Delete artificial road sections which are no longer used
DELETE FROM tempus.road_section
  WHERE network_id = 0 AND id not in (select distinct road_section_id from tempus_gtfs.stops);


do $$
begin
raise notice '==== Correct train lines shapes ===';
end
$$;

DROP TABLE IF EXISTS _tempus_import.troncon_voie_ferree_simplif;
CREATE table _tempus_import.troncon_voie_ferree_simplif AS
(
    SELECT id_rte500::integer, nature, energie, classement, st_transform(st_force2D(geom), 2154) as geom, null::integer as source, null::integer as target
    FROM _tempus_import.troncon_voie_ferree
);
CREATE INDEX troncon_voie_ferree_simplif_geom_idx
ON _tempus_import.troncon_voie_ferree_simplif
USING gist(geom);


DROP TABLE IF EXISTS _tempus_import.troncon_voie_ferree_simplif_vertices_pgr;
SELECT pgr_createTopology('_tempus_import.troncon_voie_ferree_simplif', 10, 'geom', 'id_rte500');
CREATE INDEX troncon_voie_ferree_simplif_vertices_pgr_geom_idx
ON _tempus_import.troncon_voie_ferree_simplif_vertices_pgr
USING gist(the_geom);


ALTER TABLE _tempus_import.appariement_ign_arrets_fer
ADD COLUMN IF NOT EXISTS id_pgr integer; 

UPDATE _tempus_import.appariement_ign_arrets_fer
SET id_pgr = null; 

UPDATE _tempus_import.appariement_ign_arrets_fer
SET id_pgr = noeuds_pgr.id 
FROM _tempus_import.troncon_voie_ferree_simplif_vertices_pgr noeuds_pgr JOIN _tempus_import.noeud_ferre ON (st_distance(st_transform(noeud_ferre.geom, 2154), noeuds_pgr.the_geom)=0)
WHERE noeud_ferre.id_rte500 = appariement_ign_arrets_fer.id_rte500 ;

REFRESH MATERIALIZED VIEW tempus_gtfs.sections_by_mode;

WITH q AS
(
	WITH t AS
	(
        SELECT sections_by_mode.section_id, sections_by_mode.geom, t_from.id_pgr as id_pgr_from, t_to.id_pgr as id_pgr_to
        FROM tempus_gtfs.sections_by_mode JOIN tempus_gtfs.stops stop_from ON (stop_from.id = sections_by_mode.stop_from)
                                            JOIN _tempus_import.appariement_ign_arrets_fer t_from ON (stop_from.parent_station_id = t_from.stop_id)
                                            JOIN tempus_gtfs.stops stop_to ON (stop_to.id = sections_by_mode.stop_to)
                                            JOIN _tempus_import.appariement_ign_arrets_fer t_to ON (stop_to.parent_station_id= t_to.stop_id) 
        WHERE sections_by_mode.feed_id = '%(source_name)' AND sections_by_mode.route_type = 2
	)
	SELECT t.section_id, st_force3d(st_geometryn(st_multi(st_linemerge(st_union(section.geom))), 1))::Geometry('LinestringZ', 2154) as geom
	FROM t, _tempus_import.troncon_voie_ferree_simplif section, pgr_dijkstra('select id_rte500 as id, source, target, st_length(geom) as cost from _tempus_import.troncon_voie_ferree_simplif'::text, t.id_pgr_from::bigint, t.id_pgr_to::bigint, false) dijkstra
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
WHERE feed_id = '%(source_name)'; 

DELETE FROM tempus_gtfs.shapes
WHERE feed_id = '%(source_name)';

DROP SEQUENCE IF EXISTS seq_shape_id;
CREATE SEQUENCE seq_shape_id start WITH 1;
SELECT setval('seq_shape_id', (SELECT max(id)+1 FROM tempus_gtfs.shapes));

DROP TABLE IF EXISTS _tempus_import.tmp_shapes_desc; 
CREATE TABLE _tempus_import.tmp_shapes_desc AS
(
    SELECT nextval('seq_shape_id') as id, stops, array_agg(trip_id) as trips, route_type
    FROM 
    (
	SELECT stop_times.trip_id, array_agg(stops.id order by stop_sequence) as stops, routes.route_type
	FROM tempus_gtfs.stop_times JOIN tempus_gtfs.stops ON (stops.stop_id = stop_times.stop_id AND stops.feed_id = stop_times.feed_id)
				    JOIN tempus_gtfs.trips ON ((stop_times.feed_id = trips.feed_id) AND (trips.trip_id = stop_times.trip_id))
				    JOIN tempus_gtfs.routes ON ((trips.feed_id = routes.feed_id) AND (routes.route_id = trips.route_id))
				    WHERE stop_times.feed_id = '%(source_name)'
	GROUP BY stop_times.trip_id, routes.route_type
    ) q 
    GROUP BY stops, route_type
);  

DROP TABLE IF EXISTS _tempus_import.tmp_shapes_geom;
CREATE TABLE _tempus_import.tmp_shapes_geom AS 
( 
    WITH shapes_stops AS
    (
	    SELECT id, id::character varying as shape_id, unnest(stops) as stop_id_int, generate_subscripts(stops, 1) AS stop_sequence, route_type
	    FROM _tempus_import.tmp_shapes_desc
	    ORDER BY shape_id, stop_sequence
    )
    SELECT s1.id, s1.shape_id, st_force2d(st_multi(st_linemerge(st_union(array_agg(sections.geom)))))::Geometry('Multilinestring', 4326) as geom
    FROM tempus_gtfs.sections, shapes_stops s1, shapes_stops s2
    WHERE s1.shape_id = s2.shape_id AND s1.stop_sequence = s2.stop_sequence-1 
      AND sections.feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') AND s1.stop_id_int = sections.stop_from AND s2.stop_id_int = sections.stop_to
    GROUP BY s1.id, s1.shape_id
); 

 
INSERT INTO tempus_gtfs.shapes(feed_id, shape_id, geom, id)
SELECT '%(source_name)'::character varying as feed_id, shape_id, st_force3d(st_geometryn(st_linemerge(geom), 1)) as geom, id
FROM _tempus_import.tmp_shapes_geom;

UPDATE tempus_gtfs.trips
SET shape_id = tmp_shapes_desc.id::character varying, shape_id_int = tmp_shapes_desc.id
FROM _tempus_import.tmp_shapes_desc
WHERE trips.feed_id = '%(source_name)' AND trips.trip_id = ANY(tmp_shapes_desc.trips);

DROP TABLE _tempus_import.tmp_shapes_geom; 
DROP TABLE _tempus_import.tmp_shapes_desc; 


do $$
begin
raise notice '==== Build transfers ===';
end
$$;

-- New transfers are created between stops belonging to the same parent_station_id, but which are not linked by a transfer edge
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
(
    -- From stop to stop : 10 minutes
    SELECT stops1.feed_id, stops1.stop_id, stops2.stop_id, 2, 10*60, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id)
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = '%(source_name)' AND stops1.parent_station_id = stops2.parent_station_id AND stops1.stop_id != stops2.stop_id
)
UNION
(
    SELECT stops1.feed_id, stops1.stop_id, stops2.stop_id, 2, 0, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id)
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = '%(source_name)' AND stops1.parent_station_id = stops2.stop_id
)
UNION
(
    SELECT stops1.feed_id, stops1.stop_id, stops2.stop_id, 2, 10*60, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id)
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = '%(source_name)' AND stops1.stop_id = stops2.parent_station_id
)
ORDER BY 2,3; 

-- New transfers are created between all stop areas less distant than 900 m (15 min walking time at 3.6 km/h)
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
SELECT '%(source_name)', s1.stop_id, s2.stop_id, 2 as transfer_type, st_distance(geography(s1.geom), geography(s2.geom))/60 as min_transfer_time, s1.id, s2.id
  FROM tempus_gtfs.stops s1 CROSS JOIN tempus_gtfs.stops s2
  WHERE s1.parent_station_id IS NULL AND s2.parent_station_id IS NULL AND s1.stop_id != s2.stop_id AND (st_distance(geography(s1.geom), geography(s2.geom))/60 < 15);

-- New transfers are created for big cities, considering the urban public transport network
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
(
    SELECT '%(source_name)', from_stop, to_stop, 2, min_time, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = from_stop::character varying), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = to_stop::character varying)
    FROM _tempus_import.urban_pt_transfers LEFT JOIN tempus_gtfs.transfers ON (transfers.feed_id = '%(source_name)' AND transfers.from_stop_id = urban_pt_transfers.from_stop::character varying AND transfers.to_stop_id =urban_pt_transfers.to_stop::character varying)
    WHERE transfers.from_stop_id IS NULL
);

UPDATE tempus_gtfs.transfers
SET min_transfer_time = urban_pt_transfers.min_time
FROM _tempus_import.urban_pt_transfers
WHERE transfers.feed_id = '%(source_name)' 
  AND urban_pt_transfers.from_stop::character varying = transfers.from_stop_id 
  AND urban_pt_transfers.to_stop::character varying = transfers.to_stop_id 
  AND urban_pt_transfers.min_time < transfers.min_transfer_time;
 
-- Transfers are converted to road sections
DROP TABLE IF EXISTS _tempus_import.transfers_without_doubles;
CREATE TABLE _tempus_import.transfers_without_doubles AS
(
    WITH foo AS
    (
        SELECT t1.feed_id, t1.from_stop_id, t1.to_stop_id, t1.min_transfer_time as min_transfer_time_direct, t2.min_transfer_time as min_transfer_time_reverse
          FROM tempus_gtfs.transfers t1
          LEFT JOIN tempus_gtfs.transfers t2 ON ( t1.from_stop_id = t2.to_stop_id AND t2.from_stop_id = t1.to_stop_id AND t1.feed_id = t2.feed_id )
        WHERE t1.id < t2.id AND t1.feed_id = '%(source_name)'
    )
    SELECT feed_id, from_stop_id, to_stop_id, min_transfer_time_direct as min_transfer_time, true as both_dir
    FROM foo
    WHERE min_transfer_time_direct = min_transfer_time_reverse
    UNION
    SELECT feed_id, from_stop_id, to_stop_id, min_transfer_time_direct, false
    FROM foo
    WHERE min_transfer_time_direct is not null AND (min_transfer_time_direct != min_transfer_time_reverse OR min_transfer_time_reverse is null)
    UNION
    SELECT feed_id, to_stop_id, from_stop_id, min_transfer_time_reverse, false
    FROM foo
    WHERE min_transfer_time_reverse is not null AND (min_transfer_time_direct != min_transfer_time_reverse OR min_transfer_time_direct is null)
);  

INSERT INTO tempus.road_network(name, comment)
VALUES ('transfers_feed_id','Transfers between PT stops in the feed_id network');

DROP SEQUENCE IF EXISTS seq_transfer_node_id;
CREATE SEQUENCE seq_transfer_node_id start WITH 1;
SELECT setval('seq_transfer_node_id', (SELECT max(id)+1 FROM tempus.road_node));

DROP SEQUENCE IF EXISTS seq_transfer_section_id;
CREATE SEQUENCE seq_transfer_section_id start WITH 1;
SELECT setval('seq_transfer_section_id', (SELECT max(id)+1 FROM tempus.road_section));

-- mark each (distinct) stop involved in a transfer
DROP TABLE IF EXISTS _tempus_import.road_transfers;
CREATE TABLE _tempus_import.road_transfers AS
(
    WITH transfer_stops AS
	(
		SELECT DISTINCT stops.id AS stop_id
		FROM tempus_gtfs.stops JOIN tempus_gtfs.transfers ON (stops.feed_id = transfers.feed_id AND (stops.stop_id = transfers.from_stop_id OR stops.stop_id = transfers.to_stop_id))
		WHERE transfer_type::integer = 2 AND transfers.feed_id = '%(source_name)'
	)
    SELECT stops.id, 
           stops.road_section_id, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN nextval('seq_transfer_section_id')::bigint
           END AS first_split_id, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN rs.length * stops.abscissa_road_section
           END AS first_split_length, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN st_makeline(n1.geom, st_lineinterpolatepoint(rs.geom, stops.abscissa_road_section))
           END AS first_split_geom, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN nextval('seq_transfer_section_id')::bigint
           END AS second_split_id,
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN rs.length * stops.abscissa_road_section
           END AS second_split_length, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN st_makeline(st_lineinterpolatepoint(rs.geom, stops.abscissa_road_section), n2.geom)
           END AS second_split_geom,
           nextval('seq_transfer_section_id')::bigint AS link_section_id,
           600 AS link_section_length, 
           CASE WHEN stops.abscissa_road_section = 0 THEN st_makeline(n1.geom, stops.geom)
                WHEN stops.abscissa_road_section = 1 THEN st_makeline(n2.geom, stops.geom)
                ELSE st_makeline(st_lineinterpolatepoint(rs.geom, stops.abscissa_road_section), stops.geom)
           END AS link_section_geom,
           rs.node_from as node_from_id, 
           n1.geom as node_from_geom,
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN nextval('seq_transfer_node_id')::bigint
           END AS intermed_node_id, 
           CASE WHEN stops.abscissa_road_section NOT IN (0, 1) THEN st_lineinterpolatepoint(rs.geom, stops.abscissa_road_section)
           END AS intermed_node_geom, 
           rs.node_to as node_to_id, 
           n2.geom as node_to_geom, 
           nextval('seq_transfer_node_id')::bigint AS stop_node_id, 
           stops.geom as stop_node_geom,   
           stops.abscissa_road_section
	FROM transfer_stops JOIN tempus_gtfs.stops ON (stops.id = transfer_stops.stop_id)
                        JOIN tempus.road_section rs ON (rs.id = stops.road_section_id)
                        JOIN tempus.road_node n1 ON n1.id = rs.node_from
                        JOIN tempus.road_node n2 ON n2.id = rs.node_to
); 

-- Insert new road nodes
INSERT INTO tempus.road_node(id, network_id, bifurcation, geom)
(
SELECT DISTINCT intermed_node_id as id
     , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_feed_id')
     , false AS bifurcation
     , intermed_node_geom
FROM _tempus_import.road_transfers
WHERE intermed_node_id IS NOT NULL
UNION
SELECT DISTINCT stop_node_id as id
     , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_feed_id')
     , false AS bifurcation
     , stop_node_geom
FROM _tempus_import.road_transfers
ORDER BY id
); 

-- Insert new road sections
INSERT INTO tempus.road_section(id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, geom)
(
SELECT
   first_split_id AS id, 
   (SELECT network_id FROM tempus.road_section WHERE id = road_section_id),
   (SELECT road_type FROM tempus.road_section WHERE id = road_section_id),
   node_from_id,
   intermed_node_id,
   1 as traffic_rules_ft,
   1 as traffic_rules_tf,
   first_split_length, 
   (SELECT road_name FROM tempus.road_section WHERE id = road_section_id), 
   first_split_geom
FROM _tempus_import.road_transfers
WHERE first_split_id IS NOT NULL
UNION
SELECT
   second_split_id AS id, 
   (SELECT network_id FROM tempus.road_section WHERE id = road_section_id),
   (SELECT road_type FROM tempus.road_section WHERE id = road_section_id),
   intermed_node_id,
   node_to_id, 
   1 as traffic_rules_ft,
   1 as traffic_rules_tf,
   first_split_length, 
   (SELECT road_name FROM tempus.road_section WHERE id = road_section_id), 
   second_split_geom
FROM _tempus_import.road_transfers
WHERE first_split_id IS NOT NULL
UNION
SELECT
   link_section_id AS id, 
   (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_feed_id'),
   5 as road_type,
   CASE WHEN abscissa_road_section = 0 THEN node_from_id
        WHEN abscissa_road_section = 1 THEN node_to_id
        ELSE intermed_node_id
   END,
   stop_node_id,
   1 as traffic_rules_ft,
   1 as traffic_rules_tf,
   link_section_length, 
   'Transfer', 
   link_section_geom
FROM _tempus_import.road_transfers
WHERE link_section_id IS NOT NULL
ORDER BY id
);

UPDATE tempus_gtfs.stops
SET road_section_id = link_section_id, abscissa_road_section = 1
FROM _tempus_import.road_transfers
WHERE stops.id = road_transfers.id; 

-- Insert the transfer sections
INSERT INTO tempus.road_section(id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, geom)
SELECT
  nextval('seq_transfer_section_id')::bigint
  , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_feed_id')
  , 5 AS road_type -- road_type dedicated to transfer between PT stops
  , nn1.stop_node_id
  , nn2.stop_node_id
  , 1 as traffic_rules_ft
  , CASE WHEN tr.both_dir = TRUE THEN 1 ELSE 0 END as traffic_rules_tf
  , min_transfer_time::float * 5000 / 3600.0 AS length -- convert FROM time to distance (multiply by walking speed)
  , 'Transfer'
  , st_makeline(s1.geom, s2.geom)
FROM
  _tempus_import.transfers_without_doubles tr
  JOIN tempus_gtfs.stops s1 ON (s1.feed_id = tr.feed_id AND s1.stop_id = tr.from_stop_id)
  JOIN tempus_gtfs.stops s2 ON (s2.feed_id = tr.feed_id AND s2.stop_id = tr.to_stop_id)
  JOIN _tempus_import.road_transfers nn1 ON nn1.id = s1.id
  JOIN _tempus_import.road_transfers nn2 ON nn2.id = s2.id;  


-- Speed is defined for pedestrians on road sections
INSERT INTO tempus.road_daily_profile(
            profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES((SELECT CASE WHEN max(profile_id) IS NULL THEN 1 ELSE max(profile_id)+1 END FROM tempus.road_daily_profile),0,1,1440,3.6);
  
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, (SELECT max(profile_id) FROM tempus.road_daily_profile)
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 1) > 0 OR (road_section.traffic_rules_tf::integer & 1) > 0; 

