-- Tempus Database schema: version 1.2
--

--
-- DROP and clean if needed
--
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

DROP SCHEMA IF EXISTS tempus CASCADE;
DROP SCHEMA IF EXISTS tempus_gtfs CASCADE;
DELETE FROM public.geometry_columns WHERE f_table_schema='tempus' or f_table_schema='tempus_gtfs';


do $$
begin
raise notice '==== Road tables ===';
end$$;

CREATE SCHEMA tempus;

CREATE TABLE tempus.traffic_rule
(
    id integer, 
    name character varying,
    PRIMARY KEY(id)
);

INSERT INTO tempus.traffic_rule(id, name)
VALUES (1, 'Walking');
INSERT INTO tempus.traffic_rule(id, name)
VALUES (2, 'Cycling');
INSERT INTO tempus.traffic_rule(id, name)
VALUES (4, 'Driving a private car');
INSERT INTO tempus.traffic_rule(id, name)
VALUES (8, 'Driving a taxi');
INSERT INTO tempus.traffic_rule(id, name)
VALUES (16, 'Driving a truck');
INSERT INTO tempus.traffic_rule(id, name)
VALUES (32, 'Driving a coach');


CREATE TABLE tempus.speed_rule
(
    id integer, 
    name character varying,
    PRIMARY KEY(id)
);

INSERT INTO tempus.speed_rule(id, name)
VALUES (1, 'Walking');
INSERT INTO tempus.speed_rule(id, name)
VALUES (2, 'Cycling');
INSERT INTO tempus.speed_rule(id, name)
VALUES (5, 'Driving a light vehicle');


CREATE TABLE tempus.toll_rule
(
    id integer, 
    name character varying,
    PRIMARY KEY(id)
);

INSERT INTO tempus.toll_rule(id, name)
VALUES (1, 'Class 1: light vehicles');
INSERT INTO tempus.toll_rule(id, name)
VALUES (2, 'Class 2: intermediary vehicles');
INSERT INTO tempus.toll_rule(id, name)
VALUES (4, 'Class 3: trucks and coaches with 2 wheel shafts');
INSERT INTO tempus.toll_rule(id, name)
VALUES (8, 'Class 4: trucks and coaches with more than 2 wheel shafts');
INSERT INTO tempus.toll_rule(id, name)
VALUES (16, 'Class 5: motorcycles, side-cars');

CREATE TABLE tempus.transport_mode
(
    id serial PRIMARY KEY,
    name varchar, -- Description of the mode
    public_transport boolean NOT NULL,
    gtfs_route_type integer, -- Reference to the equivalent GTFS codification (for PT only)
    traffic_rules integer, -- Binary composition of TransportModeTrafficRule
    speed_rule integer, -- TransportModeSpeedRule
    toll_rule integer, -- Binary composition of TransportModeToolRule
    engine_type integer, -- TransportModeEngine
    need_parking boolean,
    shared_vehicle boolean,
    return_shared_vehicle boolean
);

COMMENT ON TABLE tempus.transport_mode IS 'Available transport modes';
COMMENT ON COLUMN tempus.transport_mode.name IS 'Description of the mode';
COMMENT ON COLUMN tempus.transport_mode.traffic_rules IS 'Bitfield value: defines road traffic rules followed by the mode, NULL for PT modes';
COMMENT ON COLUMN tempus.transport_mode.gtfs_route_type IS 'Reference to the equivalent GTFS code (for PT only)';
COMMENT ON COLUMN tempus.transport_mode.speed_rule IS 'Defines the road speed rule followed by the mode, NULL for PT modes';
COMMENT ON COLUMN tempus.transport_mode.toll_rule IS 'Bitfield value: gives the toll rules followed by the mode, NULL for PT modes';
COMMENT ON COLUMN tempus.transport_mode.need_parking IS 'If vehicle needs to be parked, NULL for PT modes';
COMMENT ON COLUMN tempus.transport_mode.shared_vehicle IS 'If vehicule is shared and needs to be return at a/some stations at the end of the trip, NULL for PT modes';
COMMENT ON COLUMN tempus.transport_mode.return_shared_vehicle IS 'If vehicule is shared and needs to be returned to its initial station at the end of a loop, NULL for PT modes';
-- TODO Add a CHECK on parent_id related to id bitfield values

INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, traffic_rules, speed_rule, toll_rule, engine_type, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Walking',         'f', NULL, 1,  1, NULL, NULL, 'f', 'f', 'f');
INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, traffic_rules, speed_rule, toll_rule, engine_type, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private bicycle', 'f', NULL, 2,  2, NULL, NULL, 't', 'f', 'f');
INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, traffic_rules, speed_rule, toll_rule, engine_type, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private car',     'f', NULL, 4,  5, 1,    1,    't', 'f', 'f');
INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, traffic_rules, speed_rule, toll_rule, engine_type, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private car with no parking constraint',     'f', NULL, 4,  5, 1,    1,    'f', 'f', 'f');
INSERT INTO tempus.transport_mode(name, public_transport, gtfs_route_type, traffic_rules, speed_rule, toll_rule, engine_type, need_parking, shared_vehicle, return_shared_vehicle)
    VALUES ('Taxi',            'f', NULL, 8, 5, 1,    1,    'f', 'f', 'f');

CREATE TABLE tempus.road_validity_period
(
    id integer PRIMARY KEY,
    name varchar,
    monday boolean DEFAULT true,
    tuesday boolean DEFAULT true,
    wednesday boolean DEFAULT true,
    thursday boolean DEFAULT true,
    friday boolean DEFAULT true,
    saturday boolean DEFAULT true,
    sunday boolean DEFAULT true,
    bank_holiday boolean DEFAULT true,
    day_before_bank_holiday boolean DEFAULT true,
    holidays boolean DEFAULT true,
    day_before_holidays boolean DEFAULT true,
    start_date date,
    end_date date
);
COMMENT ON TABLE tempus.road_validity_period IS 'Periods during which road restrictions and speed profiles apply';
INSERT INTO tempus.road_validity_period VALUES (0, 'Always', true, true, true, true, true, true, true, true, true, true, true, NULL, NULL);

/*
CREATE TABLE tempus.seasonal_ticket
(
    id integer PRIMARY KEY, --bitfield
    name varchar NOT NULL,
    price double precision,
    people_concerned varchar
);
INSERT INTO tempus.seasonal_ticket VALUES (1, 'Shared bicycle day ticket', 1.5, 'everybody');
INSERT INTO tempus.seasonal_ticket VALUES (2, 'Shared bicycle week ticket', 5, 'everybody');
INSERT INTO tempus.seasonal_ticket VALUES (4, 'Shared bicycle year ticket', 25, 'everybody');



CREATE TABLE tempus.road_vehicle_fare_rule
(
    id integer PRIMARY KEY,
    name varchar NOT NULL,
    seasonal_ticket integer,  -- bitfield
    transport_type integer,
    price_per_km double precision,
    price_per_minute double precision,
    price_per_use double precision,
    min_minutes integer,
    max_mintes integer
    min_km integer,
    max_km integer,
    start_time time without time zone,
    end_time time without time zone
);

INSERT INTO tempus.road_vehicle_fare_rule VALUES (1, 'Shared bicycle first half an hour of use', 7, 0, 0, 0, 0, 30, NULL, NULL, NULL, NULL);
INSERT INTO tempus.road_vehicle_fare_rule VALUES (2, 'Shared bicycle second half an hour of use', 7, 0, 0, 1, 30, 60, NULL, NULL, NULL, NULL);
INSERT INTO tempus.road_vehicle_fare_rule VALUES (3, 'Shared bicycle third half an hour of use', 7, 0, 0, 2, 60, 90, NULL, NULL, NULL, NULL);
INSERT INTO tempus.road_vehicle_fare_rule VALUES (4, 'Shared bicycle fourth half an hour of use', 7, 0, 0, 2, 90, 120, NULL, NULL, NULL, NULL);


*/
--TODO: add a data model able to represent taxis and shared vehicles fare rules => be able to give marginal cost of transports for any user category (with or without subscription to transport services...)


CREATE TABLE tempus.bank_holiday
(
    calendar_date date PRIMARY KEY,
    name varchar
);
COMMENT ON TABLE tempus.bank_holiday IS 'Bank holiday list';

-- Function that is TRUE when the parameter date is a french bank holiday, FALSE otherwise
-- Algorithm based on the Easter day of each year
CREATE OR REPLACE FUNCTION tempus.french_bank_holiday(pdate date)
  RETURNS boolean AS
$BODY$
DECLARE
    lgA INTEGER;
    lG integer;
    lC integer;
    lD integer;
    lE integer;
    lH integer;
    lK integer;
    lP integer;
    lQ integer;
    lI integer;
    lB integer;
    lJ1 integer;
    lJ2 integer;
    lR integer;
    stDate VARCHAR(10);
    dtPaq DATE;
    blFerie integer;
    ferie boolean; 

