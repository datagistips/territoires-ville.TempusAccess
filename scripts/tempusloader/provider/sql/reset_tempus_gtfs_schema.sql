
do $$
begin
raise notice '==== PT schema ===';
end$$;


CREATE SCHEMA tempus_gtfs;

CREATE TABLE tempus_gtfs.feed_info (
        feed_id VARCHAR PRIMARY KEY,
        feed_publisher_name VARCHAR,
        feed_publisher_url VARCHAR,
        feed_contact_email VARCHAR,
        feed_contact_url VARCHAR,
        feed_lang VARCHAR,
        feed_start_date DATE,
        feed_end_date DATE,
        feed_version VARCHAR, 
        id serial UNIQUE
);
CREATE INDEX ON tempus_gtfs.feed_info(feed_id);
CREATE INDEX ON tempus_gtfs.feed_info(id);


CREATE TABLE tempus_gtfs.agency (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        agency_id VARCHAR NOT NULL,
        agency_name VARCHAR NOT NULL,
        agency_url VARCHAR NOT NULL,
        agency_timezone VARCHAR NOT NULL,
        agency_lang VARCHAR,
        agency_phone VARCHAR,
        agency_fare_url VARCHAR,
        agency_email VARCHAR, 
        id serial, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, agency_id)
);
CREATE INDEX ON tempus_gtfs.agency(id);


/*CREATE TABLE tempus_gtfs.calendar (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        service_id VARCHAR NOT NULL, 
        id serial, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, service_id)
);
CREATE INDEX ON tempus_gtfs.calendar(id);*/


CREATE TABLE tempus_gtfs.zones (
        feed_id VARCHAR NOT NULL,
        zone_id VARCHAR NOT NULL, 
        id serial, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, zone_id)
);
CREATE INDEX ON tempus_gtfs.zones(id);


CREATE TABLE tempus_gtfs.routes (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE, 
        route_id VARCHAR NOT NULL, 
        agency_id VARCHAR NOT NULL, 
        route_short_name VARCHAR,
        route_long_name VARCHAR,
        route_desc VARCHAR,
        route_type INTEGER NOT NULL,
        route_url VARCHAR,
        route_color VARCHAR,
        route_text_color VARCHAR, 
        id serial, 
        agency_id_int integer REFERENCES tempus_gtfs.agency(id) MATCH SIMPLE ON DELETE CASCADE ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, route_id)
);
CREATE INDEX ON tempus_gtfs.routes(id);
CREATE INDEX ON tempus_gtfs.routes(feed_id, route_type);
CREATE INDEX ON tempus_gtfs.routes(agency_id_int);
CREATE INDEX ON tempus_gtfs.routes(feed_id, agency_id);
CREATE INDEX ON tempus_gtfs.routes(feed_id, route_short_name);


CREATE TABLE tempus_gtfs.fare_attributes (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        fare_id VARCHAR NOT NULL,
        price FLOAT NOT NULL,
        currency_type VARCHAR NOT NULL,
        payment_method INTEGER NOT NULL,
        transfers INTEGER,
        agency_id VARCHAR,
        transfer_duration INTEGER, 
        id serial, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, fare_id)
);
CREATE INDEX ON tempus_gtfs.fare_attributes(id);


