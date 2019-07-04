
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
DROP SCHEMA IF EXISTS _tempus_import CASCADE;
CREATE SCHEMA _tempus_import;

/* Create PT tables in the tempus import schema for raw import of GTFS data */

do $$
begin
raise notice '==== Reset PT import tables ===';
end$$;

/* GTFS data tables */
DROP TABLE IF EXISTS _tempus_import.agency;
CREATE TABLE _tempus_import.agency
(
  agency_id character varying,
  agency_name character varying,
  agency_url character varying,
  agency_timezone character varying,
  agency_lang character varying
);

DROP TABLE IF EXISTS _tempus_import.calendar_dates;
CREATE TABLE _tempus_import.calendar_dates
(
  service_id character varying,
  date date
);


DROP TABLE IF EXISTS _tempus_import.fare_attributes; 
CREATE TABLE _tempus_import.fare_attributes
(
  fare_id character varying,
  price double precision,
  currency_type character varying,
  payment_method integer,
  transfers integer,
  agency_id character varying,
  transfer_duration integer
);

DROP TABLE IF EXISTS _tempus_import.fare_rules;
CREATE TABLE _tempus_import.fare_rules
(
  fare_id character varying,
  route_id character varying,
  origin_id character varying,
  destination_id character varying,
  contains_id character varying
);

DROP TABLE IF EXISTS _tempus_import.routes; 
CREATE TABLE _tempus_import.routes (
  route_id character varying,
  agency_id character varying,
  route_short_name character varying,
  route_long_name character varying,
  route_desc character varying,
  route_type integer,
  route_url character varying,
  route_color character varying,
  route_text_color character varying
);

DROP TABLE IF EXISTS _tempus_import.shapes;
CREATE TABLE _tempus_import.shapes (
  shape_id character varying,
  geom geometry(LineStringZ,4326)
);

DROP TABLE IF EXISTS _tempus_import.stop_times;
CREATE TABLE _tempus_import.stop_times (
  trip_id text,
  arrival_time integer,
  departure_time integer,
  stop_id text,
  stop_sequence integer,
  stop_headsign character varying,
  pickup_type integer,
  drop_off_type integer,
  shape_dist_traveled double precision
);

DROP TABLE IF EXISTS _tempus_import.stops;
CREATE TABLE _tempus_import.stops (
  stop_id text,
  parent_station_id character varying,
  location_type integer,
  stop_name character varying,
  stop_lat double precision,
  stop_lon double precision,
  wheelchair_boarding integer,
  stop_code character varying,
  stop_desc character varying,
  zone_id character varying,
  stop_url character varying,
  stop_timezone character varying,
  geom geometry(PointZ,4326),
  road_section_id bigint,
  abscissa_road_section double precision
);

DROP TABLE IF EXISTS _tempus_import.trips;
CREATE TABLE _tempus_import.trips (
  route_id text,
  service_id text,
  trip_id text,
  trip_headsign character varying,
  direction_id integer,
  block_id character varying,
  shape_id character varying
);


DROP TABLE IF EXISTS _tempus_import.transfers;
CREATE TABLE _tempus_import.transfers (
  from_stop_id text,
  to_stop_id text,
  transfer_type integer,
  min_transfer_time integer
);

DROP TABLE IF EXISTS _tempus_import.sections;
CREATE TABLE _tempus_import.sections (
  from_stop_id character varying,
  to_stop_id character varying,
  feed_id character varying,
  geom geometry(LineStringZ,4326),
  shape_id character varying
);



