-- Tempus - Public transport networks merging 
 /*
        Substitutions options
        %(source_list): names of the PT networks to merge
        %(stops): character (t or f) used to describe if similar stops are merged
        %(agencies): character (t or f) used to describe if similar agencies are merged
        %(services): character (t or f) used to describe if similar services are merged
        %(routes): character (t or f) used to describe if similar routes are merged
        %(trips): character (t or f) used to describe if similar trips are merged
        %(fares): character (t or f) used to describe if similar fares are merged
        %(shapes): character (t or f) used to describe if similar shapes are merged
*/

DROP SCHEMA IF EXISTS _tempus_import CASCADE;
CREATE SCHEMA _tempus_import; 

do $$
begin
RAISE NOTICE '==== Merge PT networks ====';

-- Merge stops
DROP TABLE IF EXISTS _tempus_import.stops;
IF ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.stops AS
    (
        SELECT DISTINCT ON (stop_id) stop_id, parent_station_id, location_type, stop_name, stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, 
                                     zone_id, stop_url, stop_timezone, geom, road_section_id, abscissa_road_section
        FROM tempus_gtfs.stops 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSE
    CREATE TABLE _tempus_import.stops AS
    (
        SELECT feed_id || '-' || stop_id as stop_id, parent_station_id, location_type, stop_name, 
            stop_lat, stop_lon, wheelchair_boarding, stop_code, stop_desc, 
            zone_id, stop_url, stop_timezone, geom, road_section_id, abscissa_road_section 
        FROM tempus_gtfs.stops
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge agencies
DROP TABLE IF EXISTS _tempus_import.agency;
IF ('%(agencies)' = True) THEN        
    CREATE TABLE _tempus_import.agency AS
    (
        SELECT DISTINCT ON (agency_id) agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone, agency_fare_url, agency_email
        FROM tempus_gtfs.agency 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE _tempus_import.agency AS
    (
        SELECT feed_id || '-' || agency_id as agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone, agency_fare_url, agency_email
        FROM tempus_gtfs.agency 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge routes
DROP TABLE IF EXISTS _tempus_import.routes;
IF ('%(routes)' = True) AND ('%(agencies)' = True) THEN
    CREATE TABLE _tempus_import.routes AS
    (
        SELECT DISTINCT ON (route_id, agency_id) route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.routes AS
    (
        SELECT DISTINCT ON (route_id) route_id, feed_id || '-' || agency_id as agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(agencies)' = True) THEN
    CREATE TABLE _tempus_import.routes AS
    (
        SELECT DISTINCT ON (agency_id) feed_id || '-' || route_id as route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE _tempus_import.routes AS
    (
        SELECT feed_id || '-' || route_id as route_id, feed_id || '-' || agency_id as agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color 
        FROM tempus_gtfs.routes 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;



-- Merge services
DROP TABLE IF EXISTS _tempus_import.calendar_dates;
IF ('%(services)' = True) THEN
    CREATE TABLE _tempus_import.calendar_dates AS
    (
        SELECT DISTINCT ON (service_id) service_id, date
        FROM tempus_gtfs.calendar_dates 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE _tempus_import.calendar_dates AS
    (
        SELECT feed_id || '-' || service_id as service_id, date
        FROM tempus_gtfs.calendar_dates 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF; 

-- Merge trips
DROP TABLE IF EXISTS _tempus_import.trips; 
IF ('%(trips)' = True) AND ('%(routes)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (route_id, trip_id, service_id) route_id, service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (route_id, trip_id) route_id, feed_id || '-' || service_id as service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (trip_id, service_id) feed_id || '-' || route_id as route_id, service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(routes)' = True) AND ('%(services)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (route_id, service_id) route_id, service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (route_id) route_id, feed_id || '-' || service_id as service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(services)' = True) THEN
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT DISTINCT ON (service_id) feed_id || '-' || route_id as route_id, service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) THEN 
    CREATE TABLE _tempus_import.trips AS
    ( 
        SELECT DISTINCT ON (trip_id) feed_id || '-' || route_id as route_id, feed_id || '-' || service_id as service_id, trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE _tempus_import.trips AS
    (
        SELECT feed_id || '-' || route_id as route_id, feed_id || '-' || service_id as service_id, feed_id || '-' || trip_id as trip_id, trip_headsign, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_short_name, direction_id, block_id, shape_id
        FROM tempus_gtfs.trips
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );        
END IF; 

-- Merge stop_times
DROP TABLE IF EXISTS _tempus_import.stop_times;
IF ('%(stops)' = True) AND ('%(trips)' = True) THEN
    CREATE TABLE _tempus_import.stop_times AS
    (
        SELECT DISTINCT ON (trip_id, stop_id) trip_id, arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.stop_times AS
    (
        SELECT DISTINCT ON (stop_id) feed_id || '-' || trip_id as trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(trips)' = True) THEN
    CREATE TABLE _tempus_import.stop_times AS
    (
        SELECT DISTINCT ON (trip_id) trip_id, arrival_time, departure_time, feed_id || '-' || stop_id as stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSE
    CREATE TABLE _tempus_import.stop_times AS
    (
        SELECT feed_id || '-' || trip_id as trip_id, arrival_time, departure_time, feed_id || '-' || stop_id as stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled 
        FROM tempus_gtfs.stop_times
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge transfers
DROP TABLE IF EXISTS _tempus_import.transfers;
IF ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.transfers AS
    (
        SELECT DISTINCT ON (from_stop_id, to_stop_id) from_stop_id,to_stop_id,transfer_type,min_transfer_time 
        FROM tempus_gtfs.transfers 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE _tempus_import.transfers AS
    (
        SELECT feed_id || '-' || from_stop_id as from_stop_id, feed_id || '-' || to_stop_id as to_stop_id, transfer_type, min_transfer_time 
        FROM tempus_gtfs.transfers 
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge fare_attributes
DROP TABLE IF EXISTS _tempus_import.fare_attributes;
IF ('%(fares)' = True) AND ('%(agencies)' = True) THEN
    CREATE TABLE _tempus_import.fare_attributes AS
    (
        SELECT DISTINCT ON (fare_id, agency_id) fare_id, price, currency_type, payment_method, transfers, agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) THEN 
    CREATE TABLE _tempus_import.fare_attributes AS
    (
        SELECT DISTINCT ON (fare_id) fare_id, price, currency_type, payment_method, transfers, feed_id || '-' || agency_id as agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(agencies)' = True) THEN
    CREATE TABLE _tempus_import.fare_attributes AS
    (
        SELECT DISTINCT ON (agency_id) feed_id || '-' || fare_id as fare_id, price, currency_type, payment_method, transfers, agency_id, transfer_duration 
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE _tempus_import.fare_attributes AS
    (
        SELECT feed_id || '-' || fare_id as fare_id, price, currency_type, payment_method, transfers, feed_id || '-' || agency_id as agency_id, transfer_duration
        FROM tempus_gtfs.fare_attributes
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );    
END IF;

-- Merge fare_rules
DROP TABLE IF EXISTS _tempus_import.fare_rules;
IF ('%(stops)' = True) AND ('%(routes)' = True) AND ('%(fares)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id, route_id, fare_id) fare_id, route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(stops)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id, route_id) feed_id || '-' || fare_id as fare_id, route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    ); 
ELSIF ('%(fares)' = True) AND ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (fare_id, route_id) fare_id, route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) AND ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (fare_id, origin_id, destination_id) fare_id, feed_id || '-' || route_id as route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(fares)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (fare_id) fare_id, feed_id || '-' || route_id as route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(routes)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (route_id) feed_id || '-' || fare_id as fare_id, route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT DISTINCT ON (origin_id, destination_id) feed_id || '-' || fare_id as fare_id, feed_id || '-' || route_id as route_id, origin_id, destination_id, contains_id 
            FROM tempus_gtfs.fare_rules
            WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE 
    CREATE TABLE _tempus_import.fare_rules AS
    (
        SELECT feed_id || '-' || fare_id as fare_id, feed_id || '-' || route_id as route_id, feed_id || '-' || origin_id as origin_id, feed_id || '-' || destination_id as destination_id, contains_id
        FROM tempus_gtfs.fare_rules
        WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

-- Merge sections
DROP TABLE IF EXISTS _tempus_import.sections;
IF ('%(stops)' = True) AND ('%(shapes)' = True) THEN
    CREATE TABLE _tempus_import.sections AS
    (
        SELECT DISTINCT ON (stop_from.stop_id, stop_to.stop_id) stop_from.stop_id as from_stop_id, stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(stops)' = True) THEN
    CREATE TABLE _tempus_import.sections AS
    (
        SELECT DISTINCT ON (stop_from.stop_id, stop_to.stop_id) stop_from.stop_id as from_stop_id, stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSIF ('%(shapes)' = True) THEN
    CREATE TABLE _tempus_import.sections AS
    (
        SELECT DISTINCT ON (shapes.shape_id) stop_from.feed_id || '-' || stop_from.stop_id as from_stop_id, stop_from.feed_id || '-' || stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
ELSE
    CREATE TABLE _tempus_import.sections AS
    (
        SELECT stop_from.feed_id || '-' || stop_from.stop_id as from_stop_id, stop_from.feed_id || '-' || stop_to.stop_id as to_stop_id, stop_from.feed_id, sections.geom
        FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stop_from ON (sections.stop_from = stop_from.id)
                                  JOIN tempus_gtfs.stops stop_to ON (sections.stop_to = stop_to.id)
        WHERE stop_from.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
          AND stop_to.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY[%(source_list)])
    );
END IF;

end$$;



