/*
        Substitutions options
        %(source_name): name of the PT network
*/

VACUUM FULL ANALYSE;

do $$
begin
raise notice '==== Init ===';
end$$;

-- stops_id_map
DROP TABLE IF EXISTS _tempus_import.stops_idmap;
CREATE TABLE _tempus_import.stops_idmap
(
        id serial primary key,
        stop_id varchar
);

SELECT setval('_tempus_import.stops_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.stops), false);
INSERT INTO _tempus_import.stops_idmap (stop_id)
       SELECT stop_id FROM _tempus_import.stops;
CREATE INDEX stops_idmap_stop_id_idx ON _tempus_import.stops_idmap(stop_id);

-- routes_id_map
DROP TABLE IF EXISTS _tempus_import.routes_idmap;
CREATE TABLE _tempus_import.routes_idmap
(
        id serial primary key,
        route_id varchar
);
SELECT setval('_tempus_import.routes_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.routes), false);
INSERT INTO _tempus_import.routes_idmap (route_id)
       SELECT route_id FROM _tempus_import.routes;
CREATE INDEX routes_idmap_route_id_idx ON _tempus_import.routes_idmap(route_id);

-- agency_id_map
DROP TABLE IF EXISTS _tempus_import.agency_idmap;
CREATE TABLE _tempus_import.agency_idmap
(
	id serial primary key,
	agency_id varchar
);
SELECT setval('_tempus_import.agency_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.agency), false);
INSERT INTO _tempus_import.agency_idmap(agency_id)
	SELECT agency_id FROM _tempus_import.agency;
	CREATE INDEX agency_idmap_agency_id_idx ON _tempus_import.agency_idmap(agency_id);

-- trips_id_map
DROP TABLE IF EXISTS _tempus_import.trips_idmap;
CREATE TABLE _tempus_import.trips_idmap
(
        id serial primary key,
        trip_id varchar
);
SELECT setval('_tempus_import.trips_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.trips), false);
INSERT INTO _tempus_import.trips_idmap (trip_id)
       SELECT trip_id FROM _tempus_import.trips;
CREATE INDEX trips_idmap_vendor_idx ON _tempus_import.trips_idmap(trip_id);

-- service_id_map
DROP TABLE IF EXISTS _tempus_import.service_idmap;
CREATE TABLE _tempus_import.service_idmap
(
	id serial primary key,
	service_id varchar
);
SELECT setval('_tempus_import.service_idmap_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.calendar), false);
INSERT INTO _tempus_import.service_idmap( service_id )
	SELECT service_id FROM _tempus_import.calendar union SELECT service_id FROM _tempus_import.calendar_dates;
CREATE INDEX service_idmap_vendor_idx ON _tempus_import.service_idmap(service_id);

-- pt_fare_id_map
DROP TABLE IF EXISTS _tempus_import.fare_idmap;
CREATE TABLE _tempus_import.fare_idmap
(
        id serial primary key,
        fare_id varchar
);
SELECT setval('_tempus_import.fare_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.fare_attributes));
INSERT INTO _tempus_import.fare_idmap (fare_id)
       SELECT fare_id FROM _tempus_import.fare_attributes;
CREATE INDEX fare_idmap_fare_idx ON _tempus_import.fare_idmap(fare_id);

-- shapes_id_map
DROP TABLE IF EXISTS _tempus_import.shapes_idmap;
CREATE TABLE _tempus_import.shapes_idmap
(
        id serial primary key,
        shape_id varchar
);
SELECT setval('_tempus_import.shapes_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.shapes));
INSERT INTO _tempus_import.shapes_idmap (shape_id)
       SELECT DISTINCT shape_id FROM _tempus_import.shapes;
CREATE INDEX shapes_idmap_shape_idx ON _tempus_import.shapes_idmap(shape_id);

-- zones_id_map
DROP TABLE IF EXISTS _tempus_import.zones_idmap;
CREATE TABLE _tempus_import.zones_idmap
(
        id serial primary key,
        zone_id varchar
);
SELECT setval('_tempus_import.zones_idmap_id_seq', (SELECT case when max(id) is null then 1 else max(id)+1 end FROM tempus_gtfs.zones));
INSERT INTO _tempus_import.zones_idmap (zone_id)
       SELECT DISTINCT zone_id FROM _tempus_import.stops;
CREATE INDEX zones_idmap_shape_idx ON _tempus_import.zones_idmap(zone_id);


do $$
begin
raise notice '==== PT network and agencies ====';
end$$;

INSERT INTO tempus_gtfs.feed_info(
            feed_id,feed_publisher_name,feed_publisher_url,feed_contact_email,feed_contact_url,
            feed_lang,feed_start_date,feed_end_date,feed_version)
    SELECT '%(source_name)', 
           CASE WHEN r.count>0 THEN feed_publisher_name END,
           CASE WHEN r.count>0 THEN feed_publisher_url END,
           CASE WHEN r.count>0 THEN feed_contact_email END,
           CASE WHEN r.count>0 THEN feed_contact_url END,
           CASE WHEN r.count>0 THEN feed_lang END,
           CASE WHEN r.count>0 THEN feed_start_date END,
           CASE WHEN r.count>0 THEN feed_end_date END,
           CASE WHEN r.count>0 THEN feed_version END
    FROM _tempus_import.feed_info RIGHT JOIN (SELECT count(*) FROM _tempus_import.feed_info) r ON (1=1);

INSERT INTO tempus_gtfs.agency(
            agency_id, agency_name, agency_url, agency_timezone, 
            agency_lang, agency_phone, agency_fare_url, agency_email, feed_id, id)
    SELECT
	        agency_id, agency_name, agency_url, agency_timezone, 
            agency_lang, agency_phone, agency_fare_url, agency_email, '%(source_name)' AS feed_id, 
            (SELECT id FROM _tempus_import.agency_idmap WHERE agency_idmap.agency_id=agency.agency_id) AS id
    FROM
            _tempus_import.agency;

do $$
begin
raise notice '==== Stops ====';
end$$;

UPDATE _tempus_import.stops
SET geom = st_force3DZ(st_setsrid(st_point(stop_lon, stop_lat), 4326))::Geometry(PointZ, 4326);
CREATE INDEX ON _tempus_import.stops USING gist(geom);
CREATE INDEX ON _tempus_import.stops(stop_id);

INSERT INTO tempus_gtfs.stops (
                                feed_id, stop_id, parent_station_id, location_type, stop_name, 
                                stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, 
                                zone_id, stop_url, stop_timezone, geom, id
                              )
SELECT '%(source_name)' AS feed_id, stop_id, parent_station, location_type, stop_name, 
    stop_lat, stop_lon, coalesce(wheelchair_boarding,0), stop_code, stop_desc, 
    zone_id, stop_url, stop_timezone, geom, 
    (SELECT id FROM _tempus_import.stops_idmap WHERE stops_idmap.stop_id=stops.stop_id) AS id
FROM _tempus_import.stops;
    
UPDATE tempus_gtfs.stops
SET parent_station_id_int = stops2.id 
FROM tempus_gtfs.stops stops2 
WHERE stops2.feed_id = stops.feed_id AND stops2.stop_id = stops.parent_station_id;

--
-- attach each stop to the closest road section within a 50 meters radius
--

-- first, CREATE an INDEX ON road_section geography 
CREATE INDEX ON tempus.road_section using gist(geography(geom));

-- reset sequences
DROP SEQUENCE IF EXISTS tempus.seq_road_node_id;
CREATE SEQUENCE tempus.seq_road_node_id start WITH 1;
SELECT setval('tempus.seq_road_node_id', (SELECT max(id) FROM tempus.road_node));

DROP SEQUENCE IF EXISTS tempus.seq_road_section_id;
CREATE SEQUENCE tempus.seq_road_section_id start WITH 1;
SELECT setval('tempus.seq_road_section_id', (SELECT max(id) FROM tempus.road_section));

DO
$$
DECLARE
    l_road_section_id bigint;
    l_node1_id bigint;
    l_node2_id bigint;
    l_abscissa_road_section float8;
    stop record;
BEGIN
    -- Use a loop here in order to make sure stops are compared to road sections
    -- while new road sections are created.
    FOR stop IN
        SELECT * FROM tempus_gtfs.stops WHERE feed_id = '%(source_name)'
    LOOP
        l_road_section_id := null;
        -- get the closest road section (if any)
        SELECT INTO l_road_section_id, l_abscissa_road_section
                    road_section_id, abscissa
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
            l_abscissa_road_section := 1;
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

DROP INDEX tempus.road_section_geography_idx;

-- set parent_station to null when the parent_station does not exist
UPDATE tempus_gtfs.stops
SET parent_station_id=null
WHERE id IN
(
      SELECT s1.id
      FROM tempus_gtfs.stops AS s1
      LEFT JOIN tempus_gtfs.stops AS s2 ON (s1.parent_station_id = s2.stop_id AND s1.feed_id = s2.feed_id)
      WHERE s1.parent_station_id IS NOT NULL AND s2.id IS NULL
);


do $$
begin
raise notice '==== PT transport modes ====';
end$$;

CREATE TABLE _tempus_import.transport_mode
(
  id serial NOT NULL,
  name character varying, -- Description of the mode
  public_transport boolean NOT NULL,
  gtfs_route_type integer -- Reference to the equivalent GTFS code (fOR PT only)
);

SELECT setval('_tempus_import.transport_mode_id_seq', (SELECT max(id) FROM tempus.transport_mode));

INSERT INTO _tempus_import.transport_mode(id, name, public_transport, gtfs_route_type)
    SELECT
        nextval('_tempus_import.transport_mode_id_seq') AS id,
        CASE
            WHEN r.route_type = 0 THEN 'Tram (%(source_name))'
            WHEN r.route_type = 1 THEN 'Subway (%(source_name))'
            WHEN r.route_type = 2 THEN 'Train (%(source_name))'
            WHEN r.route_type = 3 THEN 'Bus (%(source_name))'
            WHEN r.route_type = 4 THEN 'Ferry (%(source_name))'
            WHEN r.route_type = 5 THEN 'Cable-car (%(source_name))'
            WHEN r.route_type = 6 THEN 'Suspended Cable-Car (%(source_name))'
            WHEN r.route_type = 7 THEN 'Funicular (%(source_name))'
        END,
        TRUE,
        r.route_type
    FROM (SELECT DISTINCT route_type FROM _tempus_import.routes) r;

INSERT INTO tempus.transport_mode(id, name, public_transport, gtfs_route_type, gtfs_feed_id)
SELECT id, name, public_transport, gtfs_route_type, (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') as gtfs_feed_id
FROM _tempus_import.transport_mode;

do $$
begin
raise notice '==== PT routes ====';
end$$;

INSERT INTO tempus_gtfs.routes(
            feed_id, route_id, agency_id, route_short_name, route_long_name, 
            route_desc, route_type, route_url, route_color, route_text_color, 
            id, agency_id_int)
SELECT 	'%(source_name)'
        , route_id
        , agency_id
        , route_short_name
        , route_long_name
        , route_desc
        , route_type
        , route_url
        , route_color
        , route_text_color
        , (SELECT id FROM _tempus_import.routes_idmap WHERE routes.route_id=routes_idmap.route_id)
        , (SELECT id FROM tempus_gtfs.agency WHERE agency.agency_id = routes.agency_id AND agency.feed_id = '%(source_name)')
FROM _tempus_import.routes;


do $$
begin
raise notice '==== PT sections and shapes ====';
end$$;

DROP TABLE IF EXISTS _tempus_import.shape_points;
CREATE TABLE _tempus_import.shape_points AS
    SELECT shape_id, 
           shape_pt_sequence, 
           ('srid=4326;point(' || shape_pt_lon || ' ' || shape_pt_lat || ')')::geometry AS geom
    FROM _tempus_import.shapes;
    
CREATE INDEX ON _tempus_import.shape_points USING gist(geom);
CREATE INDEX ON _tempus_import.shape_points(shape_id);

INSERT INTO tempus_gtfs.shapes(feed_id, shape_id, id, geom)
    SELECT '%(source_name)', 
           shape_id, 
           (SELECT id FROM _tempus_import.shapes_idmap WHERE shapes_idmap.shape_id = shape_points.shape_id), 
           st_force3DZ(st_makeline(shape_points.geom ORDER BY shape_pt_sequence)) AS geom
    FROM _tempus_import.shape_points
    GROUP BY shape_points.shape_id;

INSERT INTO tempus_gtfs.sections (stop_from, stop_to, feed_id, shape_id_int, geom)
    WITH pt_seq AS (
            SELECT
                    trip_id
                    -- gtfs stop sequences can have holes
                    -- use the dense rank to have then continuous
                    , dense_rank() over win AS stopseq
                    , stop_sequence
                    , stop_id
            FROM _tempus_import.stop_times 
            window win AS (PARTITION BY trip_id ORDER BY stop_sequence)
    )
    SELECT DISTINCT 
            foo2.stop_from
            , foo2.stop_to
            , (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') AS feed_id
            , (SELECT id FROM tempus_gtfs.shapes WHERE shape_id = foo2.shape_id) AS shape_id_int
            , coalesce(st_linesubstring(foo2.geom, least(st_linelocatepoint(foo2.geom, g1.geom), st_linelocatepoint(foo2.geom, g2.geom)), greatest(st_linelocatepoint(foo2.geom, g1.geom), st_linelocatepoint(foo2.geom, g2.geom))), st_force_3DZ(st_setsrid(st_makeline(g1.geom, g2.geom), 4326))) AS geom
    FROM 
        (
            SELECT stop_from, stop_to, foo.shape_id, st_force3DZ(st_makeline(shape_points.geom ORDER BY shape_pt_sequence)) AS geom
            FROM
            (
                SELECT DISTINCT ON (t1.stop_id, t2.stop_id)
                    (SELECT id FROM _tempus_import.stops_idmap WHERE stop_id=t1.stop_id) AS stop_from,
                    (SELECT id FROM _tempus_import.stops_idmap WHERE stop_id=t2.stop_id) AS stop_to,
                    trips.shape_id
                FROM pt_seq AS t1
                JOIN pt_seq AS t2 ON (t1.trip_id = t2.trip_id AND t1.stopseq = t2.stopseq - 1)
                JOIN _tempus_import.trips ON t1.trip_id = trips.trip_id
                ORDER BY t1.stop_id, t2.stop_id, trips.shape_id
            ) foo
            LEFT JOIN _tempus_import.shape_points ON (shape_points.shape_id = foo.shape_id)
            GROUP BY stop_from, stop_to, foo.shape_id
        ) foo2
    JOIN -- get the from stop geometry
         tempus_gtfs.stops AS g1 ON foo2.stop_from = g1.id
    JOIN -- get the to stop geometry
         tempus_gtfs.stops AS g2 ON foo2.stop_to = g2.id;



do $$
begin
raise notice '==== PT calendar and calendar_dates ====';
end$$;

INSERT INTO tempus_gtfs.calendar(feed_id, service_id, id)
SELECT '%(source_name)', service_id, id
FROM _tempus_import.service_idmap; 

WITH foo AS
(
    SELECT start_date::date + generate_series(0, (extract(days FROM end_date::date) - extract(days FROM start_date::date))::integer) AS date, 
        service_id, 
        monday::boolean AS monday
        , tuesday::boolean AS tuesday
        , wednesday::boolean AS wednesday
        , thursday::boolean AS thursday
        , friday::boolean AS friday
        , saturday::boolean AS saturday
        , sunday::boolean AS sunday
        , start_date::date AS start_date
        , end_date::date AS end_date
    FROM
        _tempus_import.calendar
)
INSERT INTO tempus_gtfs.calendar_dates(feed_id, service_id, date, service_id_int)
(
SELECT '%(source_name)'
       , foo.service_id
       , date
       , (SELECT id FROM _tempus_import.service_idmap WHERE service_idmap.service_id=foo.service_id) AS service_id_int
FROM foo
WHERE (monday::boolean = true AND extract('dow' FROM date)=1) 
   OR (tuesday::boolean = true AND extract('dow' FROM date)=2)
   OR (wednesday::boolean = true AND extract('dow' FROM date)=3)
   OR (thursday::boolean = true AND extract('dow' FROM date)=4)
   OR (friday::boolean = true AND extract('dow' FROM date)=5)
   OR (saturday::boolean = true AND extract('dow' FROM date)=6)
   OR (sunday::boolean = true AND extract('dow' FROM date)=0)
UNION
(
	SELECT '%(source_name)'
           , calendar_dates.service_id
           , calendar_dates.date::date
           , (SELECT id FROM _tempus_import.service_idmap WHERE service_idmap.service_id=calendar_dates.service_id) AS service_id_int
	FROM _tempus_import.calendar_dates
	WHERE exception_type::integer=1
)
EXCEPT
(
	SELECT '%(source_name)'
           , calendar_dates.service_id
           , calendar_dates.date::date
           , (SELECT id FROM _tempus_import.service_idmap WHERE service_idmap.service_id=calendar_dates.service_id) AS service_id_int
	FROM _tempus_import.calendar_dates
	WHERE exception_type::integer=2
)
);

do $$
begin
raise notice '==== PT trips ====';
end$$;

INSERT INTO tempus_gtfs.trips(
            feed_id, trip_id, route_id, service_id, shape_id, wheelchair_accessible, 
            bikes_allowed, trip_headsign, trip_short_name, direction_id, block_id, id, 
            route_id_int, service_id_int, shape_id_int, exact_times, frequency_generated)
(
	SELECT * FROM
	(
		SELECT
		    '%(source_name)'
		    , trip_id
		    , route_id
		    , service_id
		    , shape_id
		    , coalesce(wheelchair_accessible, 0)
		    , coalesce(bikes_allowed, 0)
		    , trip_headsign
		    , trip_short_name
		    , direction_id
		    , block_id
		    , (SELECT id FROM _tempus_import.trips_idmap WHERE trips.trip_id=trips_idmap.trip_id)
		    , (SELECT id FROM _tempus_import.routes_idmap WHERE trips.route_id=routes_idmap.route_id)
		    , (SELECT id FROM _tempus_import.service_idmap WHERE service_idmap.service_id=trips.service_id)
		    , (SELECT id FROM _tempus_import.shapes_idmap WHERE trips.shape_id=shapes_idmap.shape_id)
		    , 1
		    , false
		FROM _tempus_import.trips
	) q
	WHERE q.service_id IS NOT NULL AND q.route_id IS NOT NULL
);


do $$
begin
raise notice '==== PT stop times ====';
end$$;

CREATE OR REPLACE FUNCTION _tempus_import.format_gtfs_time(text)
RETURNS integer AS $$
BEGIN
        return substr($1,1,2)::integer * 3600 + substr($1,4,2)::integer * 60 + substr($1,7,2)::integer;
END;
$$ LANGUAGE plpgsql;

INSERT INTO tempus_gtfs.stop_times (feed_id, trip_id, stop_sequence, stop_id, arrival_time, departure_time, shape_dist_traveled, pickup_type, drop_off_type, stop_headsign, trip_id_int, stop_id_int, interpolated, timepoint)
(
    SELECT '%(source_name)'
	   , stop_times.trip_id
	   , stop_sequence::integer AS stop_sequence
	   , stop_times.stop_id
	   , _tempus_import.format_gtfs_time(arrival_time) AS arrival_time
	   , _tempus_import.format_gtfs_time(departure_time) AS departure_time
	   , coalesce(shape_dist_traveled, 0)
	   , pickup_type::integer AS pickup_type
	   , drop_off_type::integer AS drop_off_type
	   , stop_headsign
	   , (SELECT id FROM _tempus_import.trips_idmap WHERE stop_times.trip_id=trips_idmap.trip_id)
	   , (SELECT id FROM _tempus_import.stops_idmap WHERE stop_times.stop_id=stops_idmap.stop_id)
	   , FALSE
	   , 1
    FROM _tempus_import.stop_times JOIN tempus_gtfs.stops ON (stops.stop_id = stop_times.stop_id AND stops.feed_id = '%(source_name)')
); 

do $$
begin
raise notice '==== PT frequency ====';
end$$;

INSERT INTO tempus_gtfs.stop_times(feed_id, trip_id, stop_sequence, stop_id, arrival_time, departure_time, shape_dist_traveled, pickup_type, drop_off_type, stop_headsign, trip_id_int, stop_id_int, interpolated, timepoint)
       SELECT '%(source_name)'
	       , stop_times.trip_id
	       , stop_sequence::integer AS stop_sequence
	       , stop_times.stop_id
	       , _tempus_import.format_gtfs_time(start_time) + generate_series( 0, _tempus_import.format_gtfs_time(end_time) - _tempus_import.format_gtfs_time(start_time), headway_secs ) AS arrival_time
	       , _tempus_import.format_gtfs_time(start_time) + generate_series( 0, _tempus_import.format_gtfs_time(end_time) - _tempus_import.format_gtfs_time(start_time), headway_secs ) AS departure_time
	       , coalesce(shape_dist_traveled, 0)
	       , pickup_type::integer AS pickup_type
	       , drop_off_type::integer AS drop_off_type
	       , stop_headsign
	       , (SELECT id FROM _tempus_import.trips_idmap WHERE frequencies.trip_id=trips_idmap.trip_id)
	       , (SELECT id FROM _tempus_import.stops_idmap WHERE stop_times.stop_id=stops_idmap.stop_id)
	       , true
	       , 1
	FROM _tempus_import.frequencies JOIN _tempus_import.stop_times ON (stop_times.trip_id = frequencies.trip_id)
					JOIN tempus_gtfs.stops ON (stops.stop_id = stop_times.stop_id AND stops.feed_id = '%(source_name)'); 

do $$
begin
raise notice '==== PT fare attribute ====';
end$$;

INSERT INTO tempus_gtfs.fare_attributes(feed_id, fare_id, price, currency_type, payment_method, transfers, transfer_duration, id)
SELECT 
	'%(source_name)'
	, fare_id
	, price::double precision AS price
	, currency_type::char(3) AS currency_type
	, payment_method
	, transfers::integer AS transfers
	, transfer_duration::integer AS transfer_duration
	, (SELECT id FROM _tempus_import.fare_idmap WHERE fare_idmap.fare_id=fare_attributes.fare_id)
FROM _tempus_import.fare_attributes;

do $$
begin
raise notice '==== PT fare rule ====';
end$$;

INSERT INTO tempus_gtfs.fare_rules (feed_id, fare_id, route_id, origin_id, destination_id, contains_id, 
             fare_id_int, route_id_int, origin_id_int, destination_id_int, contains_id_int)
SELECT
	'%(source_name)'
	, fare_id
	, route_id
	, origin_id
	, destination_id
	, contains_id
	, (SELECT id FROM _tempus_import.fare_idmap WHERE fare_idmap.fare_id=fare_rules.fare_id)
	, (SELECT id FROM _tempus_import.routes_idmap WHERE routes_idmap.route_id=route_id)
	, (SELECT id FROM _tempus_import.zones_idmap WHERE zones_idmap.zone_id=origin_id) 
	, (SELECT id FROM _tempus_import.zones_idmap WHERE zones_idmap.zone_id=destination_id) 
	, (SELECT id FROM _tempus_import.zones_idmap WHERE zones_idmap.zone_id=contains_id) 
FROM
	_tempus_import.fare_rules;

do $$
begin
raise notice '==== PT transfer ====';
end$$;

INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
SELECT '%(source_name)', from_stop_id, to_stop_id, 2, min_transfer_time::integer, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = from_stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = to_stop_id)
FROM _tempus_import.transfers;

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
    -- From stop area to stop : 0 minutes
    SELECT stops1.feed_id, stops1.stop_id, stops2.stop_id, 2, 0, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id)
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = '%(source_name)' AND stops1.parent_station_id = stops2.stop_id
)
UNION
(
    -- From stop to stop area : 10 minutes
    SELECT stops1.feed_id, stops1.stop_id, stops2.stop_id, 2, 10*60, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id)
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = '%(source_name)' AND stops1.stop_id = stops2.parent_station_id
)
ORDER BY 2,3; 

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
VALUES ('transfers_%(source_name)','Transfers between PT stops in the %(source_name) network');

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
         , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_%(source_name)')
         , false AS bifurcation
         , intermed_node_geom
    FROM _tempus_import.road_transfers
    WHERE intermed_node_id IS NOT NULL
    UNION
    SELECT DISTINCT stop_node_id as id
         , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_%(source_name)')
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
   (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_%(source_name)'),
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
  , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_%(source_name)')
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