BEGIN
    ferie = FALSE; 
    stDate := TO_CHAR(pDate, 'DDMM');
    -- Jours fériés fixes (1er janvier, 1er mai, 8 mai, 14 juillet, 15 août, 1er novembre, 11 novembre, 25 décembre)
    IF stDate IN ('0101','0105','0805','1407','1508','0111','1111','2512') THEN
        ferie=TRUE;
    END IF;

        -- Construction de la date du dimanche de P㲵es
        lgA := TO_CHAR(pDate, 'YYYY');
        lG := mod(lgA,19);
        lC := trunc(lgA / 100);
        lD := trunc(lC / 4);
        lE := trunc((8 * lC + 13) / 25);
        lH := mod((19 * lG + lC - lD - lE + 15),30);
        lK := trunc(lH / 28);
        lP := trunc(29 /(lH + 1));
        lQ := trunc((21 - lG) / 11);
        lI := (lK * lP * lQ - 1) * lK + lH;
        lB := trunc(lgA / 4) + lgA;
        lJ1 := lB + lI + 2 + lD - lC;
        lJ2 := mod(lJ1,7);
        lR := 28 + lI - lJ2;

        IF lR > 31 THEN
            dtPaq := to_date((lR-31)::character varying || '/04/' || lgA::character varying, 'dd/mm/yyyy');
        ELSE
            dtPaq := to_date(lR::character varying || '/03/' || lgA::character varying, 'dd/mm/yyyy');
        END IF;

    -- Jours fériés mobiles (lundi de pâques, ascension, lundi de Pentecôte)
    -- Pâques et pentecôte exclus puisqu'ils tombent tous les deux un dimanche.

        IF (pDate = dtPaq) OR (pDate = (dtPaq + 1)) OR (pDate = (dtPaq + 39)) OR (pDate = (dtPaq + 50)) THEN
            ferie=TRUE;
        END IF;
    
    RETURN ferie;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;

CREATE TABLE tempus.holidays
(
    id serial,
    name varchar,
    start_date date,
    end_date date
);
COMMENT ON TABLE tempus.holidays IS 'Holidays definition : can be modified to add new holidays periods. Take care to conform to the initial format. ';

--
-- Roads
-- NOTA: Consider look at OSM specification:
--       <http://wiki.openstreetmap.org/wiki/Map_Features>
--	 <http://wiki.openstreetmap.org/wiki/Tagging_samples/urban>
--       and
--       "Description des bases de donnees vectorielles routieres" DREAL NPdC
CREATE TABLE tempus.road_network
(
    id serial PRIMARY KEY, 
    name character varying UNIQUE,
    comment character varying
);

INSERT INTO tempus.road_network(id, name, comment)
VALUES (0,'artificial','Artificial road network used to connect PT stops and POI which are not placed on an already loaded road section'); 

CREATE TABLE tempus.road_node
(
    id bigint PRIMARY KEY,
    bifurcation boolean, -- total number of incident edges is > 2 
    geom Geometry(PointZ, 4326) NOT NULL,
    network_id integer REFERENCES tempus.road_network ON DELETE CASCADE ON UPDATE CASCADE,
    vendor_id character varying,
    chk boolean
);
COMMENT ON TABLE tempus.road_node IS 'Road nodes description';
COMMENT ON COLUMN tempus.road_node.bifurcation IS 'If true, total number of incident edges is > 2';
COMMENT ON COLUMN tempus.road_node.network_id IS 'ID of the original data source';
COMMENT ON COLUMN tempus.road_node.vendor_id IS 'ID of the road node in the original data source';

CREATE INDEX ON tempus.road_node USING btree(geom);
CREATE INDEX ON tempus.road_node(id);
CREATE INDEX ON tempus.road_node(network_id);

CREATE TABLE tempus.road_section
(
    id bigint PRIMARY KEY,
    vendor_id character varying, 
    road_type integer,
    node_from bigint NOT NULL REFERENCES tempus.road_node ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
    node_to bigint NOT NULL REFERENCES tempus.road_node ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE INITIALLY IMMEDIATE,
    traffic_rules_ft smallint NOT NULL, -- References tempus.road_traffic_rule => bitfield value
    traffic_rules_tf smallint NOT NULL, -- References tempus.road_traffic_rule => bitfield value
    length double precision NOT NULL, -- in meters
    car_speed_limit double precision, -- in km/h
    road_name varchar,
    lane integer,
    roundabout boolean,
    bridge boolean,
    tunnel boolean,
    ramp boolean, -- or sliproads
    tollway boolean, 
    geom Geometry(LinestringZ, 4326), 
    network_id integer REFERENCES tempus.road_network ON DELETE CASCADE ON UPDATE CASCADE, 
    lane_ft integer,
    lane_tf integer,
    chk boolean
);
COMMENT ON TABLE tempus.road_section IS 'Road sections description';
COMMENT ON COLUMN tempus.road_section.road_type IS '1: fast links between urban areas, 2: links between 1 level links, heavy traffic with lower speeds, 3: local links with heavy traffic, 4: low traffic, 5: transfers between PT stops/POI';
COMMENT ON COLUMN tempus.road_section.traffic_rules_ft IS 'Bitfield value giving allowed traffic rules for direction from -> to';
COMMENT ON COLUMN tempus.road_section.traffic_rules_tf IS 'Bitfield value giving allowed traffic rules for direction to -> from';
COMMENT ON COLUMN tempus.road_section.length IS 'In meters';
COMMENT ON COLUMN tempus.road_section.car_speed_limit IS 'In km/h';
COMMENT ON COLUMN tempus.road_section.ramp IS 'Or sliproad';
CREATE INDEX ON tempus.road_section(id);
CREATE INDEX ON tempus.road_section(network_id);
CREATE INDEX ON tempus.road_section(node_from);
CREATE INDEX ON tempus.road_section(node_to);


