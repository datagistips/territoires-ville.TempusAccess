-- Tempus - Public transport networks merging 
 /*
        Substitutions options
        %(temp_schema): name of the temporary PostgreSQL data schema
        %(source_list): names of the PT networks to merge
        %(stops): character (t or f) used to describe if similar stops are merged
        %(agencies): character (t or f) used to describe if similar agencies are merged
        %(services): character (t or f) used to describe if similar services are merged
        %(routes): character (t or f) used to describe if similar routes are merged
        %(trips): character (t or f) used to describe if similar trips are merged
        %(fares): character (t or f) used to describe if similar fares are merged
        %(shapes): character (t or f) used to describe if similar shapes are merged
*/



do $$
begin
RAISE NOTICE '==== Merge PT networks ====';

-- Merge stops
DROP TABLE IF EXISTS %(temp_schema).stops;
IF ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).stops AS
    (
        SELECT DISTINCT ON (stops.stop_id, stops.parent_station_id) stops.stop_id, coalesce(stops_transfers.parent_stop_id, stops.parent_station_id) as parent_station_id, location_type, stop_name, 
                                                        stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, 
                                                        zone_id, stop_url, stop_timezone, geom, road_section_id, abscissa_road_section
        FROM tempus_gtfs.stops LEFT JOIN %(temp_schema).stops_transfers ON (stops_transfers.feed_id = stops.feed_id AND stops_transfers.stop_id = stops.stop_id)
        WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).stops AS
    (
        SELECT stops.feed_id || '-' || stops.stop_id as stop_id, coalesce(stops_transfers.parent_stop_id, stops.feed_id || '-' || stops.parent_station_id) as parent_station_id, location_type, stop_name, 
               stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, 
               zone_id, stop_url, stop_timezone, geom, road_section_id, abscissa_road_section 
        FROM tempus_gtfs.stops LEFT JOIN %(temp_schema).stops_transfers ON (stops_transfers.feed_id = stops.feed_id AND stops_transfers.stop_id = stops.stop_id)
        WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

/* 
DROP TABLE IF EXISTS %(temp_schema).stop_areas;
IF ('%(stop_areas)' = True) THEN
    CREATE TABLE %(temp_schema).stop_areas AS
    (
        SELECT DISTINCT ON (parent_station_id) parent_station_id, location_type, stop_area_name, geom, road_section_id, abscissa_road_section
        FROM tempus_gtfs.stop_areas 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSE
    CREATE TABLE %(temp_schema).stop_areas AS
    (
        SELECT feed_id || '-' || stop_area_id, location_type, stop_area_name, geom, road_section_id, abscissa_road_section
        FROM tempus_gtfs.stop_areas 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF; */

-- Merge agencies
DROP TABLE IF EXISTS %(temp_schema).agency;
IF ('%(agencies)' = True) THEN        
    CREATE TABLE %(temp_schema).agency AS
    (
        SELECT DISTINCT ON (agency_id) agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone, agency_fare_url, agency_email
        FROM tempus_gtfs.agency 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).agency AS
    (
        SELECT feed_id || '-' || agency_id as agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone, agency_fare_url, agency_email
        FROM tempus_gtfs.agency 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge routes
DROP TABLE IF EXISTS %(temp_schema).routes;
IF ('%(routes)' = True) AND ('%(agencies)' = True) THEN
    CREATE TABLE %(temp_schema).routes AS
    (
        SELECT DISTINCT ON (route_id, agency_id) route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).routes AS
    (
        SELECT DISTINCT ON (route_id) route_id, feed_id || '-' || agency_id as agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(agencies)' = True) THEN
    CREATE TABLE %(temp_schema).routes AS
    (
        SELECT DISTINCT ON (agency_id) feed_id || '-' || route_id as route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).routes AS
    (
        SELECT feed_id || '-' || route_id as route_id, feed_id || '-' || agency_id as agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;



-- Merge services
DROP TABLE IF EXISTS %(temp_schema).calendar_dates;
IF ('%(services)' = True) THEN
    CREATE TABLE %(temp_schema).calendar_dates AS
    (
        SELECT DISTINCT ON (service_id) service_id, date
        FROM tempus_gtfs.calendar_dates 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE %(temp_schema).calendar_dates AS
    (
        SELECT feed_id || '-' || service_id as service_id, date
        FROM tempus_gtfs.calendar_dates 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF; 

-- Merge trips
DROP TABLE IF EXISTS %(temp_schema).trips; 
IF ('%(trips)' = True) AND ('%(routes)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (route_id, trip_id, service_id) route_id, service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (route_id, trip_id) route_id, feed_id || '-' || service_id as service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (trip_id, service_id) feed_id || '-' || route_id as route_id, service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(routes)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (route_id, service_id) route_id, service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (route_id) route_id, feed_id || '-' || service_id as service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(services)' = True) THEN
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT DISTINCT ON (service_id) feed_id || '-' || route_id as route_id, service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) THEN 
    CREATE TABLE %(temp_schema).trips AS
    ( 
        SELECT DISTINCT ON (trip_id) feed_id || '-' || route_id as route_id, feed_id || '-' || service_id as service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).trips AS
    (
        SELECT feed_id || '-' || route_id as route_id, feed_id || '-' || service_id as service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );        
END IF; 

-- Merge stop_times
DROP TABLE IF EXISTS %(temp_schema).stop_times;
IF ('%(stops)' = True) AND ('%(trips)' = True) THEN
    CREATE TABLE %(temp_schema).stop_times AS
    (
        SELECT DISTINCT ON (trip_id, stop_id) trip_id, arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).stop_times AS
    (
        SELECT DISTINCT ON (stop_id) feed_id || '-' || trip_id as trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) THEN
    CREATE TABLE %(temp_schema).stop_times AS
    (
        SELECT DISTINCT ON (trip_id) trip_id, arrival_time, departure_time, feed_id || '-' || stop_id as stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSE
    CREATE TABLE %(temp_schema).stop_times AS
    (
        SELECT feed_id || '-' || trip_id as trip_id, arrival_time, departure_time, feed_id || '-' || stop_id as stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge transfers
DROP TABLE IF EXISTS %(temp_schema).transfers;
IF ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).transfers AS
    (
        SELECT DISTINCT ON (from_stop_id, to_stop_id) from_stop_id,to_stop_id,transfer_type,min_transfer_time 
        FROM tempus_gtfs.transfers 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE %(temp_schema).transfers AS
    (
        SELECT feed_id || '-' || from_stop_id as from_stop_id, feed_id || '-' || to_stop_id as to_stop_id, transfer_type, min_transfer_time 
        FROM tempus_gtfs.transfers 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Add new transfers for stops having the same parent_station_id (given by the stops_transfers table)
-- Speed : 1 m/s, Flying distance penalty : 1.4
INSERT INTO %(temp_schema).transfers(from_stop_id, to_stop_id, transfer_type, min_transfer_time)
SELECT s1.stop_id, s2.stop_id, 2, st_length(geography(st_makeline(s1.geom, s2.geom)))*1.4
FROM %(temp_schema).stops s1 JOIN %(temp_schema).stops s2 ON (s1.parent_station_id = s2.parent_station_id)
WHERE (s1.stop_id, s2.stop_id) IN
(
    (
        SELECT s1.stop_id, s2.stop_id
        FROM %(temp_schema).stops s1 JOIN %(temp_schema).stops s2 ON (s1.parent_station_id = s2.parent_station_id)
    )
    EXCEPT
    (
        SELECT from_stop_id, to_stop_id
        FROM %(temp_schema).transfers  
    )
); 


-- Merge fare_attributes
DROP TABLE IF EXISTS %(temp_schema).fare_attributes;
IF ('%(fares)' = True) AND ('%(agencies)' = True) THEN
    CREATE TABLE %(temp_schema).fare_attributes AS
    (
        SELECT DISTINCT ON (fare_id, agency_id) fare_id, price, currency_type, payment_method, transfers, agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) THEN 
    CREATE TABLE %(temp_schema).fare_attributes AS
    (
        SELECT DISTINCT ON (fare_id) fare_id, price, currency_type, payment_method, transfers, feed_id || '-' || agency_id as agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(agencies)' = True) THEN
    CREATE TABLE %(temp_schema).fare_attributes AS
    (
        SELECT DISTINCT ON (agency_id) feed_id || '-' || fare_id as fare_id, price, currency_type, payment_method, transfers, agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).fare_attributes AS
    (
        SELECT feed_id || '-' || fare_id as fare_id, price, currency_type, payment_method, transfers, feed_id || '-' || agency_id as agency_id, transfer_duration
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );    
END IF;

-- Merge fare_rules
DROP TABLE IF EXISTS %(temp_schema).fare_rules;
IF ('%(stops)' = True) AND ('%(routes)' = True) AND ('%(fares)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id, route_id, fare_id) fare_id, route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(stops)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id, route_id) feed_id || '-' || fare_id as fare_id, route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(fares)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (fare_id, route_id) fare_id, route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) AND ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (fare_id, origin_id, destination_id) fare_id, feed_id || '-' || route_id as route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (fare_id) fare_id, feed_id || '-' || route_id as route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (route_id) feed_id || '-' || fare_id as fare_id, route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id) feed_id || '-' || fare_id as fare_id, feed_id || '-' || route_id as route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE %(temp_schema).fare_rules AS
    (
        SELECT feed_id || '-' || fare_id as fare_id, feed_id || '-' || route_id as route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id
        FROM tempus_gtfs.fare_rules
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge sections
DROP TABLE IF EXISTS %(temp_schema).sections;
IF ('%(stops)' = True) AND ('%(shapes)' = True) THEN
    CREATE TABLE %(temp_schema).sections AS
    (
        SELECT DISTINCT ON (stop_from.stop_id, stop_to.stop_id) stop_from.stop_id as from_stop_id, stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE %(temp_schema).sections AS
    (
        SELECT DISTINCT ON (stop_from.stop_id, stop_to.stop_id) stop_from.stop_id as from_stop_id, stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(shapes)' = True) THEN
    CREATE TABLE %(temp_schema).sections AS
    (
        SELECT DISTINCT ON (shapes.shape_id) stop_from.feed_id || '-' || stop_from.stop_id as from_stop_id, stop_from.feed_id || '-' || stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE %(temp_schema).sections AS
    (
        SELECT stop_from.feed_id || '-' || stop_from.stop_id as from_stop_id, stop_from.feed_id || '-' || stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

end$$;