CREATE TABLE tempus_gtfs.fare_rules (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        fare_id VARCHAR NOT NULL,
        route_id VARCHAR,
        origin_id VARCHAR,
        destination_id VARCHAR,
        contains_id VARCHAR, 
        fare_id_int integer REFERENCES tempus_gtfs.fare_attributes(id) ON DELETE CASCADE ON UPDATE CASCADE,
        route_id_int integer REFERENCES tempus_gtfs.routes(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        origin_id_int integer REFERENCES tempus_gtfs.zones(id) ON DELETE CASCADE ON UPDATE CASCADE,
        destination_id_int integer REFERENCES tempus_gtfs.zones(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        contains_id_int integer REFERENCES tempus_gtfs.zones(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        PRIMARY KEY(fare_id_int, route_id_int, origin_id_int, destination_id_int, contains_id_int), 
        UNIQUE(feed_id, fare_id, route_id, origin_id, destination_id, contains_id)
);


CREATE TABLE tempus_gtfs.calendar_dates (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        service_id VARCHAR NOT NULL,
        date DATE NOT NULL, 
        id serial, 
        service_id_int integer, -- REFERENCES tempus_gtfs.calendar(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, service_id, date)
);
CREATE INDEX ON tempus_gtfs.calendar_dates(id);
CREATE INDEX ON tempus_gtfs.calendar_dates(feed_id, date);

CREATE TABLE tempus_gtfs.stops (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        stop_id VARCHAR NOT NULL,
        parent_station_id VARCHAR,
        location_type INTEGER NOT NULL,
        stop_name VARCHAR NOT NULL,
        stop_lat FLOAT NOT NULL,
        stop_lon FLOAT NOT NULL,
        wheelchair_boarding INTEGER NOT NULL,
        stop_code VARCHAR,
        stop_desc VARCHAR,
        zone_id VARCHAR,
        stop_url VARCHAR,
        stop_timezone VARCHAR,
        geom Geometry(PointZ, 4326), 
        id serial, 
        parent_station_id_int integer, 
        zone_id_int integer REFERENCES tempus_gtfs.zones(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        road_section_id bigint REFERENCES tempus.road_section(id) MATCH SIMPLE ON DELETE CASCADE ON UPDATE CASCADE, 
        abscissa_road_section double precision CHECK (abscissa_road_section <=1 AND abscissa_road_section >=0),
        PRIMARY KEY (id), 
        UNIQUE(feed_id, stop_id)
);
CREATE INDEX ON tempus_gtfs.stops(id);
CREATE INDEX ON tempus_gtfs.stops(parent_station_id_int);
CREATE INDEX ON tempus_gtfs.stops USING gist(geom);

/* 
CREATE TABLE tempus_gtfs.shapes (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        shape_id VARCHAR NOT NULL, 
        id serial, 
        geom Geometry(LineStringZ, 4326), 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, shape_id)
); 
CREATE INDEX ON tempus_gtfs.shapes USING gist(geom); */


/*CREATE TABLE tempus_gtfs.shape_pts (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        shape_id VARCHAR NOT NULL,
        shape_pt_sequence INTEGER NOT NULL,
        shape_dist_traveled FLOAT NOT NULL,
        shape_pt_lat FLOAT NOT NULL,
        shape_pt_lon FLOAT NOT NULL, 
        id serial, 
        shape_id_int integer REFERENCES tempus_gtfs.shapes(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, shape_id, shape_pt_sequence)
);
CREATE INDEX ON tempus_gtfs.shape_pts(id);
CREATE INDEX ON tempus_gtfs.shape_pts(feed_id, shape_id);*/


CREATE TABLE tempus_gtfs.sections (
	id serial, 
    stop_from integer NOT NULL REFERENCES tempus_gtfs.stops(id) ON DELETE CASCADE ON UPDATE CASCADE,
	stop_to integer NOT NULL REFERENCES tempus_gtfs.stops(id) ON DELETE CASCADE ON UPDATE CASCADE,
	feed_id integer REFERENCES tempus_gtfs.feed_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
	geom Geometry(LineStringZ, 4326), 
	PRIMARY KEY (id),
	UNIQUE (feed_id, stop_from, stop_to)
);
CREATE INDEX ON tempus_gtfs.sections(id);
CREATE INDEX ON tempus_gtfs.sections(stop_from);
CREATE INDEX ON tempus_gtfs.sections(stop_to);
CREATE INDEX ON tempus_gtfs.sections USING gist(geom);


CREATE TABLE tempus_gtfs.transfers (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        from_stop_id VARCHAR NOT NULL,
        to_stop_id VARCHAR NOT NULL,
        transfer_type INTEGER NOT NULL,
        min_transfer_time INTEGER, 
        id serial, 
        from_stop_id_int integer REFERENCES tempus_gtfs.stops(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        to_stop_id_int integer REFERENCES tempus_gtfs.stops(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, from_stop_id, to_stop_id)
);
CREATE INDEX ON tempus_gtfs.transfers(id); 
CREATE INDEX ON tempus_gtfs.transfers(from_stop_id_int);
CREATE INDEX ON tempus_gtfs.transfers(to_stop_id_int);


CREATE TABLE tempus_gtfs.trips (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        trip_id VARCHAR NOT NULL,
        route_id VARCHAR NOT NULL,
        service_id VARCHAR NOT NULL,
        shape_id VARCHAR,
        wheelchair_accessible INTEGER NOT NULL,
        bikes_allowed INTEGER NOT NULL,
        exact_times INTEGER NOT NULL,
        frequency_generated BOOLEAN NOT NULL,
        trip_headsign VARCHAR,
        trip_short_name VARCHAR,
        direction_id INTEGER,
        block_id VARCHAR, 
        id serial, 
        route_id_int integer REFERENCES tempus_gtfs.routes(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        service_id_int integer, -- REFERENCES tempus_gtfs.calendar(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        shape_id_int integer, --REFERENCES tempus_gtfs.shapes(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, trip_id)
);
CREATE INDEX ON tempus_gtfs.trips(id);
CREATE INDEX ON tempus_gtfs.trips(route_id_int);
CREATE INDEX ON tempus_gtfs.trips(service_id_int);
CREATE INDEX ON tempus_gtfs.trips(shape_id_int);


CREATE TABLE tempus_gtfs.stop_times (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        trip_id VARCHAR NOT NULL,
        stop_sequence INTEGER NOT NULL,
        stop_id VARCHAR NOT NULL,
        arrival_time INTEGER,
        departure_time INTEGER,
        interpolated BOOLEAN NOT NULL,
        shape_dist_traveled FLOAT NOT NULL,
        timepoint INTEGER NOT NULL,
        pickup_type INTEGER NOT NULL,
        drop_off_type INTEGER NOT NULL,
        stop_headsign VARCHAR, 
        id serial, 
        trip_id_int integer REFERENCES tempus_gtfs.trips(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        stop_id_int integer REFERENCES tempus_gtfs.stops(id) MATCH SIMPLE ON DELETE NO ACTION ON UPDATE CASCADE, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, trip_id, stop_id, stop_sequence)
);
CREATE INDEX ON tempus_gtfs.stop_times(feed_id, stop_id);
CREATE INDEX ON tempus_gtfs.stop_times(feed_id, stop_sequence);
CREATE INDEX ON tempus_gtfs.stop_times(id); 
CREATE INDEX ON tempus_gtfs.stop_times(trip_id_int);
CREATE INDEX ON tempus_gtfs.stop_times(stop_id_int);


CREATE MATERIALIZED VIEW tempus_gtfs.shapes AS
SELECT trips.shape_id_int as id, trips.feed_id, trips.shape_id as shape_id, st_union(sections.geom) as geom
FROM tempus_gtfs.trips JOIN tempus_gtfs.stop_times st_from ON (st_from.trip_id_int = trips.id)
                       JOIN tempus_gtfs.stop_times st_to ON (st_to.trip_id_int = trips.id)
                       JOIN tempus_gtfs.sections ON (st_from.stop_id_int = sections.stop_from AND st_to.stop_id_int = sections.stop_to)
GROUP BY trips.shape_id_int, trips.feed_id, trips.shape_id;

-- for each pair of pt stops, departure, arrival_time and service_id of each available trip
CREATE VIEW tempus_gtfs.timetable AS
SELECT
  trips.feed_id,
  st1.id as origin_stop,
  st2.id as destination_stop,
  trips.id as trip_id,
  t1.departure_time / 60.0 as departure_time,
  t2.arrival_time / 60.0 as arrival_time,
  trips.service_id
FROM
  tempus_gtfs.stop_times t1
  JOIN tempus_gtfs.stop_times t2 ON (t1.trip_id = t2.trip_id) and (t1.feed_id = t2.feed_id) and (t2.stop_sequence = t1.stop_sequence + 1)
  JOIN tempus_gtfs.trips ON trips.trip_id = t1.trip_id and trips.feed_id = t1.feed_id
  JOIN tempus_gtfs.stops st1 ON st1.stop_id = t1.stop_id and st1.feed_id = t1.feed_id
  JOIN tempus_gtfs.stops st2 ON st2.stop_id = t2.stop_id and st2.feed_id = t2.feed_id
;

-- trigger to propagate stop deletion to artificial road sections
CREATE OR REPLACE FUNCTION tempus.delete_artificial_stop_road_section_f() 
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM tempus.road_section 
    WHERE OLD.road_section_id = road_section.id AND network_id = 0 AND road_section.id IN 
    (
        SELECT road_section.id
        FROM tempus.road_section
        LEFT JOIN tempus_gtfs.stops 
        ON road_section.id = stops.road_section_id
        LEFT JOIN tempus.poi
        ON road_section.id = poi.road_section_id
        WHERE stops.road_section_id IS NULL AND poi.road_section_id IS NULL
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_artificial_stop_road_section ON tempus_gtfs.stops;
CREATE TRIGGER delete_artificial_stop_road_section 
AFTER DELETE ON tempus_gtfs.stops
FOR EACH ROW
EXECUTE PROCEDURE tempus.delete_artificial_stop_road_section_f();

CREATE OR REPLACE FUNCTION tempus.delete_isolated_road_nodes_f()
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM tempus.road_node
    WHERE OLD.node_from = road_node.id OR OLD.node_to = road_node.id AND id IN
    (
        SELECT road_node.id
        FROM tempus.road_node
        LEFT JOIN tempus.road_section AS s1
        ON s1.node_from = road_node.id
        LEFT JOIN tempus.road_section AS s2
        ON s2.node_to = road_node.id
        WHERE s1.node_from is null AND s2.node_to is null
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_isolated_road_nodes ON tempus.road_section;
CREATE TRIGGER delete_isolated_road_nodes
AFTER DELETE ON tempus.road_section
FOR EACH ROW
EXECUTE PROCEDURE tempus.delete_isolated_road_nodes_f();


-- link from transport_mode to gtfs feed
alter table tempus.transport_mode
ADD COLUMN gtfs_feed_id bigint references tempus_gtfs.feed_info(id) on delete cascade on update cascade;

-- Trigger which redraws a section as a straight line between the two stops, when one of the stops position is moved
CREATE OR REPLACE FUNCTION tempus_gtfs.retrace_section_f()
  RETURNS TRIGGER AS
$BODY$
BEGIN
    -- Update the stop_lat and stop_lon fields with values from the new geometry
    UPDATE tempus_gtfs.stops
    SET stop_lat = st_y(NEW.geom), stop_lon = st_x(NEW.geom)
    WHERE NEW.id = stops.id;
    
    -- Update corresponding sections : they are retraced with a straight line joining origin and destination stops
    UPDATE tempus_gtfs.sections
    SET geom = CASE 
                   WHEN shape_id_int IS NULL 
                        THEN st_makeline(NEW.geom, st_endpoint(sections.geom)) 
                   ELSE 
                        (SELECT st_linesubstring(shapes.geom, st_linelocatepoint(NEW.geom, shapes.geom), st_endpoint(sections.geom)) FROM tempus_gtfs.shapes WHERE shapes.id = shape_id_int)
               END
    WHERE NEW.id = sections.stop_from; 
    
    UPDATE tempus_gtfs.sections
    SET geom = CASE 
                   WHEN shape_id_int IS NULL 
                        THEN st_makeline(NEW.geom, st_endpoint(sections.geom)) 
                   ELSE 
                        (SELECT st_linesubstring(shapes.geom, st_startpoint(sections.geom), st_linelocatepoint(NEW.geom, shapes.geom)) FROM tempus_gtfs.shapes WHERE shapes.id = shape_id_int)
               END
    WHERE NEW.id = sections.stop_to; 

    return NEW;
END;
$BODY$
  LANGUAGE plpgsql;

CREATE TRIGGER retrace_section AFTER UPDATE ON tempus_gtfs.stops
    FOR EACH ROW WHEN (OLD.geom IS DISTINCT FROM NEW.geom)
        EXECUTE PROCEDURE tempus_gtfs.retrace_section_f();
 
-- Materialized view containing stops, distinct by mode passing at the stop
-- If GTFS is correctly coded, there should be the same number of stops in that view than in the original table
CREATE MATERIALIZED VIEW tempus_gtfs.stops_by_mode AS 
    SELECT row_number() OVER () AS gid,
        q.id, 
        q.feed_id,
        q.stop_id,
        q.stop_name,
        q.zone_id,
        q.stop_url,
        q.location_type,
        q.parent_station_id,
        q.geom,
        q.route_type
       FROM ( 
            SELECT DISTINCT 
                stops.id, 
                stops.feed_id,
                stops.stop_id,
                stops.stop_name,
                stops.zone_id,
                stops.stop_url,
                stops.location_type,
                stops.parent_station_id,
                stops.geom,
                routes.route_type
               FROM tempus_gtfs.stops JOIN tempus_gtfs.stop_times ON (stops.feed_id = stop_times.feed_id AND stops.stop_id = stop_times.stop_id)
                                      JOIN tempus_gtfs.trips ON (stop_times.feed_id = trips.feed_id AND stop_times.trip_id = trips.trip_id)
                                      JOIN tempus_gtfs.routes ON (routes.feed_id = trips.feed_id AND trips.route_id = routes.route_id)
              ORDER BY stops.id, routes.route_type 
            ) q
;

CREATE MATERIALIZED VIEW tempus_gtfs.sections_by_mode AS
    SELECT row_number() OVER () AS gid,
           sections.id as section_id, 
           stops1.feed_id, 
           sections.stop_from,
           stops1.stop_id as stop_id_from, 
           stops1.stop_name as stop_name_from, 
           sections.stop_to,
           stops2.stop_id as stop_id_to, 
           stops2.stop_name as stop_name_to,
           t.route_type, 
           sections.geom
    FROM (
        SELECT DISTINCT ON (st1.feed_id, st1.stop_id, st2.stop_id, routes.route_type)
          st1.feed_id,
          st1.stop_id as stop1, 
          st2.stop_id as stop2, 
          routes.route_type
        FROM tempus_gtfs.stop_times st1 JOIN tempus_gtfs.stop_times st2 ON ((st1.trip_id = st2.trip_id) AND (st1.feed_id = st2.feed_id) AND (st2.stop_sequence = st1.stop_sequence + 1))
                                        JOIN tempus_gtfs.trips ON (st2.trip_id = trips.trip_id) AND (st2.feed_id = trips.feed_id)
                                        JOIN tempus_gtfs.routes ON (trips.route_id = routes.route_id) AND (trips.feed_id = routes.feed_id)
    ) t
    JOIN tempus_gtfs.sections ON sections.feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = t.feed_id) AND (sections.stop_from = (SELECT id FROM tempus_gtfs.stops WHERE stop_id =t.stop1 AND feed_id = t.feed_id)) AND (sections.stop_to = (SELECT id FROM tempus_gtfs.stops WHERE stop_id = t.stop2 AND feed_id = t.feed_id))
    JOIN tempus_gtfs.stops stops1 ON (sections.feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = stops1.feed_id)) AND (stops1.id = sections.stop_from)
    JOIN tempus_gtfs.stops stops2 ON (sections.feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = stops2.feed_id)) AND (stops2.id = sections.stop_to)
;

-- Materialized view containing trips, distinct by modes serving the trip
CREATE MATERIALIZED VIEW IF NOT EXISTS tempus_gtfs.trips_by_mode AS 
(
    SELECT row_number() over() as gid, q.feed_id, q.shape_id, q.trip_ids, q.route_type, shapes.geom
    FROM (
        SELECT trips.feed_id, trips.shape_id, array_agg(trips.trip_id) as trip_ids, routes.route_type 
        FROM tempus_gtfs.trips JOIN tempus_gtfs.routes ON (trips.feed_id = routes.feed_id AND trips.route_id = routes.route_id) 
        GROUP BY trips.feed_id, shape_id, route_type 
        ORDER BY trips.feed_id, shape_id, route_type 
    ) q JOIN tempus_gtfs.shapes ON (q.feed_id = shapes.feed_id AND q.shape_id = shapes.shape_id)
) ;


CREATE OR REPLACE FUNCTION tempus_gtfs.create_idmaps(tablename character varying, pkname character varying)
RETURNS void AS 
$$
DECLARE
s character varying; 
BEGIN
    s='DROP TABLE IF EXISTS _tempus_import.' || $2 || 'map;
    CREATE TABLE _tempus_import.' || $2 || 'map
    (
        id serial primary key,
        ' || $2 || ' varchar
    );
    SELECT setval(''_tempus_import.' || $2 || 'map_id_seq'', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.' || $1 || '), false);
    INSERT INTO _tempus_import.' || $2 || 'map( ' || $2 || ' )
        SELECT DISTINCT ' || $2 || ' FROM _tempus_import.' || $1 || ';
    CREATE INDEX ' || $2 || 'map_vendor_idx ON _tempus_import.' || $2 || 'map(' || $2 || ');'; 
    EXECUTE(s);
END;
$$ 
LANGUAGE plpgsql; 


CREATE OR REPLACE FUNCTION tempus_gtfs.attach_stops_to_road_section(feed_id character varying, distance float) 
RETURNS VOID AS
$$
DECLARE
    l_road_section_id bigint;
    l_node1_id bigint;
    l_node2_id bigint;
    l_abscissa_road_section float8;
    stop record;

BEGIN
    -- CREATE an INDEX ON road_section geography 
    CREATE INDEX ON tempus.road_section using gist(geography(geom));

    -- reset sequences
    DROP SEQUENCE IF EXISTS tempus.seq_road_node_id;
    CREATE SEQUENCE tempus.seq_road_node_id start WITH 1;
    PERFORM setval('tempus.seq_road_node_id', (SELECT max(id) FROM tempus.road_node));

    DROP SEQUENCE IF EXISTS tempus.seq_road_section_id;
    CREATE SEQUENCE tempus.seq_road_section_id start WITH 1;
    PERFORM setval('tempus.seq_road_section_id', (SELECT max(id) FROM tempus.road_section));

    -- Use a loop here in order to make sure stops are compared to road sections
    -- while new road sections are created.
    FOR stop IN (SELECT * FROM tempus_gtfs.stops WHERE stops.feed_id = $1)
    LOOP
        l_road_section_id=null;
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
            FROM tempus.road_section rs JOIN tempus.road_network rnet ON (rs.network_id = rnet.id)
            WHERE st_dwithin(geography(stop.geom), geography(rs.geom), $2)
            -- attach to roads waklable by pedestrians
            AND ((rs.traffic_rules_ft & 1) > 0 OR (rs.traffic_rules_tf & 1) > 0)
            AND rnet.name NOT LIKE 'transfers_%' 
            ORDER BY dist
            LIMIT 1
        ) t ;

        IF l_road_section_id IS NULL THEN
            -- no section, create a fake one, from the stop geometry
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
        SET road_section_id = l_road_section_id, abscissa_road_section = l_abscissa_road_section
        WHERE id = stop.id;
    END LOOP;
    
    DROP INDEX tempus.road_section_geography_idx; 
    
END;
$$
LANGUAGE plpgsql;


-- pt stops with integer ids and network ids
CREATE VIEW tempus.load_stops AS
(
    SELECT 
      sections.feed_id as network_id
      , s.id
      , s.stop_name
      , s.location_type
      , p.id as parent_station_id
      , s.road_section_id
      , s.zone_id
      , s.abscissa_road_section
      , s.stop_lon as x
      , s.stop_lat as y
      , 0.0 as z  
    FROM 
      tempus_gtfs.sections
      JOIN tempus_gtfs.stops s on s.id = stop_from
      LEFT JOIN tempus_gtfs.stops p on p.stop_id = s.parent_station_id
)
UNION
(
    SELECT
      sections.feed_id as network_id
      , s.id
      , s.stop_name
      , s.location_type
      , p.id as parent_station_id
      , s.road_section_id
      , s.zone_id
      , s.abscissa_road_section
      , s.stop_lon as x
      , s.stop_lat as y
      , 0.0 as z  
    FROM
      tempus_gtfs.sections
      JOIN tempus_gtfs.stops s on s.id = stop_to
      LEFT JOIN tempus_gtfs.stops p on p.stop_id = s.parent_station_id
);

CREATE VIEW tempus.chk_isolated_stops AS
(
    SELECT p.*
    FROM tempus_gtfs.stops AS p
      LEFT JOIN tempus_gtfs.sections AS s1 on p.id = s1.stop_from
      LEFT JOIN tempus_gtfs.sections AS s2 on p.id = s2.stop_to
      LEFT JOIN tempus_gtfs.stop_times on p.stop_id = stop_times.stop_id
      LEFT JOIN tempus_gtfs.stops AS pp on p.stop_id = pp.parent_station_id
    WHERE s1.stop_from is null
      AND s2.stop_to is null
      AND stop_times.stop_id is null
      AND pp.parent_station_id is null
);

-- View containing all the french bank holidays corresponding to the period covered by the PT data
CREATE OR REPLACE VIEW tempus.view_french_bank_holiday AS 
(
    SELECT date
    FROM
    (
        SELECT date_min + generate_series(0, date_max - date_min) AS date
        FROM
        (
            SELECT min(date) as date_min, max(date) as date_max 
            FROM tempus_gtfs.calendar_dates
        ) q
    ) r
    WHERE tempus.french_bank_holiday(date)=True
); 



