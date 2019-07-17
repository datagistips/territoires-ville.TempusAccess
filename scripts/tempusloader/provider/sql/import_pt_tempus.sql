/*
        Substitutions options
        %(source_name): name of the PT network
        %(max_dist): maximum distance to link a PT stop to a road section
*/


DO
$$
BEGIN
RAISE NOTICE '==== Create ID Maps ====';
END
$$;
    
SELECT tempus_gtfs.create_idmaps('stops', 'stop_id');
SELECT tempus_gtfs.create_idmaps('routes', 'route_id');
SELECT tempus_gtfs.create_idmaps('agency', 'agency_id');
SELECT tempus_gtfs.create_idmaps('trips', 'trip_id');
SELECT tempus_gtfs.create_idmaps('calendar_dates', 'service_id');
SELECT tempus_gtfs.create_idmaps('fare_attributes', 'fare_id');
SELECT tempus_gtfs.create_idmaps('trips', 'shape_id');
SELECT tempus_gtfs.create_idmaps('stops', 'zone_id');    


DO
$$
BEGIN
RAISE NOTICE '==== PT network and agencies ====';
END
$$;

DELETE FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.feed_info(feed_id) VALUES ('%(source_name)');

DELETE FROM tempus_gtfs.agency WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.agency(
                                agency_id, agency_name, agency_url, agency_timezone, 
                                agency_lang, agency_phone, agency_fare_url, agency_email, feed_id, id
                              )
    SELECT
            agency_id, agency_name, agency_url, agency_timezone, 
            agency_lang, agency_phone, agency_fare_url, agency_email, 
            '%(source_name)' AS feed_id, 
            (SELECT id FROM %(temp_schema).agency_idmap WHERE agency_idmap.agency_id=agency.agency_id) AS id
    FROM
            %(temp_schema).agency;
