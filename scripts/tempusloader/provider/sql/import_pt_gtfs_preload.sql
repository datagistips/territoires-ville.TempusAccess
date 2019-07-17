
-- Feed info
DELETE FROM tempus_gtfs.feed_info 
WHERE feed_id = '%(source_name)'; 

do $$
begin
raise notice '==== Remove constraints (performances concern) ===';
end$$;

-- Remove all related constraints
ALTER TABLE tempus_gtfs.stops 
DROP CONSTRAINT IF EXISTS stops_road_section_id_fkey;

DROP INDEX IF EXISTS tempus_gtfs.stops_id_idx; 
DROP INDEX IF EXISTS tempus_gtfs.stops_station_id_int_idx;
DROP INDEX IF EXISTS tempus_gtfs.stops_geom_idx;

ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_road_section_id_fkey;
ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_station_id_int_fkey;
ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_zone_id_int_fkey;
ALTER TABLE tempus_gtfs.stop_times DROP CONSTRAINT IF EXISTS stop_times_stop_id_int_fkey;
ALTER TABLE tempus_gtfs.stop_times DROP CONSTRAINT IF EXISTS stop_times_trip_id_int_fkey;
ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_shape_id_int_fkey;
ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_stop_from_fkey;
ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_stop_to_fkey; 
ALTER TABLE tempus_gtfs.routes DROP CONSTRAINT IF EXISTS routes_agency_id_int_fkey;
ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_route_id_int_fkey;   
ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_service_id_int_fkey;  
ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_shape_id_int_fkey; 
    
do $$
begin
raise notice '==== Remove road nodes and sections indexes ===';
end
$$;

SELECT _drop_index('tempus', 'road_node', 'geom');
SELECT _drop_index('tempus', 'road_section', 'geom');
SELECT _drop_index('tempus', 'road_section', 'node_from');
SELECT _drop_index('tempus', 'road_section', 'node_to');

DROP TRIGGER IF EXISTS delete_isolated_road_nodes ON tempus.road_section;
DROP TRIGGER IF EXISTS retrace_section ON tempus_gtfs.stops;
DROP TRIGGER IF EXISTS delete_artificial_stop_road_section ON tempus_gtfs.stops;

do $$
begin
raise notice '==== Reset import schema ===';
end$$;

/* Drop import schema and recreate it */
DROP SCHEMA IF EXISTS %(temp_schema) CASCADE;
CREATE SCHEMA %(temp_schema);

/* Create PT tables in the tempus import schema for raw import of GTFS data */

do $$
begin
raise notice '==== Reset PT import tables ===';
end$$;

/* GTFS data tables */
DROP TABLE IF EXISTS %(temp_schema).feed_info;
CREATE TABLE %(temp_schema).feed_info
(
  feed_publisher_name character varying,
  feed_publisher_url character varying,
  feed_contact_email character varying,
  feed_contact_url character varying,
  feed_lang character varying,
  feed_start_date date,
  feed_end_date date,
  feed_version character varying
); 


DROP TABLE IF EXISTS %(temp_schema).agency;
CREATE TABLE %(temp_schema).agency (
    agency_id character varying,
    agency_name character varying NOT NULL,
    agency_url character varying NOT NULL,
    agency_timezone character varying NOT NULL,
    agency_lang character varying,
    agency_phone character varying,
    agency_fare_url character varying, 
    agency_email character varying
);

DROP TABLE IF EXISTS %(temp_schema).calendar;
CREATE TABLE %(temp_schema).calendar (
    service_id character varying NOT NULL,
    monday integer NOT NULL,
    tuesday integer NOT NULL,
    wednesday integer NOT NULL,
    thursday integer NOT NULL,
    friday integer NOT NULL,
    saturday integer NOT NULL,
    sunday integer NOT NULL,
    start_date character varying NOT NULL,
    end_date character varying NOT NULL
);

