
/* Create PT tables in the tempus import schema for raw import of GTFS data */

do $$
begin
raise notice '==== Reset PT import tables ===';
end$$;

/* GTFS data tables */
DROP TABLE IF EXISTS %(temp_schema).agency;
CREATE TABLE %(temp_schema).agency
(
  agency_id character varying,
  agency_name character varying,
  agency_url character varying,
  agency_timezone character varying,
  agency_lang character varying
);

DROP TABLE IF EXISTS %(temp_schema).calendar_dates;
CREATE TABLE %(temp_schema).calendar_dates
(
  service_id character varying,
  date date
);


DROP TABLE IF EXISTS %(temp_schema).fare_attributes; 
CREATE TABLE %(temp_schema).fare_attributes
(
  fare_id character varying,
  price double precision,
  currency_type character varying,
  payment_method integer,
  transfers integer,
  agency_id character varying,
  transfer_duration integer
);

DROP TABLE IF EXISTS %(temp_schema).fare_rules;
CREATE TABLE %(temp_schema).fare_rules
(
  fare_id character varying,
  route_id character varying,
  origin_id character varying,
  destination_id character varying,
  contains_id character varying
);

DROP TABLE IF EXISTS %(temp_schema).routes; 
CREATE TABLE %(temp_schema).routes (
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

DROP TABLE IF EXISTS %(temp_schema).shapes;
CREATE TABLE %(temp_schema).shapes (
  shape_id character varying,
  geom geometry(LineStringZ,4326)
);

DROP TABLE IF EXISTS %(temp_schema).stop_times;
CREATE TABLE %(temp_schema).stop_times (
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

DROP TABLE IF EXISTS %(temp_schema).stops;
CREATE TABLE %(temp_schema).stops (
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

DROP TABLE IF EXISTS %(temp_schema).trips;
CREATE TABLE %(temp_schema).trips (
  route_id text,
  service_id text,
  trip_id text,
  trip_headsign character varying,
  direction_id integer,
  block_id character varying,
  shape_id character varying
);


DROP TABLE IF EXISTS %(temp_schema).transfers;
CREATE TABLE %(temp_schema).transfers (
  from_stop_id text,
  to_stop_id text,
  transfer_type integer,
  min_transfer_time integer
);

DROP TABLE IF EXISTS %(temp_schema).sections;
CREATE TABLE %(temp_schema).sections (
  from_stop_id character varying,
  to_stop_id character varying,
  feed_id character varying,
  geom geometry(LineStringZ,4326),
  shape_id character varying
);