SELECT setval('tempus_gtfs.agency_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.agency), false); 


DO
$$
BEGIN
RAISE NOTICE '==== Stops ====';
END
$$;

DELETE FROM tempus_gtfs.stops WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.stops (id, feed_id, stop_id, parent_station_id, location_type, stop_name, stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, zone_id, stop_url, stop_timezone, geom)
SELECT (SELECT id FROM %(temp_schema).stop_idmap WHERE stop_idmap.stop_id=stops.stop_id) AS id, 
       '%(source_name)' AS feed_id, stop_id, parent_station_id, location_type, stop_name, stop_lat, stop_lon, 
       coalesce(wheelchair_boarding,0), stop_code, stop_desc, zone_id, stop_url, stop_timezone, geom
FROM %(temp_schema).stops;
SELECT setval('tempus_gtfs.stops_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.stops), false); 


-- Set parent_station_id_int 
UPDATE tempus_gtfs.stops
SET parent_station_id_int = stops2.id 
FROM tempus_gtfs.stops stops2 
WHERE stops2.feed_id = stops.feed_id AND stops2.stop_id = stops.parent_station_id;

-- Set parent_station_id to null when the parent_station does not exist
UPDATE tempus_gtfs.stops
SET parent_station_id=null
WHERE id IN
(
    SELECT s1.id
    FROM tempus_gtfs.stops AS s1
    LEFT JOIN tempus_gtfs.stops AS s2 ON (s1.parent_station_id = s2.stop_id AND s1.feed_id = s2.feed_id)
    WHERE s1.parent_station_id IS NOT NULL AND s2.id IS NULL
);

-- Attach stops to the nearest road section within a 50 meters radius 
SELECT tempus_gtfs.attach_stops_to_road_section('%(source_name)', %(max_dist));

DO
$$
BEGIN
RAISE NOTICE '==== PT transport modes ====';
END
$$;

CREATE TABLE %(temp_schema).transport_mode
(
  id serial NOT NULL,
  name character varying, -- Description of the mode
  public_transport boolean NOT NULL,
  gtfs_route_type integer -- Reference to the equivalent GTFS code (for PT only)
);
SELECT setval('%(temp_schema).transport_mode_id_seq', (SELECT max(id) FROM tempus.transport_mode));

INSERT INTO %(temp_schema).transport_mode(id, name, public_transport, gtfs_route_type)
    SELECT
        nextval('%(temp_schema).transport_mode_id_seq') AS id,
        CASE
            WHEN r.route_type = 0 THEN 'Tram (' || '%(source_name)' || ')'
            WHEN r.route_type = 1 THEN 'Subway (' || '%(source_name)' || ')'
            WHEN r.route_type = 2 THEN 'Train (' || '%(source_name)' || ')'
            WHEN r.route_type = 3 THEN 'Bus (' || '%(source_name)' || ')'
            WHEN r.route_type = 4 THEN 'Ferry (' || '%(source_name)' || ')'
            WHEN r.route_type = 5 THEN 'Cable-car (' || '%(source_name)' || ')'
            WHEN r.route_type = 6 THEN 'Suspended Cable-Car (' || '%(source_name)' || ')'
            WHEN r.route_type = 7 THEN 'Funicular (' || '%(source_name)' || ')'
        END,
        TRUE,
        r.route_type
    FROM (SELECT DISTINCT route_type FROM %(temp_schema).routes) r;

INSERT INTO tempus.transport_mode(id, name, public_transport, gtfs_route_type, gtfs_feed_id)
SELECT id, name, public_transport, gtfs_route_type, (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') as gtfs_feed_id
FROM %(temp_schema).transport_mode; 

DO
$$
BEGIN
raise notice '==== PT routes ====';
END
$$;

DELETE FROM tempus_gtfs.routes WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.routes(id, feed_id, route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color, agency_id_int)
SELECT  (SELECT id FROM %(temp_schema).route_idmap WHERE route_idmap.route_id=routes.route_id) as id
        , '%(source_name)'
        , route_id
        , agency_id
        , route_short_name
        , route_long_name
        , route_desc
        , route_type
        , route_url
        , route_color
        , route_text_color
        , (SELECT id FROM tempus_gtfs.agency WHERE agency.agency_id = routes.agency_id AND agency.feed_id = '%(source_name)')
FROM %(temp_schema).routes;
SELECT setval('tempus_gtfs.routes_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.routes), false); 

DO
$$
BEGIN
raise notice '==== PT sections and shapes ====';
END
$$;

DELETE FROM tempus_gtfs.sections WHERE feed_id = (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = '%(source_name)') ;  
INSERT INTO tempus_gtfs.sections (stop_from, stop_to, feed_id, geom)
SELECT (SELECT id FROM %(temp_schema).stop_idmap WHERE stop_id=sections.from_stop_id) AS stop_from,
       (SELECT id FROM %(temp_schema).stop_idmap WHERE stop_id=sections.to_stop_id) AS stop_to, 
       (SELECT id FROM tempus_gtfs.feed_info WHERE feed_info.feed_id = '%(source_name)'), 
       geom
FROM %(temp_schema).sections;

DO
$$
BEGIN
raise notice '==== PT calendar and calendar_dates ====';
END
$$;

DELETE FROM tempus_gtfs.calendar_dates WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.calendar_dates(feed_id, service_id, date, service_id_int)
(
    SELECT '%(source_name)'
           , calendar_dates.service_id
           , calendar_dates.date::date
           , (SELECT id FROM %(temp_schema).service_idmap WHERE service_idmap.service_id=calendar_dates.service_id) AS service_id_int
    FROM %(temp_schema).calendar_dates
);


DO
$$
BEGIN
raise notice '==== PT trips ====';
END
$$;

DELETE FROM tempus_gtfs.trips WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.trips(id, feed_id, trip_id, route_id, service_id, shape_id, wheelchair_accessible, 
       bikes_allowed, exact_times, frequency_generated, trip_headsign, 
       trip_short_name, direction_id, block_id, route_id_int, service_id_int, shape_id_int)
(
    SELECT * FROM
    (
        SELECT
            (SELECT id FROM %(temp_schema).trip_idmap WHERE trip_idmap.trip_id=trips.trip_id) as id
            , '%(source_name)'
            , trip_id
            , route_id
            , service_id
            , shape_id
            , wheelchair_accessible
            , bikes_allowed
            , exact_times
            , frequency_generated
            , trip_headsign
            , trip_short_name
            , direction_id
            , block_id
            , (SELECT id FROM %(temp_schema).route_idmap WHERE route_idmap.route_id=trips.route_id) as route_id_int
            , (SELECT id FROM %(temp_schema).service_idmap WHERE service_idmap.service_id=trips.service_id) as service_id_int
            , (SELECT id FROM %(temp_schema).shape_idmap WHERE shape_idmap.shape_id=trips.shape_id) as shape_id_int
        FROM %(temp_schema).trips
    ) q
    WHERE q.service_id IS NOT NULL AND q.route_id IS NOT NULL
);
SELECT setval('tempus_gtfs.trips_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.trips), false);


DO
$$
BEGIN
raise notice '==== PT stop times ====';
END
$$;

DELETE FROM tempus_gtfs.stop_times WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.stop_times (feed_id, trip_id, stop_sequence, stop_id, arrival_time, departure_time, shape_dist_traveled, pickup_type, drop_off_type, stop_headsign, trip_id_int, stop_id_int, interpolated, timepoint)
(
    SELECT '%(source_name)'
       , stop_times.trip_id
       , stop_sequence::integer AS stop_sequence
       , stop_times.stop_id
       , arrival_time
       , departure_time
       , coalesce(shape_dist_traveled, 0)
       , pickup_type
       , drop_off_type
       , null 
       , (SELECT id FROM %(temp_schema).trip_idmap WHERE stop_times.trip_id=trip_idmap.trip_id)
       , (SELECT id FROM %(temp_schema).stop_idmap WHERE stop_times.stop_id=stop_idmap.stop_id)
       , FALSE
       , 1
    FROM %(temp_schema).stop_times JOIN tempus_gtfs.stops ON (stops.stop_id = stop_times.stop_id AND stops.feed_id = '%(source_name)')
); 


DO
$$
BEGIN
raise notice '==== PT fare attribute ====';
END
$$;

DELETE FROM tempus_gtfs.fare_attributes WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.fare_attributes(feed_id, fare_id, price, currency_type, payment_method, transfers, transfer_duration, id)
SELECT 
    '%(source_name)'
    , fare_id
    , price::double precision AS price
    , currency_type::char(3) AS currency_type
    , payment_method
    , transfers::integer AS transfers
    , transfer_duration::integer AS transfer_duration
    , (SELECT id FROM %(temp_schema).fare_idmap WHERE fare_idmap.fare_id=fare_attributes.fare_id)
FROM %(temp_schema).fare_attributes;
SELECT setval('tempus_gtfs.fare_attributes_id_seq', (SELECT coalesce(max(id)+1, 1) FROM tempus_gtfs.fare_attributes), false);


DO
$$
BEGIN
raise notice '==== PT fare rule ====';
END
$$;

DELETE FROM tempus_gtfs.fare_rules WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.fare_rules (feed_id, fare_id, route_id, origin_id, destination_id, contains_id, fare_id_int, route_id_int, origin_id_int, destination_id_int, contains_id_int)
SELECT
    '%(source_name)'
    , fare_id
    , route_id
    , origin_id
    , destination_id
    , contains_id
    , (SELECT id FROM %(temp_schema).fare_idmap WHERE fare_idmap.fare_id=fare_rules.fare_id)
    , (SELECT id FROM %(temp_schema).route_idmap WHERE route_idmap.route_id=route_id)
    , (SELECT id FROM %(temp_schema).zone_idmap WHERE zone_idmap.zone_id=origin_id) 
    , (SELECT id FROM %(temp_schema).zone_idmap WHERE zone_idmap.zone_id=destination_id) 
    , (SELECT id FROM %(temp_schema).zone_idmap WHERE zone_idmap.zone_id=contains_id) 
FROM
    %(temp_schema).fare_rules;


DO
$$
BEGIN
raise notice '==== PT transfer ====';
END
$$;

DELETE FROM tempus_gtfs.transfers WHERE feed_id = '%(source_name)'; 
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
SELECT '%(source_name)', from_stop_id, to_stop_id, 2, min_transfer_time::integer, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = from_stop_id), (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = '%(source_name)' AND stops.stop_id = to_stop_id)
FROM %(temp_schema).transfers;

-- New transfers are created between stops belonging to the same parent_station_id, but which are not linked by a transfer edge

-- New transfers are created between stops belonging to the same parent_station_id, but which are not linked by a transfer edge
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int)
(
    SELECT q.feed_id, q.from_stop_id, q.to_stop_id, transfer_type, min_transfer_time, from_stop_id_int, to_stop_id_int
    FROM
    (
        (
            -- From stop to stop : 10 minutes
            SELECT stops1.feed_id, stops1.stop_id as from_stop_id, stops2.stop_id as to_stop_id, 2 as transfer_type, 10*60 as min_transfer_time, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops1.feed_id AND stops.stop_id = stops1.stop_id) as from_stop_id_int, (SELECT id FROM tempus_gtfs.stops WHERE stops.feed_id = stops2.feed_id AND stops.stop_id = stops2.stop_id) as to_stop_id_int
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
    ) q
    LEFT JOIN (SELECT feed_id, from_stop_id, to_stop_id FROM tempus_gtfs.transfers) r ON (q.feed_id = r.feed_id  AND q.from_stop_id = r.from_stop_id AND q.to_stop_id = r.to_stop_id)
    WHERE r.feed_id IS NULL
    ORDER BY 2,3
); 

DROP TABLE IF EXISTS %(temp_schema).transfers_without_doubles;
CREATE TABLE %(temp_schema).transfers_without_doubles AS
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
VALUES ('transfers_' || '%(source_name)','Transfers between PT stops in the ' || '%(source_name)' || ' network');

DROP SEQUENCE IF EXISTS seq_transfer_node_id;
CREATE SEQUENCE seq_transfer_node_id start WITH 1;
SELECT setval('seq_transfer_node_id', (SELECT max(id)+1 FROM tempus.road_node));

DROP SEQUENCE IF EXISTS seq_transfer_section_id;
CREATE SEQUENCE seq_transfer_section_id start WITH 1;
SELECT setval('seq_transfer_section_id', (SELECT max(id)+1 FROM tempus.road_section));

-- mark each (distinct) stop involved in a transfer
DROP TABLE IF EXISTS %(temp_schema).road_transfers;
CREATE TABLE %(temp_schema).road_transfers AS
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
         , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_' || '%(source_name)')
         , false AS bifurcation
         , intermed_node_geom
    FROM %(temp_schema).road_transfers
    WHERE intermed_node_id IS NOT NULL
    UNION
    SELECT DISTINCT stop_node_id as id
         , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_' || '%(source_name)')
         , false AS bifurcation
         , stop_node_geom
    FROM %(temp_schema).road_transfers
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
FROM %(temp_schema).road_transfers
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
FROM %(temp_schema).road_transfers
WHERE first_split_id IS NOT NULL
UNION
SELECT
   link_section_id AS id, 
   (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_' || '%(source_name)'),
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
FROM %(temp_schema).road_transfers
WHERE link_section_id IS NOT NULL
ORDER BY id
);

UPDATE tempus_gtfs.stops
SET road_section_id = link_section_id, abscissa_road_section = 1
FROM %(temp_schema).road_transfers
WHERE stops.id = road_transfers.id; 

-- Insert the transfer sections
INSERT INTO tempus.road_section(id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, geom)
SELECT
  nextval('seq_transfer_section_id')::bigint
  , (SELECT max(id) FROM tempus.road_network WHERE name = 'transfers_' || '%(source_name)')
  , 5 AS road_type -- road_type dedicated to transfer between PT stops
  , nn1.stop_node_id
  , nn2.stop_node_id
  , 1 as traffic_rules_ft
  , CASE WHEN tr.both_dir = TRUE THEN 1 ELSE 0 END as traffic_rules_tf
  , min_transfer_time::float * 5000 / 3600.0 AS length -- convert FROM time to distance (multiply by walking speed)
  , 'Transfer'
  , st_makeline(s1.geom, s2.geom)
FROM
  %(temp_schema).transfers_without_doubles tr
  JOIN tempus_gtfs.stops s1 ON (s1.feed_id = tr.feed_id AND s1.stop_id = tr.from_stop_id)
  JOIN tempus_gtfs.stops s2 ON (s2.feed_id = tr.feed_id AND s2.stop_id = tr.to_stop_id)
  JOIN %(temp_schema).road_transfers nn1 ON nn1.id = s1.id
  JOIN %(temp_schema).road_transfers nn2 ON nn2.id = s2.id;  


-- Speed is defined for pedestrians on road sections
INSERT INTO tempus.road_daily_profile(
            profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES((SELECT CASE WHEN max(profile_id) IS NULL THEN 1 ELSE max(profile_id)+1 END FROM tempus.road_daily_profile),0,1,1440,3.6);
  
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, (SELECT max(profile_id) FROM tempus.road_daily_profile)
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 1) > 0 OR (road_section.traffic_rules_tf::integer & 1) > 0;

VACUUM FULL ANALYSE;