DROP TABLE IF EXISTS %(temp_schema).calendar_dates;
CREATE TABLE %(temp_schema).calendar_dates (
    service_id character varying NOT NULL,
    "date" character varying NOT NULL,
    exception_type character varying NOT NULL
);


DROP TABLE IF EXISTS %(temp_schema).fare_attributes; 
CREATE TABLE %(temp_schema).fare_attributes (
    fare_id character varying NOT NULL,
    price character varying NOT NULL,
    currency_type character varying NOT NULL,
    payment_method integer NOT NULL,
    transfers integer,
    agency_id character varying, 
    transfer_duration integer
);

DROP TABLE IF EXISTS %(temp_schema).fare_rules;
CREATE TABLE %(temp_schema).fare_rules (
    fare_id character varying NOT NULL,
    route_id character varying,
    origin_id character varying,
    destination_id character varying,
    contains_id character varying
);

DROP TABLE IF EXISTS %(temp_schema).frequencies;
CREATE TABLE %(temp_schema).frequencies (
    trip_id character varying NOT NULL,
    start_time character varying NOT NULL,
    end_time character varying NOT NULL,
    headway_secs integer NOT NULL
);

DROP TABLE IF EXISTS %(temp_schema).routes; 
CREATE TABLE %(temp_schema).routes (
    agency_id character varying,
    route_id character varying NOT NULL,
    route_short_name character varying,
    route_long_name character varying NOT NULL,
    route_desc character varying,
    route_type integer NOT NULL,
    route_url character varying,
    route_color character varying,
    route_text_color character varying
);

DROP TABLE IF EXISTS %(temp_schema).shapes;
CREATE TABLE %(temp_schema).shapes (
    shape_id character varying NOT NULL,
    shape_pt_lat double precision NOT NULL,
    shape_pt_lon double precision NOT NULL,
    shape_pt_sequence integer NOT NULL,
    shape_dist_traveled double precision,
    geom geometry(LinestringZ, 4326)
);

DROP TABLE IF EXISTS %(temp_schema).stop_times;
CREATE TABLE %(temp_schema).stop_times (
    trip_id character varying NOT NULL,
    arrival_time character varying NOT NULL,
    departure_time character varying NOT NULL,
    stop_id character varying NOT NULL,
    stop_sequence integer NOT NULL,
    stop_headsign character varying,
    pickup_type integer,
    drop_off_type integer,
    shape_dist_traveled integer, 
    timepoint integer
);

DROP TABLE IF EXISTS %(temp_schema).stops;
CREATE TABLE %(temp_schema).stops (
    stop_id character varying NOT NULL,
    stop_code character varying,
    stop_name character varying NOT NULL,
    stop_desc character varying,
    stop_lat double precision NOT NULL,
    stop_lon double precision NOT NULL,
    zone_id character varying,
    stop_url character varying,
    location_type integer,
    parent_station character varying,
    stop_timezone character varying,
    wheelchair_boarding integer, 
    geom geometry(PointZ, 4326)
);

DROP TABLE IF EXISTS %(temp_schema).trips;
CREATE TABLE %(temp_schema).trips (
    route_id character varying NOT NULL,
    service_id character varying NOT NULL,
    trip_id character varying NOT NULL,
    trip_headsign character varying,
    trip_short_name character varying,
    direction_id integer,
    block_id character varying,
    shape_id character varying,
    direction varchar,
    wheelchair_accessible integer,
    bikes_allowed integer
);


DROP TABLE IF EXISTS %(temp_schema).transfers;
CREATE TABLE %(temp_schema).transfers (
    from_stop_id character varying NOT NULL,
    to_stop_id character varying NOT NULL,
    transfer_type character varying NOT NULL,
    min_transfer_time character varying
);

CREATE OR REPLACE FUNCTION %(temp_schema).format_gtfs_time(text)
RETURNS integer AS 
$$
BEGIN
    return substr($1,1,2)::integer * 3600 + substr($1,4,2)::integer * 60 + substr($1,7,2)::integer;
END;
$$ 
LANGUAGE plpgsql; 