CREATE TABLE tempus.road_daily_profile
(
    profile_id integer NOT NULL,
    begin_time integer NOT NULL,
    speed_rule integer NOT NULL,
    end_time  integer NOt NULL,
    average_speed double precision NOT NULL, -- In km/h
    PRIMARY KEY (profile_id, speed_rule, begin_time)
);
COMMENT ON COLUMN tempus.road_daily_profile.begin_time IS 'When the period begins. Number of minutes since midnight';
COMMENT ON COLUMN tempus.road_daily_profile.end_time IS 'When the period ends. Number of minutes since midnight';
COMMENT ON COLUMN tempus.road_daily_profile.speed_rule IS 'Speed rule: car, truck, bike, etc.';
COMMENT ON COLUMN tempus.road_daily_profile.average_speed IS 'Speed value in km/h';

CREATE TABLE tempus.road_section_speed
(
    road_section_id bigint NOT NULL REFERENCES tempus.road_section ON DELETE CASCADE ON UPDATE CASCADE,
    period_id integer NOT NULL REFERENCES tempus.road_validity_period ON DELETE CASCADE ON UPDATE CASCADE,
    profile_id integer NOT NULL, -- road_daily_profile
    PRIMARY KEY (road_section_id, period_id, profile_id)
);
COMMENT ON TABLE tempus.road_section_speed IS 'Speed, vehicle types and validity period associated to road sections';
COMMENT ON COLUMN tempus.road_section_speed.period_id IS '0 if always applies';
COMMENT ON COLUMN tempus.road_section_speed.profile_id IS 'Reference to tempus.road_daily_profile';


CREATE TABLE tempus.road_restriction
(
    id bigserial PRIMARY KEY,
    network_id integer,
    vendor_id character varying, 
    sections bigint[] NOT NULL
);
COMMENT ON TABLE tempus.road_restriction IS 'Road sections lists submitted to a restriction';
COMMENT ON COLUMN tempus.road_restriction.sections IS 'Involved road sections ID, not always forming a path';

CREATE TABLE tempus.road_restriction_time_penalty
(
    restriction_id bigint NOT NULL REFERENCES tempus.road_restriction ON DELETE CASCADE ON UPDATE CASCADE,
    period_id integer NOt NULL REFERENCES tempus.road_validity_period ON DELETE CASCADE ON UPDATE CASCADE, -- 0 if always applies
    traffic_rules integer NOT NULL, -- References tempus.road_traffic_rule => bitfield value
    time_value double precision NOT NULL,
    PRIMARY KEY (restriction_id, period_id, traffic_rules)
);
COMMENT ON TABLE tempus.road_restriction_time_penalty IS 'Time penalty (including infinite values for forbidden movements) applied to road restrictions';
COMMENT ON COLUMN tempus.road_restriction_time_penalty.period_id IS '0 if always applies';
COMMENT ON COLUMN tempus.road_restriction_time_penalty.traffic_rules IS 'References tempus.transport_mode_traffic_rule => Bitfield value';
COMMENT ON COLUMN tempus.road_restriction_time_penalty.time_value IS 'In minutes';


CREATE TABLE tempus.road_restriction_toll
(
    restriction_id bigint NOT NULL REFERENCES tempus.road_restriction ON DELETE CASCADE ON UPDATE CASCADE,
    period_id integer NOT NULL REFERENCES tempus.road_validity_period ON DELETE CASCADE ON UPDATE CASCADE, -- NULL if always applies
    toll_rules integer NOT NULL, -- References tempus.road_toll_rule => bitfield value
    toll_value double precision,
    PRIMARY KEY (restriction_id, period_id, toll_rules)
);
COMMENT ON TABLE tempus.road_restriction_toll IS 'Tolls applied to road restrictions';
COMMENT ON COLUMN tempus.road_restriction_toll.period_id IS '0 if always applies';
COMMENT ON COLUMN tempus.road_restriction_toll.toll_rules IS 'References tempus.transport_mode_toll_rule => Bitfield value, defines the type of vehicles to which it applies';
COMMENT ON COLUMN tempus.road_restriction_toll.toll_value IS 'In euros, can be NULL if unknown';


DROP VIEW IF EXISTS tempus.view_forbidden_movements;
CREATE OR REPLACE VIEW tempus.view_forbidden_movements AS
 SELECT road_restriction.id,
    road_restriction.network_id, 
    road_restriction.sections,
    st_union(road_section.geom) AS geom,
    max(road_restriction_time_penalty.traffic_rules) AS traffic_rules
   FROM tempus.road_section,
    tempus.road_restriction,
    tempus.road_restriction_time_penalty
  WHERE (road_section.id = ANY (road_restriction.sections)) AND road_restriction_time_penalty.restriction_id = road_restriction.id AND road_restriction_time_penalty.time_value = 'Infinity'::double precision
  GROUP BY road_restriction.id, road_restriction.sections;

DROP VIEW IF EXISTS tempus.view_penalized_movements_cars;
CREATE VIEW tempus.view_penalized_movements_cars AS 
 SELECT road_restriction.id,
    road_restriction.network_id, 
    road_restriction.sections,
    st_union(road_section.geom) AS geom,
    max(road_restriction_time_penalty.traffic_rules) AS traffic_rules,
    max(road_restriction_time_penalty.time_value) AS time_penalty
   FROM tempus.road_section,
    tempus.road_restriction,
    tempus.road_restriction_time_penalty
  WHERE (road_section.id = ANY (road_restriction.sections)) AND road_restriction_time_penalty.restriction_id = road_restriction.id AND (traffic_rules::integer & 4)>0
  GROUP BY road_restriction.id, road_restriction.sections;

DROP VIEW IF EXISTS tempus.view_penalized_movements_cyclists;
CREATE VIEW tempus.view_penalized_movements_cyclists AS 
 SELECT road_restriction.id,
    road_restriction.network_id, 
    road_restriction.sections,
    st_union(road_section.geom) AS geom,
    max(road_restriction_time_penalty.traffic_rules) AS traffic_rules,
    max(road_restriction_time_penalty.time_value) AS time_penalty
   FROM tempus.road_section,
    tempus.road_restriction,
    tempus.road_restriction_time_penalty
  WHERE (road_section.id = ANY (road_restriction.sections)) AND road_restriction_time_penalty.restriction_id = road_restriction.id AND (traffic_rules::integer & 2)>0
  GROUP BY road_restriction.id, road_restriction.sections;

------
-- Views for road network visualization : network accessible with each mode
------

CREATE VIEW tempus.road_section_pedestrians AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id,
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 1) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 1) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf, 
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 1) > 0 OR (road_section.traffic_rules_tf::integer & 1) > 0;


 CREATE VIEW tempus.road_section_cyclists AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id, 
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 2) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 2) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf, 
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 2) > 0 OR (road_section.traffic_rules_tf::integer & 2) > 0;

  
 CREATE VIEW tempus.road_section_cars AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id, 
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 4) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 4) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf,
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0;  

 CREATE VIEW tempus.road_section_taxis AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id, 
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 8) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 8) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf,
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 8) > 0 OR (road_section.traffic_rules_tf::integer & 8) > 0;  

  
 CREATE VIEW tempus.road_section_trucks AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id, 
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 16) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 16) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf,
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 8) > 0 OR (road_section.traffic_rules_tf::integer & 16) > 0;  

 CREATE VIEW tempus.road_section_coaches AS 
 SELECT road_section.id::integer AS id,
    road_section.vendor_id,
    road_section.network_id, 
    road_section.road_type,
    road_section.node_from,
    road_section.node_to,
    (road_section.traffic_rules_ft::integer & 32) > 0 AS ft,
    (road_section.traffic_rules_tf::integer & 32) > 0 AS tf,
    road_section.length,
    road_section.car_speed_limit,
    road_section.road_name,
    road_section.lane_ft,
    road_section.lane_tf,
    road_section.roundabout,
    road_section.bridge,
    road_section.tunnel,
    road_section.ramp,
    road_section.tollway,
    road_section.geom, 
    road_section.chk
   FROM tempus.road_section
  WHERE (road_section.traffic_rules_ft::integer & 32) > 0 OR (road_section.traffic_rules_tf::integer & 32) > 0;  
  


do $$
begin
raise notice '==== POI tables ===';
end$$;

CREATE TABLE tempus.poi_source
(
    id serial PRIMARY KEY, 
    name character varying UNIQUE,
    comment character varying
); 
COMMENT ON TABLE tempus.poi_source IS 'Points of Interest sources';

CREATE TABLE tempus.poi_type
(
    id serial PRIMARY KEY, 
    name character varying
); 
COMMENT ON TABLE tempus.poi_source IS 'Points of Interest types';

INSERT INTO tempus.poi_type(id, name)
VALUES(1, 'Car parks');
INSERT INTO tempus.poi_type(id, name)
VALUES(2, 'Shared cars rental point');
INSERT INTO tempus.poi_type(id, name)
VALUES(3, 'Bicycle park');
INSERT INTO tempus.poi_type(id, name)
VALUES(4, 'Shared bicycles rental point');
INSERT INTO tempus.poi_type(id, name)
VALUES(5, 'User POI'); 

CREATE TABLE tempus.poi
(
	id serial PRIMARY KEY,
    source_id integer REFERENCES tempus.poi_source ON DELETE CASCADE ON UPDATE CASCADE, 
	poi_type integer CHECK (poi_type is null OR (poi_type>0 AND poi_type<6)),
	name varchar,
    parking_transport_modes integer[] NOT NULL,
	road_section_id bigint REFERENCES tempus.road_section ON DELETE NO ACTION ON UPDATE CASCADE,
	abscissa_road_section double precision CHECK (abscissa_road_section IS NULL OR (abscissa_road_section >= 0 AND abscissa_road_section <= 1)), 
	geom Geometry(PointZ, 4326)
);
COMMENT ON TABLE tempus.poi IS 'Points of Interest';

do $$
begin
raise notice '==== PT tables ===';
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


CREATE TABLE tempus_gtfs.calendar (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        service_id VARCHAR NOT NULL, 
        id serial, 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, service_id)
);
CREATE INDEX ON tempus_gtfs.calendar(id);


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
        service_id_int integer REFERENCES tempus_gtfs.calendar(id) ON DELETE CASCADE ON UPDATE CASCADE, 
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


CREATE TABLE tempus_gtfs.shapes (
        feed_id VARCHAR NOT NULL REFERENCES tempus_gtfs.feed_info(feed_id) ON UPDATE CASCADE ON DELETE CASCADE,
        shape_id VARCHAR NOT NULL, 
        id serial, 
        geom Geometry(LineStringZ, 4326), 
        PRIMARY KEY(id), 
        UNIQUE(feed_id, shape_id)
); 
CREATE INDEX ON tempus_gtfs.shapes USING gist(geom);


CREATE TABLE tempus_gtfs.shape_pts (
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
CREATE INDEX ON tempus_gtfs.shape_pts(feed_id, shape_id);


CREATE TABLE tempus_gtfs.sections (
	id serial, 
    stop_from integer NOT NULL REFERENCES tempus_gtfs.stops(id) ON DELETE CASCADE ON UPDATE CASCADE,
	stop_to integer NOT NULL REFERENCES tempus_gtfs.stops(id) ON DELETE CASCADE ON UPDATE CASCADE,
	feed_id integer REFERENCES tempus_gtfs.feed_info(id) ON DELETE CASCADE ON UPDATE CASCADE,
	geom Geometry(LineStringZ, 4326), 
	shape_id_int integer REFERENCES tempus_gtfs.shapes(id) ON DELETE CASCADE ON UPDATE CASCADE,
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
        service_id_int integer REFERENCES tempus_gtfs.calendar(id) ON DELETE CASCADE ON UPDATE CASCADE, 
        shape_id_int integer REFERENCES tempus_gtfs.shapes(id) ON DELETE CASCADE ON UPDATE CASCADE, 
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


--
-- Utilitary functions
--

-- find the closest road_section, then select the closest endpoint
DROP FUNCTION IF EXISTS tempus.road_node_id_from_coordinates(float8, float8); 
CREATE OR REPLACE FUNCTION tempus.road_node_id_from_coordinates( float8, float8 ) 
RETURNS bigint AS
$$
    WITH rs AS (
        SELECT id, node_from, node_to FROM tempus.road_section
        ORDER BY geom <-> st_setsrid(st_point($1, $2), 4326)
        LIMIT 1
    )
    SELECT CASE WHEN st_distance( p1.geom, st_setsrid(st_point($1,$2), 4326)) < st_distance( p2.geom, st_setsrid(st_point($1,$2), 4326)) THEN p1.id ELSE p2.id END
    FROM rs, tempus.road_node p1, tempus.road_node p2
    WHERE rs.node_from = p1.id AND rs.node_to = p2.id
$$
LANGUAGE SQL;

DROP FUNCTION IF EXISTS tempus.road_node_id_from_coordinates_and_modes(float8, float8, int[]);
CREATE OR REPLACE FUNCTION tempus.road_node_id_from_coordinates_and_modes( float8, float8, int[] = array[1] ) 
RETURNS bigint AS 
$$
    WITH rs AS (
        SELECT road_section.id, node_from, node_to FROM tempus.road_section, tempus.transport_mode
        WHERE transport_mode.id IN (SELECT unnest($3)) and
          (transport_mode.traffic_rules & traffic_rules_ft = transport_mode.traffic_rules
           OR transport_mode.traffic_rules & traffic_rules_tf = transport_mode.traffic_rules)
        ORDER BY geom <-> st_setsrid(st_point($1, $2), 4326)
        LIMIT 1
    )
    select case when st_distance( p1.geom, st_setsrid(st_point($1,$2), 4326)) < st_distance( p2.geom, st_setsrid(st_point($1,$2), 4326)) then p1.id else p2.id end
    from rs, tempus.road_node as p1, tempus.road_node as p2
    where rs.node_from = p1.id and rs.node_to = p2.id
$$
LANGUAGE SQL;
  
DROP FUNCTION IF EXISTS tempus.array_search(anyelement, anyarray);
CREATE OR REPLACE FUNCTION tempus.array_search(needle anyelement, haystack anyarray)
  RETURNS integer AS
$BODY$
    SELECT i
      FROM generate_subscripts($2, 1) AS i
     WHERE $2[i] = $1
  ORDER BY i
$BODY$
LANGUAGE sql STABLE
COST 100;

--
-- graph topology checks
--
CREATE VIEW tempus.chk_inconsistent_road_sections AS
(
    SELECT road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, car_speed_limit, road_name, lane, roundabout, bridge, tunnel, ramp, tollway, rs.geom
    FROM
      tempus.road_section as rs
      LEFT JOIN tempus.road_node as rn1 ON (rs.node_from = rn1.id)
      LEFT JOIN tempus.road_node as rn2 ON (rs.node_to = rn2.id)
    WHERE rn1.id is null OR rn2.id is null
);

CREATE VIEW tempus.chk_cycles AS
(
    SELECT road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, car_speed_limit, road_name, lane, roundabout, bridge, tunnel, ramp, tollway, geom
    FROM tempus.road_section 
    WHERE node_from = node_to
);

CREATE VIEW tempus.chk_double_sections AS
(
    SELECT rs1.id as rs1_id, rs2.id as rs2_id
    FROM tempus.road_section rs1, tempus.road_section rs2
    WHERE rs1.id <> rs2.id
      AND
      (
        ( rs1.node_from = rs2.node_to
          and
          rs1.node_to = rs2.node_from
          and
          rs1.traffic_rules_ft = rs2.traffic_rules_tf
          and
          rs1.traffic_rules_tf = rs2.traffic_rules_ft
        )
      OR
        ( rs1.node_from = rs2.node_from
          and
          rs1.node_to = rs2.node_to
          and
          rs1.traffic_rules_ft = rs2.traffic_rules_ft
          and
          rs1.traffic_rules_tf = rs2.traffic_rules_tf
        )
      )
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

--
-- convenience view for data loading from core
--

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

CREATE OR REPLACE FUNCTION notice(msg text, data anyelement)
RETURNS anyelement AS
$$
BEGIN
  RAISE notice 'notice % %', msg, data;
  RETURN data;
END;
$$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS _drop_index(text, text, text);
CREATE FUNCTION _drop_index(schema_name text, table_name text, col text) returns void AS
$$
DECLARE
  idx_name text;
BEGIN
    FOR idx_name IN 
        SELECT relname
        FROM pg_index as idx JOIN pg_class as i ON (i.oid = idx.indexrelid)
                             JOIN pg_am as am ON (i.relam = am.oid)
        WHERE idx.indrelid::regclass = (schema_name || '.' || table_name)::regclass
              AND col IN (SELECT pg_get_indexdef(idx.indexrelid, k + 1, true) FROM generate_subscripts(idx.indkey, 1) as k)
    LOOP
        EXECUTE 'drop index ' || schema_name || '.' || idx_name;
    END LOOP;
END;
$$
LANGUAGE plpgsql;


-- Subsets (old)

/*CREATE TABLE tempus.subset
(
	id serial PRIMARY KEY,
    schema_name text NOT NULL, 
    geom Geometry(Polygon, 4326)
);

CREATE OR REPLACE FUNCTION tempus.create_subset(msubset text, polygon text) RETURNS void AS $$
DECLARE
    mdefinition text;
    -- declarations
BEGIN
  EXECUTE format('DROP SCHEMA IF EXISTS %s CASCADE', msubset);
  EXECUTE format('delete from geometry_columns where f_table_schema=''%s''', msubset);
  EXECUTE format('create schema %s', msubset);

  -- road nodes
  EXECUTE format('create table %s.road_node as select rn.* from tempus.road_node as rn where st_intersects( ''' || polygon || '''::geometry, rn.geom )', msubset);
  -- road sections
  EXECUTE format( 'create table %s.road_section as ' ||
	'select rs.* from tempus.road_section as rs ' ||
	'where ' ||
        'node_from in (select id from %1$s.road_node) ' ||
        'and node_to in (select id from %1$s.road_node)', msubset);
  -- pt stops
  EXECUTE format( 'create table %s.pt_stop as ' ||
                   'select pt.* from tempus.pt_stop as pt, %1$s.road_section as rs where road_section_id = rs.id', msubset );

  -- pt section
  EXECUTE format( 'create table %s.pt_section as ' ||
		'select pt.* from tempus.pt_section as pt ' ||
	        'where stop_from in (select id from %1$s.pt_stop) ' ||
                'and stop_to in (select id from %1$s.pt_stop)', msubset );

  -- pt stop time
  EXECUTE format( 'create table %s.pt_stop_time as ' ||
	'select st.* from tempus.pt_stop_time as st, %1$s.pt_stop as stop where stop_id = stop.id', msubset );

  -- poi
  EXECUTE format( 'create table %s.poi as ' ||
                  'select poi.* from tempus.poi as poi, %1$s.road_section as rs where road_section_id = rs.id', msubset );

  -- road_restriction
  EXECUTE format( 'create table %s.road_restriction as ' ||
         'select distinct rr.id, rr.sections from tempus.road_restriction as rr, %1$s.road_section as rs ' ||
         'where rs.id in (select unnest(sections) from tempus.road_restriction where id=rr.id)', msubset );

  EXECUTE format( 'create table %s.road_restriction_time_penalty as ' ||
         'select rrtp.* from tempus.road_restriction_time_penalty as rrtp, ' ||
         '%1$s.road_restriction as rr where restriction_id = rr.id', msubset );

  -- pt_trip
  EXECUTE format( 'create table %s.pt_trip as ' ||
                  'select * from tempus.pt_trip where id in (select distinct trip_id from %1$s.pt_stop_time union select trip_id from tempus.pt_frequency)', msubset);
  -- pt_frequency
  EXECUTE format( 'create table %s.pt_frequency as select * from tempus.pt_frequency', msubset );

  -- pt_route
  EXECUTE format( 'create table %s.pt_route as select * from tempus.pt_route where id in (select distinct route_id from %1$s.pt_trip)', msubset );

  -- pt_calendar
  EXECUTE format( 'create table %s.pt_calendar as select * from tempus.pt_calendar where service_id in (select distinct service_id from %1$s.pt_trip)', msubset );
  EXECUTE format( 'create table %s.pt_calendar_date as select * from tempus.pt_calendar_date where service_id in (select distinct service_id from %1$s.pt_trip)', msubset );

  -- pt_network
  EXECUTE format( 'create table %s.pt_network as select * from tempus.pt_network where id in (select distinct network_id from %1$s.pt_section)', msubset );
  -- pt_agency
  EXECUTE format( 'create table %s.pt_agency as select * from tempus.pt_agency where network_id in (select distinct id from %1$s.pt_network)', msubset );
  -- pt_zone
  EXECUTE format( 'create table %s.pt_zone as select * from tempus.pt_zone where network_id in (select distinct id from %1$s.pt_network)', msubset );
  -- pt_fare_rule
  EXECUTE format( 'create table %s.pt_fare_rule as select * from tempus.pt_fare_rule where route_id in (select id from %1$s.pt_route)', msubset );
  -- pt_fare_attribute
  EXECUTE format( 'create table %s.pt_fare_attribute as select * from tempus.pt_fare_attribute', msubset );

  -- transport_mode
  EXECUTE format( 'create table %s.transport_mode as select * from tempus.transport_mode', msubset );

  -- forbidden movements view
  SELECT replace(definition, 'tempus.', msubset || '.') into mdefinition from pg_views where schemaname='tempus' and viewname='view_forbidden_movements';
  EXECUTE 'create view ' || msubset || '.view_forbidden_movements as ' || mdefinition;

  -- update_pt_views
  select replace(prosrc, 'tempus.', msubset || '.') into mdefinition
     from pg_proc, pg_namespace where pg_proc.pronamespace = pg_namespace.oid and proname='update_pt_views' and nspname='tempus';
  EXECUTE 'create function ' || msubset || '.update_pt_views() returns void as $' || '$' || mdefinition || '$' || '$ language plpgsql';
  EXECUTE 'SELECT ' || msubset || '.update_pt_views()';

  DELETE FROM tempus.subset WHERE schema_name=msubset;
  INSERT INTO tempus.subset (schema_name, geom) VALUES (msubset, polygon::geometry);
END;
$$ LANGUAGE plpgsql;*/



  