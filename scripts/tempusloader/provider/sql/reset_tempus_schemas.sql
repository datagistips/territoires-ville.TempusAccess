-- Tempus Database schema: version 2
--
--
-- DROP and clean if needed
--

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

DROP LANGUAGE IF EXISTS plpython3u CASCADE;
CREATE LANGUAGE plpython3u;
CREATE EXTENSION IF NOT EXISTS pgtempus;

DROP SCHEMA IF EXISTS tempus_tmode CASCADE;
DROP SCHEMA IF EXISTS tempus_calendar CASCADE;
DROP SCHEMA IF EXISTS tempus_cost CASCADE;
DROP SCHEMA IF EXISTS tempus_road CASCADE;
DROP SCHEMA IF EXISTS tempus_pt CASCADE;
DROP SCHEMA IF EXISTS tempus_intermod CASCADE;
DROP SCHEMA IF EXISTS tempus_access CASCADE;
DROP SCHEMA IF EXISTS tempus_zoning CASCADE;
DROP SCHEMA IF EXISTS tempus_stored_results CASCADE;

DELETE FROM public.geometry_columns 
WHERE f_table_schema='tempus_tmode' 
   OR f_table_schema='tempus_calendar'
   OR f_table_schema='tempus_cost'
   OR f_table_schema='tempus_road' 
   OR f_table_schema='tempus_pt' 
   OR f_table_schema='tempus_intermod' 
   OR f_table_schema='tempus_access' 
   OR f_table_schema='tempus_zoning' 
   OR f_table_schema='tempus_stored_results';

CREATE SCHEMA tempus_tmode;
COMMENT ON SCHEMA tempus_tmode IS 'Transport modes data and functions';

CREATE SCHEMA tempus_calendar;
COMMENT ON SCHEMA tempus_calendar IS 'Calendar (days periods) data and functions';

CREATE SCHEMA tempus_cost;
COMMENT ON SCHEMA tempus_cost IS 'Cost data and functions';

CREATE SCHEMA tempus_road;
COMMENT ON SCHEMA tempus_road IS 'Road network data and functions';

CREATE SCHEMA tempus_pt;
COMMENT ON SCHEMA tempus_pt IS 'Public transport network data and functions';

CREATE SCHEMA tempus_intermod;
COMMENT ON SCHEMA tempus_intermod IS 'Intermodality graph data';

CREATE SCHEMA tempus_access;
COMMENT ON SCHEMA tempus_access IS 'Tables and functions used by the TempusAccess QGIS plugin';

CREATE SCHEMA tempus_zoning;
COMMENT ON SCHEMA tempus_zoning IS 'Zoning data';

CREATE SCHEMA tempus_stored_results;
COMMENT ON SCHEMA tempus_stored_results IS 'Paths and accessibility indicators stored Tempus results';


DO
$$
BEGIN
	raise notice '==== Utilitary functions ===';
END
$$;

DROP FUNCTION IF EXISTS array_search(anyelement, anyarray);
CREATE OR REPLACE FUNCTION array_search(needle anyelement, haystack anyarray)
  RETURNS integer AS
$BODY$
    SELECT i
      FROM generate_subscripts($2, 1) AS i
     WHERE $2[i] = $1
  ORDER BY i
$BODY$
LANGUAGE sql STABLE
COST 100;

DO
$$
BEGIN
	raise notice '==== Transport modes definition ===';
END
$$;

-- Vehicle engine type
CREATE TABLE tempus_tmode.engine_type
(
    id integer PRIMARY KEY, 
    name character varying
); 
COMMENT ON TABLE tempus_tmode.engine_type IS 'Engine types that can be used to calculate environnemental costs. ';

-- Traffic rules: bitfield
CREATE TABLE tempus_tmode.road_traffic_rule
(
    id integer PRIMARY KEY, 
    name_en character varying, 
    name_fr character varying
);

INSERT INTO tempus_tmode.road_traffic_rule
VALUES (1, 'Walking', 'Marche');
INSERT INTO tempus_tmode.road_traffic_rule
VALUES (2, 'Cycling', 'Vélo');
INSERT INTO tempus_tmode.road_traffic_rule
VALUES (4, 'Driving a private car', 'Véhicule particulier');
INSERT INTO tempus_tmode.road_traffic_rule
VALUES (8, 'Driving a taxi', 'Taxi');
INSERT INTO tempus_tmode.road_traffic_rule
VALUES (16, 'Driving a truck', 'Camion');
INSERT INTO tempus_tmode.road_traffic_rule
VALUES (32, 'Driving a coach', 'Bus ou autocar');

-- Speed rules: bitfield
CREATE TABLE tempus_tmode.road_speed_rule
(
    id integer PRIMARY KEY, 
    name_en character varying, 
    name_fr character varying
);

INSERT INTO tempus_tmode.road_speed_rule
VALUES (1, 'Walking', 'Marche');
INSERT INTO tempus_tmode.road_speed_rule
VALUES (2, 'Cycling', 'Vélo');
INSERT INTO tempus_tmode.road_speed_rule
VALUES (4, 'Driving a light vehicle', 'Véhicule léger');
INSERT INTO tempus_tmode.road_speed_rule
VALUES (8, 'Driving a truck or a coach', 'Bus, autocar ou camion');

-- Toll rules: bitfield
CREATE TABLE tempus_tmode.road_toll_rule
(
    id integer PRIMARY KEY, 
    name_en character varying, 
    name_fr character varying
);
INSERT INTO tempus_tmode.road_toll_rule
VALUES (1, 'Class 1', 'Classe 1');
INSERT INTO tempus_tmode.road_toll_rule
VALUES (2, 'Class 2', 'Classe 2');
INSERT INTO tempus_tmode.road_toll_rule
VALUES (3, 'Class 3', 'Classe 3');
INSERT INTO tempus_tmode.road_toll_rule
VALUES (4, 'Class 4', 'Classe 4');
INSERT INTO tempus_tmode.road_toll_rule
VALUES (5, 'Class 5', 'Classe 5');

CREATE TABLE tempus_tmode.pt_type
(
    id integer PRIMARY KEY, 
    name_en character varying,
    name_fr character varying
);
COMMENT ON TABLE tempus_tmode.pt_type IS 'Public transport vehicle type';

INSERT INTO tempus_tmode.pt_type
VALUES (0, 'Tram, street car', 'Tramway, métro léger');
INSERT INTO tempus_tmode.pt_type
VALUES (1, 'Subway, metro', 'Métro');
INSERT INTO tempus_tmode.pt_type
VALUES (2, 'Train', 'Train');
INSERT INTO tempus_tmode.pt_type
VALUES (3, 'Short or long-distance bus', 'Bus ou autocars');
INSERT INTO tempus_tmode.pt_type
VALUES (4, 'Ferry', 'Ferry');
INSERT INTO tempus_tmode.pt_type
VALUES (5, 'Cable car', 'Tramway à traction par câble');
INSERT INTO tempus_tmode.pt_type
VALUES (6, 'Cable gondola', 'Transport par câble suspendu');
INSERT INTO tempus_tmode.pt_type
VALUES (7, 'Funicular', 'Funiculaire');


-- Transport modes
CREATE TABLE tempus_tmode.transport_mode
(
    id serial PRIMARY KEY,
    name_en varchar,
    name_fr character varying, 
    pt_type_id integer REFERENCES tempus_tmode.pt_type ON UPDATE CASCADE,
    road_traffic_rule_id integer REFERENCES tempus_tmode.road_traffic_rule ON UPDATE CASCADE,
    road_speed_rule_id integer REFERENCES tempus_tmode.road_speed_rule ON UPDATE CASCADE,
    road_toll_rule_id integer REFERENCES tempus_tmode.road_toll_rule ON UPDATE CASCADE,
    engine_type_id integer REFERENCES tempus_tmode.engine_type ON UPDATE CASCADE,
    need_parking boolean,
    shared_vehicle boolean,
    return_shared_vehicle boolean, 
    vehicles_ip_ids bigint[], 
    parks_ip_ids bigint[]
);
COMMENT ON TABLE tempus_tmode.transport_mode IS 'Available transport modes';
COMMENT ON COLUMN tempus_tmode.transport_mode.name_en IS 'Description of the mode (English)'; 
COMMENT ON COLUMN tempus_tmode.transport_mode.name_fr IS 'Description of the mode (French)';
COMMENT ON COLUMN tempus_tmode.transport_mode.pt_type_id IS 'Reference to the Public Transport vehicle type';
COMMENT ON COLUMN tempus_tmode.transport_mode.road_traffic_rule_id IS 'Bitfield value: defines road traffic rules followed by the mode, NULL for PT modes. Default classes are defined. Gives TransportModeTrafficRule variable in C++. ';
COMMENT ON COLUMN tempus_tmode.transport_mode.road_speed_rule_id IS 'Defines the road speed rule followed by the mode, NULL for PT modes. Defaut classes are defined. Gives TransportModeSpeedRule variable in C++.';
COMMENT ON COLUMN tempus_tmode.transport_mode.road_toll_rule_id IS 'Bitfield value: gives the toll rules followed by the mode, NULL for PT modes. Classes must be defined by users. Gives TransportModeTollRule variable in C++.';
COMMENT ON COLUMN tempus_tmode.transport_mode.engine_type_id IS 'Vehicle engine type. Classes must be defined by users. Gives TransportModeEngine variable in C++.';
COMMENT ON COLUMN tempus_tmode.transport_mode.need_parking IS 'If vehicle needs to be parked, NULL for PT modes.';
COMMENT ON COLUMN tempus_tmode.transport_mode.shared_vehicle IS 'If vehicule is shared and needs to be return at a/some stations at the end of the trip, NULL for PT modes.';
COMMENT ON COLUMN tempus_tmode.transport_mode.return_shared_vehicle IS 'If vehicule is shared and needs to be returned to its initial station at the end of a loop, NULL for PT modes.';
COMMENT ON COLUMN tempus_tmode.transport_mode.vehicles_ip_ids IS 'List of intermodality point IDs where a vehicle is available for this mode (not NULL only if need_parking = TRUE).';
COMMENT ON COLUMN tempus_tmode.transport_mode.parks_ip_ids IS 'List of intermodality point IDs where a park is available for this mode (not NULL only if need_parking = TRUE).';

INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, road_traffic_rule_id, road_speed_rule_id, road_toll_rule_id, engine_type_id, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Walking', 'Marche', 1,  1, NULL, NULL, 'f', 'f', 'f');
INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, road_traffic_rule_id, road_speed_rule_id, road_toll_rule_id, engine_type_id, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private bicycle', 'Vélo privé', 2,  2, NULL, NULL, 't', 'f', 'f');
INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, road_traffic_rule_id, road_speed_rule_id, road_toll_rule_id, engine_type_id, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private car', 'Voiture privée', 4,  4, 1,    NULL,    't', 'f', 'f');
INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, road_traffic_rule_id, road_speed_rule_id, road_toll_rule_id, engine_type_id, need_parking, shared_vehicle, return_shared_vehicle)
	VALUES ('Private car with no parking constraint', 'Voiture privée sans contrainte de stationnement', 4,  4, 1, NULL, 'f', 'f', 'f');
INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, road_traffic_rule_id, road_speed_rule_id, road_toll_rule_id, engine_type_id, need_parking, shared_vehicle, return_shared_vehicle)
    VALUES ('Taxi', 'Taxi', 8, 4, 1, NULL,'f', 'f', 'f');
INSERT INTO tempus_tmode.transport_mode(name_en, name_fr, pt_type_id)
SELECT name_en, name_fr, id
FROM tempus_tmode.pt_type; 

DO
$$
BEGIN
	raise notice '==== Calendars definition ==='; 
END
$$;

CREATE TABLE tempus_calendar.days_period
(
    id integer PRIMARY KEY,
    original_id character varying, 
    name_en varchar,
    name_fr character varying,
    monday boolean,
    tuesday boolean,
    wednesday boolean,
    thursday boolean,
    friday boolean,
    saturday boolean,
    sunday boolean,
    bank_holiday boolean,
    day_before_bank_holiday boolean,
    holiday boolean,
    day_before_holiday boolean,
    start_date date,
    end_date date, 
    days date[]
);
COMMENT ON TABLE tempus_calendar.days_period IS 'Periods / list of days during which road restrictions, speed profiles and PT services apply';
INSERT INTO tempus_calendar.days_period VALUES (0, 'Always', 'Toujours', True, True, True, True, True, True, True, True, True, True, True, NULL, NULL, NULL);

CREATE TABLE tempus_calendar.bank_holiday
(
    calendar_date date PRIMARY KEY,
    name varchar
);
COMMENT ON TABLE tempus_calendar.bank_holiday IS 'Bank holiday list: by default, this table is not used. To use it, redefine tempus_calendar.bank_holiday_function.';

-- Function that is TRUE when the parameter date is a french bank holiday, FALSE otherwise
-- Algorithm based on the Easter day of each year
CREATE OR REPLACE FUNCTION tempus_calendar.bank_holiday_function(calendar_date date)
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
    bHol boolean; 

BEGIN
    bHol = FALSE; 
    stDate := TO_CHAR(calendar_date, 'DDMM');
    -- Fixed bank holidays
    IF stDate IN ('0101','0105','0805','1407','1508','0111','1111','2512') THEN
        bHol=TRUE;
    END IF;

        -- date of Easter sunday
        lgA := TO_CHAR(calendar_date, 'YYYY');
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

    -- Mobile bank holidays (Easter Monday, Ascension, Pentecôte Monday)
        IF (calendar_date = dtPaq) OR (calendar_date = (dtPaq + 1)) OR (calendar_date = (dtPaq + 39)) OR (calendar_date = (dtPaq + 50)) THEN
            bHol=TRUE;
        END IF;
    
    RETURN bHol;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
COMMENT ON FUNCTION tempus_calendar.bank_holiday_function(date) IS 'Default bank holiday function corresponds to the french bank holiday function: can be replaced by any bank_holiday_function, for example simply reading values from table tempus_calendar.bank_holiday.';

CREATE TABLE tempus_calendar.holiday_period
(
    id serial,
    name varchar,
    start_date date,
    end_date date
);
COMMENT ON TABLE tempus_calendar.holiday_period IS 'Holidays definition : can be modified to add new holidays periods. Never used directly by C++. ';

CREATE OR REPLACE FUNCTION tempus_calendar.date_is_in_days_period(calendar_date date, days_period_id integer)
RETURNS boolean AS
$BODY$
DECLARE
    day_of_week_test boolean;
    holiday_test boolean;
BEGIN
    day_of_week_test = (
        (extract('dow' FROM calendar_date) = 1 AND (SELECT sunday FROM tempus_calendar.days_period WHERE id= $2) = True) 
        OR (extract('dow' FROM calendar_date) = 2 AND (SELECT monday FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (extract('dow' FROM calendar_date) = 3 AND (SELECT tuesday FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (extract('dow' FROM calendar_date) = 4 AND (SELECT wednesday FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (extract('dow' FROM calendar_date) = 5 AND (SELECT thursday FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (extract('dow' FROM calendar_date) = 6 AND (SELECT friday FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (calendar_dates <@ (SELECT calendar_dates FROM tempus_calendar.days_period WHERE id = $2) = True)
    );
    
    holiday_test = (
        ((SELECT tempus_calendar.bank_holiday_function(calendar_date)) = (SELECT bank_holiday FROM tempus_calendary.days_period WHERE id = $2))
        OR ((SELECT tempus_calendar.bank_holiday_function(calendar_date + '1 day'::interval)) = (SELECT day_before_bank_holiday FROM tempus_calendary.days_period WHERE id = $2))
        OR (((SELECT count(*) FROM tempus_calendar.holiday_period WHERE start_date <= calendar_date AND end_date >= calendar_date)>0) = (SELECT day_before_holiday FROM tempus_calendar.days_period))
        OR (((SELECT count(*) FROM tempus_calendar.holiday_period WHERE start_date <= calendar_date + '1 day'::interval AND end_date >= calendar_date + '1 day'::interval)>0) = (SELECT day_before_bank_holiday FROM tempus_calendar.days_period))
		OR (calendar_dates <@ (SELECT calendar_dates FROM tempus_calendar.days_period WHERE id = $2) = True)
        OR (calendar_dates <@ (SELECT calendar_dates FROM tempus_calendar.days_period WHERE id = $2) = True)        
    );
    
    RETURN day_of_week_test AND holiday_test;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
COMMENT ON FUNCTION tempus_calendar.date_is_in_days_period(date, integer) IS 'Function which says if a given date belongs to a days period';

CREATE TABLE tempus_calendar.time_period
(
    id integer PRIMARY KEY, 
    name_en character varying, 
    name_fr character varying,
    days_period_id integer[],
    start_time time
);
COMMENT ON TABLE tempus_calendar.time_period IS 'Time periods used for cost definition.';

INSERT INTO tempus_calendar.time_period(id, name_en, name_fr, days_period_id, start_time)
VALUES (1, 'Always', 'Tout le temps', NULL, '00:00:00');

DO
$$
BEGIN
	RAISE NOTICE '==== Cost functions definition ===';
END
$$;

CREATE TABLE tempus_cost.parameter
(
    id serial, 
    name_en character varying, 
    name_fr character varying,
    value double precision
);
COMMENT ON TABLE tempus_cost.parameter IS 'User defined parameters called by generalized cost functions. Never directly used by C++.';

INSERT INTO tempus_cost.parameter(name_en, name_fr, value)
VALUES ('Mean fuel price/L', 'Coût moyen du litre de carburant', 1.55);
INSERT INTO tempus_cost.parameter(name_en, name_fr, value)
VALUES ('Mean fuel consomption/km', 'Consommation moyenne au kilomètre', 0.065);


CREATE TABLE tempus_cost.speed_function
(
    id integer PRIMARY KEY,
    name_en character varying,
    name_fr character varying
);
COMMENT ON TABLE tempus_cost.speed_function IS 'Speed functions that can be attributed to road sections. Never read by C++.';


CREATE TABLE tempus_cost.time_function
(
    id integer PRIMARY KEY, 
    name_fr character varying,
    name_en character varying
);
COMMENT ON TABLE tempus_cost.time_function IS 'Time functions that can be attributed to road restrictions. Never read by C++.';

INSERT INTO tempus_cost.time_function(id, name_en, name_fr)
VALUES(1, 'Forbidden movements', 'Mouvements interdits');


CREATE TABLE tempus_cost.env_cost_function
(
    id integer PRIMARY KEY, 
    name_en character varying,
    name_fr character varying
);
COMMENT ON TABLE tempus_cost.env_cost_function IS 'Environnemental cost functions that can be attributed to road or public transport sections. Never read by C++.';


CREATE TABLE tempus_cost.toll_function
(
    id integer PRIMARY KEY,
    name_en character varying, 
    name_fr character varying
);
COMMENT ON TABLE tempus_cost.toll_function IS 'Toll functions that can be attributed to road restrictions. Never read by C++.';


CREATE TABLE tempus_cost.speed_function_value
(
    speed_function_id integer NOT NULL REFERENCES tempus_cost.speed_function,
    time_period_id integer NOT NULL REFERENCES tempus_calendar.time_period,
    speed_value double precision NOT NULL, 
    PRIMARY KEY (speed_function_id, time_period_id)
);
COMMENT ON TABLE tempus_cost.speed_function_value IS 'Speed function definition. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_cost.speed_function_value.time_period_id IS 'References the time period.';
COMMENT ON COLUMN tempus_cost.speed_function_value.speed_value IS 'Speed value in km/h';


CREATE TABLE tempus_cost.time_function_value
(
    time_function_id integer NOT NULL REFERENCES tempus_cost.time_function,
    time_period_id integer NOT NULL REFERENCES tempus_calendar.time_period,
    time_value double precision NOT NULL, 
    PRIMARY KEY (time_function_id, time_period_id)
);
COMMENT ON TABLE tempus_cost.time_function_value IS 'Time penalties functions definition. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_cost.time_function_value.time_period_id IS 'References the time period.';
COMMENT ON COLUMN tempus_cost.time_function_value.time_value IS 'Time value in minutes';

INSERT INTO tempus_cost.time_function_value(time_function_id, time_period_id, time_value)
VALUES (1, 1, 'Infinity');


CREATE TABLE tempus_cost.env_cost_function_value
(
    env_cost_function_id integer NOT NULL REFERENCES tempus_cost.env_cost_function,
    time_period_id integer NOT NULL REFERENCES tempus_calendar.time_period,
    cost_value double precision NOT NULL, 
    PRIMARY KEY (env_cost_function_id, time_period_id)
);
COMMENT ON TABLE tempus_cost.env_cost_function_value IS 'Environnemental costs (consommations or emissions) functions definition. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_cost.env_cost_function_value.cost_value IS 'Environnemental cost value';


CREATE TABLE tempus_cost.toll_function_value
(
    toll_function_id integer NOT NULL REFERENCES tempus_cost.toll_function,
    time_period_id integer NOT NULL REFERENCES tempus_calendar.time_period,
    toll_value double precision NOT NULL, -- In km/h
    PRIMARY KEY (toll_function_id, time_period_id)
);
COMMENT ON TABLE tempus_cost.toll_function_value IS 'Toll functions definition. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_cost.toll_function_value.time_period_id IS 'References the time period.';
COMMENT ON COLUMN tempus_cost.toll_function_value.toll_value IS 'Toll value';


CREATE TABLE tempus_cost.shared_vehicle_user_group
(
    id serial PRIMARY KEY, 
    name_en character varying, 
    name_fr character varying
);
CREATE INDEX ON tempus_cost.shared_vehicle_user_group(id);
COMMENT ON TABLE tempus_cost.shared_vehicle_user_group IS 'Shared vehicles user groups that can be called to define a cost function for shared vehicles. Never called by C++.';


CREATE TABLE tempus_cost.shared_vehicle_fare 
(
    id serial PRIMARY KEY,
    tmode_id integer REFERENCES tempus_tmode.transport_mode ON UPDATE CASCADE,
    shared_vehicle_user_group_id integer REFERENCES tempus_cost.shared_vehicle_user_group ON UPDATE CASCADE ON DELETE CASCADE,
    price_per_use double precision,
    price_per_min double precision,
    price_per_km double precision,
    max_time_min integer, 
    max_dist_km integer
);
CREATE INDEX ON tempus_cost.shared_vehicle_fare(id);
COMMENT ON TABLE tempus_cost.shared_vehicle_fare IS 'Shared vehicles fare classes (can depend on user type, number of trips, distance or time). Can be used to define shared vehicles cost function. Never called by C++.';


CREATE TABLE tempus_cost.pt_fare_zone (
        id serial PRIMARY KEY, 
        original_id character varying,
        name character varying
);
CREATE INDEX ON tempus_cost.pt_fare_zone(id);
COMMENT ON TABLE tempus_cost.pt_fare_zone IS 'Public transport geographical fare zones.'; 


CREATE TABLE tempus_cost.pt_user_group (
        id serial PRIMARY KEY, 
        name character varying
);
CREATE INDEX ON tempus_cost.pt_user_group(id);
COMMENT ON TABLE tempus_cost.pt_user_group IS 'PT user groups definition for fare calculation. Never called by C++.';


CREATE TABLE tempus_cost.pt_fare (
        id serial PRIMARY KEY,
        original_id VARCHAR NOT NULL,
        pt_user_group_id integer REFERENCES tempus_cost.pt_user_group ON UPDATE CASCADE ON DELETE CASCADE,
        pt_zone_id_from integer REFERENCES tempus_cost.pt_fare_zone ON UPDATE CASCADE ON DELETE CASCADE,
        pt_zone_id_to integer REFERENCES tempus_cost.pt_fare_zone ON UPDATE CASCADE ON DELETE CASCADE,
        allowed_transfers integer,
        max_transfer_duration integer, 
        max_trip_duration integer,
        name character varying,
        price double precision NOT NULL
);
CREATE INDEX ON tempus_cost.pt_fare(id);
COMMENT ON TABLE tempus_cost.pt_fare IS 'Public transport fare (can depend on user type, number of transfers, origin and destination points, origin and destination zones, transfers or trip duration). Can be used to define public transport cost function. Never called by C++.';


CREATE TYPE tempus_cost.cost_value AS
(
    start_time integer,
    value double precision
);

CREATE OR REPLACE FUNCTION tempus_cost.road_section_tt_function (
                                                                    section_id bigint, 
                                                                    dir_ft boolean, 
                                                                    transport_mode_id integer, 
                                                                    calendar_date date, 
                                                                    start_time time, 
                                                                    duration interval
                                                                )
RETURNS SETOF tempus_cost.cost_value 
AS
$BODY$
	DECLARE
		cost tempus_cost.cost_value;
	BEGIN
		RETURN QUERY
		SELECT extract(EPOCH FROM time_period.start_time::interval)/60::integer as start_time, 
              (section_speed.value * 1000 / section.length) as value			   
		FROM tempus_road.section JOIN tempus_road.section_speed ON (section_speed.section_id = section.id)
                                 JOIN tempus_tmode.transport_mode ON (transport_mode.speed_rule & section_speed.speed_rules > 0)
                                 JOIN tempus_cost.speed_function_value ON (section_speed.speed_function_id = speed_function_value.speed_function_id)
                                 JOIN tempus_calendar.time_period ON (time_period.id = speed_function_value.time_period_id)
		WHERE section.id = $1 
          AND section_speed.dir_ft = $2 
          AND transport_mode.id = $3 
          AND (SELECT tempus_calendar.date_is_in_days_period($4, days_period.id))
          AND time_period.start_time >= $5
          AND time_period.start_time + (duration::character varying + ' hours')::interval <= time_period.start_time
        ;
	END;
$BODY$
LANGUAGE plpgsql;
COMMENT ON FUNCTION tempus_cost.road_section_tt_function(bigint, boolean, integer, date, time, interval) IS 'Road travel time function (default road cost function)'; 



CREATE FUNCTION tempus_cost.road_restriction_cost_function (
                                                                restriction_id bigint, 
                                                                transport_mode_id integer, 
                                                                calendar_date date, 
                                                                duration double precision
                                                           )
RETURNS double precision AS
$BODY$
DECLARE
    cost double precision;
BEGIN
    SELECT INTO cost
        
    
    FROM 
    
    
    RETURN cost;
END;
$BODY$
LANGUAGE plpgsql; 


CREATE FUNCTION tempus_cost.pt_section_cost_function (
                                                        section_id bigint, 
                                                        calendar_date date, 
                                                        duration double precision
                                                     )
RETURNS double precision AS
$BODY$
DECLARE
    cost double precision;
BEGIN
    SELECT INTO cost
        
    
    FROM 
    
    
    RETURN cost;
END;
$BODY$
  LANGUAGE plpgsql; 

  

do $$
begin
raise notice '==== Road networks definition ===';
end$$;

CREATE TABLE tempus_road.network
(
    id serial PRIMARY KEY, 
    name character varying UNIQUE,
    comment character varying
);

INSERT INTO tempus_road.network(id, name, comment)
VALUES (0,'artificial','Artificial road network used to connect PT stops and POI which are not placed on an already loaded road section'); 


CREATE TABLE tempus_road.node
(
    id bigint PRIMARY KEY,
    original_id character varying, 
    network_id integer REFERENCES tempus_road.network ON DELETE CASCADE ON UPDATE CASCADE,
    geom Geometry(PointZ, 4326) NOT NULL
);
COMMENT ON TABLE tempus_road.node IS 'Road nodes description. Directly read by C++.';
COMMENT ON COLUMN tempus_road.node.network_id IS 'ID of the original data source';
COMMENT ON COLUMN tempus_road.node.original_id IS 'ID of the road node in the original data source';

CREATE INDEX ON tempus_road.node USING btree(geom);
CREATE INDEX ON tempus_road.node(id);
CREATE INDEX ON tempus_road.node(network_id);


CREATE TABLE tempus_road.section_type
(
    id integer PRIMARY KEY, 
    name character varying
);
COMMENT ON TABLE tempus_road.section_type IS 'Road section types, can be used to define a network hierarchy.';

CREATE TABLE tempus_road.section
(
    id bigint PRIMARY KEY,
    original_id character varying, 
    network_id integer REFERENCES tempus_road.network ON DELETE CASCADE ON UPDATE CASCADE, 
    type_id integer NOT NULL REFERENCES tempus_road.section_type ON UPDATE CASCADE,
    node_id_from bigint NOT NULL REFERENCES tempus_road.node ON DELETE CASCADE ON UPDATE CASCADE,
    node_id_to bigint NOT NULL REFERENCES tempus_road.node ON DELETE CASCADE ON UPDATE CASCADE,
    traffic_rules_ft smallint NOT NULL, 
    traffic_rules_tf smallint NOT NULL, 
    length double precision NOT NULL,
    car_speed_limit double precision,
    road_name varchar,
    lanes_ft integer,
    lanes_tf integer,
    geom Geometry(LinestringZ, 4326)
);
COMMENT ON TABLE tempus_road.section IS 'Road sections description. Directly read by C++.';
COMMENT ON COLUMN tempus_road.section.type_id IS 'Road section hierarchy class';
COMMENT ON COLUMN tempus_road.section.traffic_rules_ft IS 'Bitfield value giving allowed traffic rules for direction from -> to';
COMMENT ON COLUMN tempus_road.section.traffic_rules_tf IS 'Bitfield value giving allowed traffic rules for direction to -> from';
COMMENT ON COLUMN tempus_road.section.length IS 'Length in meters';
COMMENT ON COLUMN tempus_road.section.car_speed_limit IS 'Car speed limit in km/h';
COMMENT ON COLUMN tempus_road.section.road_name IS 'Either street name or road number';
COMMENT ON COLUMN tempus_road.section.lanes_ft IS 'Number of lanes for direction from->to during one hour. ';
COMMENT ON COLUMN tempus_road.section.lanes_tf IS 'Number of lanes for direction to->from during one hour. ';
COMMENT ON COLUMN tempus_road.section.network_id IS 'Network id';

CREATE INDEX ON tempus_road.section(id);
CREATE INDEX ON tempus_road.section(network_id);
CREATE INDEX ON tempus_road.section(node_id_from);
CREATE INDEX ON tempus_road.section(node_id_to);


CREATE OR REPLACE FUNCTION tempus_road.delete_isolated_road_nodes_f()
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM tempus_road.node
    WHERE OLD.node_id_from = road_node.id OR OLD.node_id_to = road_node.id AND id IN
    (
        SELECT road_node.id
        FROM tempus_road.node
        LEFT JOIN tempus_road.section AS s1
        ON s1.node_id_from = road_node.id
        LEFT JOIN tempus_road.section AS s2
        ON s2.node_id_to = road_node.id
        WHERE s1.node_id_from is null AND s2.node_id_to is null
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_isolated_road_nodes
AFTER DELETE ON tempus_road.section
FOR EACH ROW EXECUTE PROCEDURE tempus_road.delete_isolated_road_nodes_f();


CREATE TABLE tempus_road.restriction
(
    id bigserial PRIMARY KEY,
    original_id character varying, 
    network_id integer,
    sections bigint[] NOT NULL
);
COMMENT ON TABLE tempus_road.restriction IS 'Road sections submitted to a restriction. Directly read by C++.';
COMMENT ON COLUMN tempus_road.restriction.sections IS 'Involved road sections ID, not always forming a path';


CREATE TABLE tempus_road.restriction_toll
(
    restriction_id bigint NOT NULL REFERENCES tempus_road.restriction ON DELETE CASCADE ON UPDATE CASCADE,
    period_id integer NOT NULL REFERENCES tempus_calendar.days_period ON DELETE CASCADE ON UPDATE CASCADE, 
    toll_rules integer NOT NULL,
    toll_function_id integer NOT NULL REFERENCES tempus_cost.toll_function ON UPDATE CASCADE,
    PRIMARY KEY (restriction_id, period_id, toll_rules)
);
COMMENT ON TABLE tempus_road.restriction_toll IS 'Toll applied to road restrictions. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_road.restriction_toll.period_id IS '0 if always applies';
COMMENT ON COLUMN tempus_road.restriction_toll.toll_rules IS 'References tempus_road.tmode_traffic_rule => Bitfield value';
COMMENT ON COLUMN tempus_road.restriction_toll.toll_function_id IS 'Toll function ID';

CREATE TABLE tempus_road.restriction_time
(
    restriction_id bigint NOT NULL REFERENCES tempus_road.restriction ON DELETE CASCADE ON UPDATE CASCADE,
    period_id integer NOT NULL REFERENCES tempus_calendar.days_period ON DELETE CASCADE ON UPDATE CASCADE, 
    traffic_rules integer NOT NULL,
    time_function_id integer NOT NULL REFERENCES tempus_cost.time_function ON UPDATE CASCADE,
    PRIMARY KEY (restriction_id, period_id, traffic_rules)
);
COMMENT ON TABLE tempus_road.restriction_time IS 'Time penalty (including infinite values for forbidden movements) applied to road restrictions. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_road.restriction_time.period_id IS 'Days period ID when the time penalty is applied. 0 if always applied. ';
COMMENT ON COLUMN tempus_road.restriction_time.traffic_rules IS 'References tempus_road.tmode_traffic_rule => Bitfield value';
COMMENT ON COLUMN tempus_road.restriction_time.time_function_id IS 'Time penalty function ID';

CREATE TABLE tempus_road.section_speed
(
    section_id bigint NOT NULL REFERENCES tempus_road.section ON DELETE CASCADE ON UPDATE CASCADE,
    dir_ft boolean, 
    period_id integer NOT NULL REFERENCES tempus_calendar.days_period ON DELETE CASCADE ON UPDATE CASCADE,
    speed_rules integer NOT NULL, 
    speed_function_id integer NOT NULL, 
    PRIMARY KEY (section_id, dir_ft, period_id, speed_function_id)
);
COMMENT ON TABLE tempus_road.section_speed IS 'Speed, vehicle types and days period associated to road sections. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_road.section_speed.period_id IS 'Days period ID when the speed is applied. 0 if always applied';
COMMENT ON COLUMN tempus_road.section_speed.speed_rules IS 'Speed rules concerned by the speed value';
COMMENT ON COLUMN tempus_road.section_speed.speed_function_id IS 'Speed function ID';

CREATE TABLE tempus_road.section_env_cost
(
    section_id bigint NOT NULL REFERENCES tempus_road.section ON DELETE CASCADE ON UPDATE CASCADE,
    dir_ft boolean, 
    period_id integer NOT NULL REFERENCES tempus_calendar.days_period ON DELETE CASCADE ON UPDATE CASCADE,
    engine_type integer NOT NULL, 
    env_cost_function_id integer NOT NULL REFERENCES tempus_cost.env_cost_function ON UPDATE CASCADE, 
    PRIMARY KEY (section_id, dir_ft, period_id, engine_type, env_cost_function_id)
);
COMMENT ON TABLE tempus_road.section_env_cost IS 'Speed, vehicle types and days period associated to road sections. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_road.section_env_cost.period_id IS 'Days period ID when the environnemental cost is applied. 0 if always applied';
COMMENT ON COLUMN tempus_road.section_env_cost.engine_type IS 'Engine types concerned by the cost value';
COMMENT ON COLUMN tempus_road.section_env_cost.env_cost_function_id IS 'Environnemental cost function ID';

-- Views used for map display
CREATE VIEW tempus_road.view_pedestrians_section AS 
SELECT id, 
       network_id, 
       type_id, 
       node_id_from, 
       node_id_to, 
       (traffic_rules_ft::integer & 1) > 0 AS ft, 
       (traffic_rules_tf::integer & 1) > 0 AS tf,
       length,
       car_speed_limit,
       road_name,
       geom
FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 1) > 0 OR (traffic_rules_tf::integer & 1) > 0;
COMMENT ON VIEW tempus_road.view_pedestrians_section IS 'Pedestrians network. Only used for map display.'; 

CREATE VIEW tempus_road.view_cyclists_section AS 
SELECT id, 
       network_id, 
       type_id, 
       node_id_from, 
       node_id_to, 
       (traffic_rules_ft::integer & 2) > 0 AS ft, 
       (traffic_rules_tf::integer & 2) > 0 AS tf,
       length,
       car_speed_limit,
       road_name,
       geom
FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 2) > 0 OR (traffic_rules_tf::integer & 2) > 0;
COMMENT ON VIEW tempus_road.view_cyclists_section IS 'Cyclists network. Only used for map display.'; 

CREATE VIEW tempus_road.view_cars_section AS 
SELECT id, 
       network_id, 
       type_id, 
       node_id_from, 
       node_id_to, 
       (traffic_rules_ft::integer & 4) > 0 AS ft, 
       (traffic_rules_tf::integer & 4) > 0 AS tf,
       length,
       car_speed_limit,
       road_name,
       lanes_ft,
       lanes_tf,
       geom
FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 4) > 0 OR (section.traffic_rules_tf::integer & 4) > 0;  
COMMENT ON VIEW tempus_road.view_cars_section IS 'Cars network. Only used for map display.'; 

CREATE VIEW tempus_road.view_taxis_section AS 
SELECT id, 
       network_id, 
       type_id, 
       node_id_from, 
       node_id_to, 
       (traffic_rules_ft::integer & 8) > 0 AS ft, 
       (traffic_rules_tf::integer & 8) > 0 AS tf,
       length,
       car_speed_limit,
       road_name,
       geom
FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 8) > 0 OR (traffic_rules_tf::integer & 8) > 0;  
COMMENT ON VIEW tempus_road.view_taxis_section IS 'Taxis network. Only used for map display.'; 
  
 CREATE VIEW tempus_road.view_trucks_section AS 
 SELECT id, 
        network_id, 
        type_id, 
        node_id_from, 
        node_id_to, 
        (traffic_rules_ft::integer & 16) > 0 AS ft, 
        (traffic_rules_tf::integer & 16) > 0 AS tf,
        length,
        car_speed_limit,
        road_name,
        lanes_ft,
        lanes_tf,
        geom
FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 16) > 0 OR (traffic_rules_tf::integer & 16) > 0; 
COMMENT ON VIEW tempus_road.view_trucks_section IS 'Trucks network. Only used for map display.'; 

CREATE VIEW tempus_road.view_coaches_section AS 
SELECT id, 
        network_id, 
        type_id, 
        node_id_from, 
        node_id_to, 
        (traffic_rules_ft::integer & 32) > 0 AS ft, 
        (traffic_rules_tf::integer & 32) > 0 AS tf,
        length,
        car_speed_limit,
        road_name,
        geom
   FROM tempus_road.section
WHERE (traffic_rules_ft::integer & 32) > 0 OR (traffic_rules_tf::integer & 32) > 0;  
COMMENT ON VIEW tempus_road.view_coaches_section IS 'Coaches network. Only used for map display.';

CREATE VIEW tempus_road.view_cars_forbidden_movement AS
SELECT restriction.id,
       restriction.network_id, 
       restriction.sections,
       st_union(section.geom) AS geom
FROM tempus_road.section,
     tempus_road.restriction,
     tempus_road.restriction_time
WHERE (section.id = ANY (restriction.sections)) AND restriction_time.restriction_id = restriction.id AND restriction_time.time_function_id = 1 AND (traffic_rules::integer & 4) > 0
GROUP BY restriction.id, restriction.sections;
COMMENT ON VIEW tempus_road.view_cars_forbidden_movement IS 'Cars forbidden movements. Only used for map display.';

CREATE VIEW tempus_road.view_taxis_forbidden_movement AS
SELECT restriction.id,
       restriction.network_id, 
       restriction.sections,
       st_union(section.geom) AS geom
FROM tempus_road.section,
     tempus_road.restriction,
     tempus_road.restriction_time
WHERE (section.id = ANY (restriction.sections)) AND restriction_time.restriction_id = restriction.id AND restriction_time.time_function_id = 1 AND (traffic_rules::integer & 8) > 0
GROUP BY restriction.id, restriction.sections;
COMMENT ON VIEW tempus_road.view_taxis_forbidden_movement IS 'Taxis forbidden movements. Only used for map display.';

CREATE VIEW tempus_road.view_trucks_forbidden_movement AS
SELECT restriction.id,
       restriction.network_id, 
       restriction.sections,
       st_union(section.geom) AS geom
FROM tempus_road.section,
     tempus_road.restriction,
     tempus_road.restriction_time
WHERE (section.id = ANY (restriction.sections)) AND restriction_time.restriction_id = restriction.id AND restriction_time.time_function_id = 1 AND (traffic_rules::integer & 16) > 0
GROUP BY restriction.id, restriction.sections;
COMMENT ON VIEW tempus_road.view_trucks_forbidden_movement IS 'Trucks forbidden movements. Only used for map display.';

-- Utilitary functions
CREATE OR REPLACE FUNCTION tempus_road.node_id_from_coordinates( float8, float8 ) 
RETURNS bigint AS
$$
    WITH rs AS (
        SELECT id, node_id_from, node_id_to 
        FROM tempus_road.section
        ORDER BY geom <-> st_setsrid(st_point($1, $2), 4326)
        LIMIT 1
    )
    SELECT CASE WHEN st_distance( p1.geom, st_setsrid(st_point($1,$2), 4326)) < st_distance( p2.geom, st_setsrid(st_point($1,$2), 4326)) THEN p1.id ELSE p2.id END
    FROM rs, tempus_road.node p1, tempus_road.node p2
    WHERE rs.node_id_from = p1.id AND rs.node_id_to = p2.id
$$
LANGUAGE SQL;

DROP FUNCTION IF EXISTS tempus_road.node_id_from_coordinates_and_modes(float8, float8, int[]);
CREATE OR REPLACE FUNCTION tempus_road.node_id_from_coordinates_and_modes( float8, float8, int[] = array[1] ) 
RETURNS bigint AS 
$$
    WITH rs AS (
        SELECT section.id, node_id_from, node_id_to 
        FROM tempus_road.section, tempus_tmode.transport_mode
        WHERE transport_mode.id IN (SELECT unnest($3)) and
          (transport_mode.road_traffic_rule_id & traffic_rules_ft = transport_mode.road_traffic_rule_id
           OR transport_mode.road_traffic_rule_id & traffic_rules_tf = transport_mode.road_traffic_rule_id)
        ORDER BY geom <-> st_setsrid(st_point($1, $2), 4326)
        LIMIT 1
    )
    select case when st_distance( p1.geom, st_setsrid(st_point($1,$2), 4326)) < st_distance( p2.geom, st_setsrid(st_point($1,$2), 4326)) then p1.id else p2.id end
    from rs, tempus_road.node as p1, tempus_road.node as p2
    where rs.node_id_from = p1.id and rs.node_id_to = p2.id
$$
LANGUAGE SQL;


-- Views operating graph topology checks
CREATE VIEW tempus_road.view_chk_inconsistent_sections AS
(
    SELECT rs.*
    FROM
      tempus_road.section as rs
      LEFT JOIN tempus_road.node as rn1 ON (rs.node_id_from = rn1.id)
      LEFT JOIN tempus_road.node as rn2 ON (rs.node_id_to = rn2.id)
    WHERE rn1.id is null OR rn2.id is null
);

CREATE VIEW tempus_road.chk_cycles AS
(
    SELECT *
    FROM tempus_road.section 
    WHERE node_id_from = node_id_to
);

CREATE VIEW tempus_road.view_chk_double_sections AS
(
    SELECT rs1.id as rs1_id, rs2.id as rs2_id
    FROM tempus_road.section rs1, tempus_road.section rs2
    WHERE rs1.id <> rs2.id
      AND
      (
        ( rs1.node_id_from = rs2.node_id_to
          and
          rs1.node_id_to = rs2.node_id_from
          and
          rs1.traffic_rules_ft = rs2.traffic_rules_tf
          and
          rs1.traffic_rules_tf = rs2.traffic_rules_ft
        )
      OR
        ( rs1.node_id_from = rs2.node_id_from
          and
          rs1.node_id_to = rs2.node_id_to
          and
          rs1.traffic_rules_ft = rs2.traffic_rules_ft
          and
          rs1.traffic_rules_tf = rs2.traffic_rules_tf
        )
      )
);

do $$
begin
raise notice '==== PT tables ===';
end$$;

CREATE TABLE tempus_pt.network (
    id serial PRIMARY KEY, 
    name character varying UNIQUE,
    comment character varying
);
COMMENT ON TABLE tempus_pt.network IS 'Public transport networks loaded in the database. Never directly read by C++. ';
COMMENT ON COLUMN tempus_pt.network.name IS 'Short name used in user interfaces to define the network';

CREATE TABLE tempus_pt.agency (
        id serial PRIMARY KEY,
        original_id character varying,
        network_id integer REFERENCES tempus_pt.network ON UPDATE CASCADE ON DELETE CASCADE,
        name VARCHAR NOT NULL,
        UNIQUE(network_id, original_id)
);
CREATE INDEX ON tempus_pt.agency(id);
COMMENT ON TABLE tempus_pt.agency IS 'Public transport agencies. A network can be composed of several agencies.';
COMMENT ON COLUMN tempus_pt.agency.name IS 'Short name used in user interfaces to define the network';

CREATE TABLE tempus_pt.route (
        id serial PRIMARY KEY,
        original_id character varying, 
        network_id integer NOT NULL REFERENCES tempus_pt.network ON UPDATE CASCADE ON DELETE CASCADE,       
        agency_id integer NOT NULL REFERENCES tempus_pt.agency ON UPDATE CASCADE ON DELETE CASCADE, 
        short_name character varying NOT NULL,
        long_name character varying,
        description character varying,
        mode_type INTEGER NOT NULL,
        UNIQUE(network_id, original_id)
);
CREATE INDEX ON tempus_pt.route(id);
CREATE INDEX ON tempus_pt.route(network_id, mode_type);
CREATE INDEX ON tempus_pt.route(agency_id);
CREATE INDEX ON tempus_pt.route(network_id, short_name);
COMMENT ON TABLE tempus_pt.route IS 'Public transport routes: group of trips having a common name or number (return trips or variants).';
COMMENT ON COLUMN tempus_pt.route.short_name IS 'Short name used in user interfaces to define the route';
COMMENT ON COLUMN tempus_pt.route.long_name IS 'Long name to define the route, facultative.';
COMMENT ON COLUMN tempus_pt.route.description IS 'Description of the itineraries of the trips belonging to the route, facultative.';
COMMENT ON COLUMN tempus_pt.route.mode_type IS 'Public transport mode type (conform to GTFS route_type field): 0 = Tram, street car, light rail, 1 = metro, subway, 2 = train, 3 = short and long-distance bus, 4 = short and long-distance ferry, 5 = cable-car, 6 = aerial lift, 7 = funicular';

CREATE TABLE tempus_pt.stop (
        id serial PRIMARY KEY,
        original_id VARCHAR,
        network_id integer REFERENCES tempus_pt.network ON UPDATE CASCADE ON DELETE CASCADE,
        location_type INTEGER NOT NULL,
        name VARCHAR NOT NULL,
        wheelchair_boarding INTEGER NOT NULL,
        fare_zone_id integer REFERENCES tempus_cost.pt_fare_zone ON UPDATE CASCADE ON DELETE CASCADE,
        road_section_id bigint REFERENCES tempus_road.section ON DELETE NO ACTION ON UPDATE CASCADE,
        road_section_abscissa double precision CHECK (road_section_abscissa IS NULL OR (road_section_abscissa >= 0 AND road_section_abscissa <= 1)), 
        geom Geometry(PointZ, 4326), 
        UNIQUE(network_id, original_id)
);
CREATE INDEX ON tempus_pt.stop(id);
CREATE INDEX ON tempus_pt.stop USING gist(geom);
COMMENT ON TABLE tempus_pt.stop IS 'Public transport stops, used to define trips.';

-- trigger to propagate stop / intermodality points deletion to artificial road sections
CREATE OR REPLACE FUNCTION tempus_road.delete_artificial_stop_road_section_f() 
RETURNS TRIGGER AS
$$
BEGIN
    DELETE FROM tempus_road.section 
    WHERE OLD.road_section_id = section.id AND network_id = 0 AND road_section.id IN 
    (
        SELECT section.id
        FROM tempus_road.section
        LEFT JOIN tempus_pt.stop
        ON section.id = stop.road_section_id
        LEFT JOIN tempus_cost.intermodality_points ip
        ON section.id = ip.road_section_id
        WHERE stops.road_section_id IS NULL AND ip.road_section_id IS NULL
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_artificial_stop_road_section 
AFTER DELETE ON tempus_pt.stop
FOR EACH ROW EXECUTE PROCEDURE tempus_road.delete_artificial_stop_road_section_f();

CREATE TABLE tempus_pt.trip_shape (
        id serial PRIMARY KEY, 
        original_id character varying,
        network_id integer REFERENCES tempus_pt.network ON UPDATE CASCADE ON DELETE CASCADE,
        geom Geometry(LineStringZ, 4326), 
        UNIQUE(original_id, network_id)
); 
CREATE INDEX ON tempus_pt.trip_shape USING gist(geom);
COMMENT ON TABLE tempus_pt.trip_shape IS 'Shape lines associated to public transport trips. Serveral trips can share the same shape line, since they have the same itinerary, but not the same intermediary stops. Never used by C++.';

CREATE TABLE tempus_pt.trip (
        id serial PRIMARY KEY,
        original_id character varying,
        network_id integer REFERENCES tempus_pt.network ON UPDATE CASCADE ON DELETE CASCADE,
        route_id integer REFERENCES tempus_pt.route ON UPDATE CASCADE ON DELETE CASCADE,
        days_period_id integer REFERENCES tempus_calendar.days_period ON UPDATE CASCADE ON DELETE CASCADE,
        trip_shape_id integer REFERENCES tempus_pt.trip_shape ON UPDATE CASCADE ON DELETE CASCADE,
        wheelchair_accessible boolean,
        bikes_allowed boolean,
        short_name character varying,
        direction smallint,
        UNIQUE(original_id, network_id)
);
CREATE INDEX ON tempus_pt.trip (id);
CREATE INDEX ON tempus_pt.trip (route_id);
CREATE INDEX ON tempus_pt.trip (days_period_id);
CREATE INDEX ON tempus_pt.trip (trip_shape_id);
COMMENT ON TABLE tempus_pt.trip IS 'Public transport trips, having a defined stops sequence.';

CREATE TABLE tempus_pt.section_stop_times (
        stop_id_from integer NOT NULL REFERENCES tempus_pt.stop(id) ON DELETE CASCADE ON UPDATE CASCADE,
        stop_id_to integer NOT NULL REFERENCES tempus_pt.stop(id) ON DELETE CASCADE ON UPDATE CASCADE,
        trip_id integer REFERENCES tempus_pt.trip ON DELETE CASCADE ON UPDATE CASCADE,
        time_from time, 
        time_to time, 
        pickup_from boolean, 
        dropoff_to boolean,
        interpolated_time_from boolean, 
        interpolated_time_to boolean,
        PRIMARY KEY (stop_id_from, stop_id_to, trip_id)
);
CREATE INDEX ON tempus_pt.section_stop_times(stop_id_from); 
CREATE INDEX ON tempus_pt.section_stop_times(stop_id_to);
CREATE INDEX ON tempus_pt.section_stop_times(trip_id);
COMMENT ON TABLE tempus_pt.section_stop_times IS 'Public transport sections stop times.';

CREATE VIEW tempus_pt.section_timetable AS
SELECT section_stop_times.stop_id_from, 
       st1.name as stop_name_from, 
       section_stop_times.time_from, 
       section_stop_times.stop_id_to, 
       st2.name as stop_name_to, 
       section_stop_times.time_to, 
       days_period.days
FROM tempus_pt.section_stop_times
JOIN tempus_pt.trip ON trip.id = section_stop_times.trip_id
JOIN tempus_calendar.days_period ON days_period.id=trip.days_period_id
JOIN tempus_pt.stop st1 ON st1.id = section_stop_times.stop_id_from
JOIN tempus_pt.stop st2 ON st2.id = section_stop_times.stop_id_to;
COMMENT ON VIEW tempus_pt.section_timetable IS 'Public transport sections timetable: stop times and days of tempus_cost. Used by C++ to load timetables in the graph.';


CREATE MATERIALIZED VIEW tempus_pt.view_trips AS
SELECT trip.id, 
       trip.original_id,
       trip.network_id, 
       trip.route_id, 
       route.short_name as route_short_name, 
       route.mode_type, 
       array_agg(distinct stop.name) as served_stops_names, 
       days_period.days, 
       trip.wheelchair_accessible,
       trip.bikes_allowed,
       trip.short_name,
       trip.direction, 
       trip_shape.geom as geom_line, 
       st_collect(DISTINCT stop.geom) as geom_points
FROM tempus_pt.trip JOIN tempus_pt.trip_shape ON (trip.trip_shape_id = trip_shape.id)
                    JOIN tempus_pt.route ON (route.id = trip.route_id)
                    JOIN tempus_calendar.days_period ON (trip.days_period_id = days_period.id)
                    JOIN tempus_pt.section_stop_times ON (trip.id = section_stop_times.trip_id)
                    JOIN tempus_pt.stop ON (section_stop_times.stop_id_from = stop.id OR section_stop_times.stop_id_to = stop.id) 
GROUP BY trip.id, 
       trip.original_id,
       trip.network_id, 
       trip.route_id, 
       route.short_name, 
       route.mode_type, 
       days_period.days, 
       trip.wheelchair_accessible,
       trip.bikes_allowed,
       trip.short_name,
       trip.direction, 
       trip_shape.geom;


-- Views operating graph topology checks
CREATE VIEW tempus_pt.view_chk_isolated_stops AS
(
    SELECT p.*
    FROM tempus_pt.stop AS p
    LEFT JOIN tempus_pt.section_stop_times ON (p.id = section_stop_times.stop_id_from or p.id = section_stop_times.stop_id_to)
    WHERE section_stop_times.stop_id_from is null
      AND section_stop_times.stop_id_to is null
);


do $$
begin
raise notice '==== Intermodal points ===';
end$$;

CREATE TABLE tempus_intermod.network
(
    id serial PRIMARY KEY, 
    name character varying UNIQUE,
    comment character varying
); 
COMMENT ON TABLE tempus_intermod.network IS 'Intermodality points networks';

CREATE TABLE tempus_intermod.point_type
(
    id serial PRIMARY KEY, 
    name character varying
); 
COMMENT ON TABLE tempus_intermod.point_type IS 'Intermodality points types';


INSERT INTO tempus_intermod.point_type(id, name)
VALUES(1, 'Car parks');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(2, 'Shared cars rental point');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(3, 'Bicycle park');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(4, 'Shared bicycles rental point');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(5, 'Point of interest');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(6, 'PT station');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(7, 'PT stop');
INSERT INTO tempus_intermod.point_type(id, name)
VALUES(8, 'Zone centroïd');

CREATE TABLE tempus_intermod.point
(
    id serial PRIMARY KEY, 
    original_id character varying,
    network_id integer REFERENCES tempus_intermod.network ON UPDATE CASCADE,
    type_id integer REFERENCES tempus_intermod.point_type ON UPDATE CASCADE, 
    name character varying,
    road_section_id bigint REFERENCES tempus_road.section ON DELETE NO ACTION ON UPDATE CASCADE,
    road_section_abscissa double precision CHECK (road_section_abscissa IS NULL OR (road_section_abscissa >= 0 AND road_section_abscissa <= 1)), 
    geom Geometry(PointZ, 4326),
    UNIQUE (network_id, original_id)
);

CREATE TABLE tempus_intermod.section
(
        id serial PRIMARY KEY,
        from_point_id integer REFERENCES tempus_intermod.point ON UPDATE CASCADE ON DELETE CASCADE,
        to_point_id integer REFERENCES tempus_intermod.point ON UPDATE CASCADE ON DELETE CASCADE,
        road_traffic_rules_ft integer, 
        road_traffic_rules_tf integer
);
CREATE INDEX ON tempus_intermod.section(id); 
CREATE INDEX ON tempus_intermod.section(from_point_id);
CREATE INDEX ON tempus_intermod.section(to_point_id);
COMMENT ON TABLE tempus_intermod.section IS 'Between intermodal points transfer road sections, used to define additional road edges of the graph.';

CREATE TABLE tempus_intermod.section_time
(
    section_id bigint NOT NULL REFERENCES tempus_intermod.section ON DELETE CASCADE ON UPDATE CASCADE,
    dir_ft boolean, 
    time_period_id integer NOT NULL REFERENCES tempus_calendar.time_period ON DELETE CASCADE ON UPDATE CASCADE,
    speed_rules integer NOT NULL, 
    time_function_id integer NOT NULL REFERENCES tempus_cost.time_function, 
    PRIMARY KEY (section_id, dir_ft, time_period_id, time_function_id)
);
COMMENT ON TABLE tempus_intermod.section_time IS 'Speed, vehicle types and days period associated to road sections. Never directly read by C++. Can be read by Pl/PgSQL cost functions.';
COMMENT ON COLUMN tempus_intermod.section_time.time_period_id IS 'Days period ID when the speed is applied. 0 if always applied';
COMMENT ON COLUMN tempus_intermod.section_time.speed_rules IS 'Speed rules concerned by the speed value';
COMMENT ON COLUMN tempus_intermod.section_time.time_function_id IS 'Speed function ID';


do $$
begin
raise notice '==== tempus_zoning shema ====';
end$$;

-- Table containing the modalities used to fill the comboBoxes of the user interface in QGIS
CREATE TABLE tempus_zoning.source
(
    id serial PRIMARY KEY, 
    name character varying, 
    comment character varying
); 
COMMENT ON TABLE tempus_zoning.source
  IS 'Zoning sources: do not modify this table directly in the database. If you want to add a new zoning, use tempus_loader. ';

  
do $$
begin
raise notice '==== tempus_access schema ====';
end$$;

CREATE TABLE tempus_access.formats
(
    data_type character varying,
    data_format character varying, 
    data_format_name character varying,
    model_version character varying,
    default_encoding character varying,
    default_srid integer, 
    path_type character varying
); 
COMMENT ON TABLE tempus_access.formats IS 'Accepted data formats. Plugin system table: do not modify!';

INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road, ign_route500', 'IGN - Route500', NULL, 'LATIN1', '2154', 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_route500', 'IGN - Route500', '2.1', 'LATIN1', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_route120', 'IGN - Route120', NULL, 'LATIN1', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_route120', 'IGN - Route120', '1.1', 'LATIN1', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_bdtopo', 'IGN - BDTopo', NULL, 'UTF-8', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_bdtopo', 'IGN - BDTopo', '2.2', 'UTF-8', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_bdcarto', 'IGN - BDCarto', NULL, 'UTF-8', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'ign_bdcarto', 'IGN - BDCarto', '3.2', 'LATIN1', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'navteq', 'Navteq - Navstreets', NULL, 'LATIN1', 4326, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'tomtom', 'TomTom - Multinet', NULL, 'LATIN1', 4326, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'tomtom', 'TomTom - Multinet', 1409, 'LATIN1', 4326, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'osm', 'OSM', NULL, 'UTF8', 4326, '.pbf');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'visum', 'Visum', NULL, 'LATIN1', 4326, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('road', 'tempus', 'Tempus', NULL, 'UTF8', 4326, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('poi', 'tempus', 'Tempus', NULL, 'LATIN1', 4326, '.shp');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('poi', 'insee_bpe', 'INSEE - BPE', NULL, 'LATIN1', 2154, 'directory');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('pt', 'gtfs', 'GTFS', NULL, 'UTF8', 4326, '.zip');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('pt', 'sncf', 'GTFS open-data SNCF (TER et IC)', NULL, 'UTF-8', 2154, '');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('zoning', 'tempus', 'Tempus', NULL, 'UTF8', 4326, '.shp');
INSERT INTO tempus_access.formats(data_type, data_format, data_format_name, model_version, default_encoding, default_srid, path_type)
VALUES ('zoning', 'ign_adminexpress', 'IGN - AdminExpress', NULL, 'LATIN1', 2154, 'directory');

CREATE TABLE tempus_access.agregates
(
    id integer PRIMARY KEY,
    name_en character varying,
    name_fr character varying,
    func_name character varying
); 
COMMENT ON TABLE tempus_access.agregates IS 'Accepted agregates (between nodes, times or days) for indicators calculation. Plugin system table: do not modify !';

INSERT INTO tempus_access.agregates(code, name_en, name_fr, func_name)
VALUES (1, 'Average', 'Moyenne', 'avg');
INSERT INTO tempus_access.agregates(code, name_en, name_fr, func_name)
VALUES (2, 'Minimum', 'Minimum', 'min');
INSERT INTO tempus_access.agregates(code, name_en, name_fr, func_name)
VALUES (3, 'Maximum', 'Maximum', 'max');


CREATE TABLE tempus_access.modalities
(
    var_name character varying, 
    mod_id integer, 
    mod_lib character varying,
    mod_data character varying,
    needs_pt boolean, 
    CONSTRAINT modalities_pkey PRIMARY KEY (var, mod_id)
); 
COMMENT ON TABLE tempus_access.modalities IS 'Plugin system table: do not modify !';

INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('node_type', 0, 'Zone d''arrêt', NULL, 't');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('node_type', 1, 'Noeud routier', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('opt_crit', 0, 'Temps minimum', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 7, 'Dimanche', '{0}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 8, 'Jours ouvrés (lundi au vendredi)', '{1,2,3,4,5}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 9, 'Jours ouvrables (lundi au samedi)', '{1,2,3,4,5,6}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 0, 'Tous les jours', '{0,1,2,3,4,5,6}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 2, 'Mardi', '{2}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 3, 'Mercredi', '{3}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 4, 'Jeudi', '{4}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 5, 'Vendredi', '{5}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 6, 'Samedi', '{6}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('day_type', 1, 'Lundi', '{1}', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('rep_meth', 1, 'Alpha shapes', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('rep_meth', 2, 'Enveloppes concaves', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('encoding', 1, 'LATIN1', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('encoding', 2, 'UTF8', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('encoding', 3, 'UTF-8', NULL, 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 0, 'Tous les types de périodes', '(1=1)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 1, 'Vacances scolaires zone A', 'dd IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''A'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 2, 'Vacances scolaires zone B', 'dd IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''B'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 3, 'Vacances scolaires zone C', 'dd IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''C'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 4, 'Période scolaire zone A', 'dd NOT IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''A'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 5, 'Période scolaire zone B', 'dd NOT IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''B'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 6, 'Période scolaire zone C', 'dd NOT IN (SELECT generate_series(start_date, end_date, ''1 day''::interval)::date as date FROM tempus.holidays WHERE position(''C'' in name)>0)', 'f');
INSERT INTO tempus_access.modalities(var_name, mod_id, mod_lib, mod_data, needs_pt)
VALUES ('per_type', 7, 'Jours fériés', '(SELECT tempus.french_bank_holiday(dd))=True', 'f');


CREATE TABLE tempus_access.obj_type
(
  id integer NOT NULL PRIMARY KEY,
  lib character varying,
  indic_list character varying,
  def_name character varying,
  needs_pt boolean
); 
COMMENT ON TABLE tempus_access.obj_type
  IS 'Available base object types for indicators calculation. Plugin system table: do not modify !';

COMMENT ON COLUMN tempus_access.obj_type.id IS 'Integer ID';
COMMENT ON COLUMN tempus_access.obj_type.lib IS 'Object name';
COMMENT ON COLUMN tempus_access.obj_type.indic_list IS 'List of available indics';
COMMENT ON COLUMN tempus_access.obj_type.def_name IS 'Default name of the layer';
COMMENT ON COLUMN tempus_access.obj_type.needs_pt IS 'True if a PT network is needed for this object type';

INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (0, 'Stop areas', 'Zones d''arrêt', '{1,2,3,4,9,10}', 'stop_areas', 't');
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (1, 'Stops', 'Arrêts', '{1,2,3,4,9,10}', 'stops', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (2, 'Sections', 'Sections', '{1,2,3,4,5,6,7,8,21}', 'sections', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (3, 'Trips', 'Trajets', '{5,6,7,9,10,13,14,21}', 'trips', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (4, 'Routes itineraries', 'Itinéraires de lignes', '{1,2,3,4,5,6,7,8,9,10}', 'stops_routes', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (5, 'Routes', 'Lignes', '{1,8}', 'routes', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (6, 'Agencies', 'Opérateurs de transport', '{8,9,10}', 'agencies', 't'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (7, 'Itinéraire(s) (résultats agrégés)', '{5,6,7,11,12,13,14,17,18,19,20,21,22}', 'paths', 'f'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (8, 'Detailed path(s)', 'Itinéraire(s) (résultats détaillés)', '{5,6,7,20,24}', 'paths_details', 'f'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (9, 'Path tree', 'Arborescence', '{6,23,24,25}', 'paths_tree', 'f'); 
INSERT INTO tempus_access.obj_type(id, name_en, name_fr, indic_list, def_name, needs_pt)
VALUES (10, 'Combined path trees', 'Combinaisons d''arborescences', '{6,23,25}', 'comb_paths_trees', 'f'); 


CREATE TABLE tempus_access.indicators
(
    code integer PRIMARY KEY,
    lib character varying,
    map_size boolean,
    map_color boolean,
    sur_color boolean,
    col_name character varying,
    time_ag_stops character varying, 
    time_ag_sections character varying,
    time_ag_trips character varying,
    time_ag_stops_routes character varying,
    time_ag_routes character varying,
    time_ag_agencies character varying,
    day_ag_stops character varying,
    day_ag_sections character varying,
    day_ag_trips character varying,
    day_ag_stops_routes character varying,
    day_ag_routes character varying,
    day_ag_agencies character varying,
    day_ag_paths character varying, 
    day_ag_paths_details character varying,
    indic_paths_trees character varying,
    day_ag_comb_paths_trees character varying, 
    node_ag_comb_paths_trees character varying,
    needs_zoning boolean, 
    needs_pt boolean
);
COMMENT ON TABLE tempus_access.indicators
  IS 'Available indicators. Plugin system table: do not modify !'; 
  
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (1, 'Nombre de services', 't', 'f', 'f', 'serv_num', 'count(distinct trip_id_int)::integer', 'count(distinct trip_id_int)::integer', NULL, 'count(trip_id_int)::integer', 'count(distinct trip_id_int)::integer', NULL, '(%(day_ag)(serv_num))::numeric(10,2)', '(%(day_ag)(serv_num))::numeric(10,2)', NULL, '(%(day_ag)(serv_num))::numeric(10,2)', '(%(day_ag)(serv_num))::numeric(10,2)', NULL, NULL, NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (2, 'Heure premier service', 'f', 'f', 'f', 'first_serv', 'least(min(arrival_time)', 'min(departure_time))', 'min(departure_time)', NULL, 'min(departure_time)', NULL, NULL, '(((%(day_ag)(first_serv)::integer)::character varying || ''seconds'')::interval)::character varying', '(((%(day_ag)(first_serv)::integer)::character varying || 'seconds')::interval)::character varying', NULL, '(((%(day_ag)(first_serv)::integer)::character varying || ''seconds'')::interval)::character varying', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'f', 't');
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (3, 'Heure dernier service', f, f, f, last_serv, greatest(max(arrival_time), max(departure_time)), max(departure_time), , max(departure_time), NULL, NULL, (((%(day_ag)(last_serv)::integer)::character varying || 'seconds')::interval)::character varying, (((%(day_ag)(last_serv)::integer)::character varying || 'seconds')::interval)::character varying, , (((%(day_ag)(last_serv)::integer)::character varying || 'seconds')::interval)::character varying, NULL, NULL, NULL, NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (4, 'Amplitude horaire', t, t, f, time_ampl, NULL, max(departure_time)-min(departure_time), , max(departure_time)-min(departure_time), NULL, NULL, (%(day_ag)(last_serv-first_serv)/3600::double precision)::numeric(10,2), (%(day_ag)(last_serv-first_serv)/3600::double precision)::numeric(10,2), , (%(day_ag)(last_serv-first_serv)/3600::double precision)::numeric(10,2), NULL, NULL, NULL, NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (5, 'Temps total (HH:MM:SS)', f, f, f, total_time, NULL, %(time_ag)(arrival_time-departure_time), max(arrival_time)-min(departure_time), %(time_ag)(arrival_time - departure_time), NULL, NULL, NULL, (((%(day_ag)(total_time)::integer)::character varying || 'seconds')::interval)::character varying, (((%(day_ag)(total_time)::integer)::character varying || 'seconds')::interval)::character varying, (((%(day_ag)(total_time)::integer)::character varying || 'seconds')::interval)::character varying, NULL, NULL, NULL, (d_time – o_time)::time, NULL, NULL, NULL, f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (7, 'Distance totale', f, f, f, total_dist, NULL, (st_length(st_transform(geom, 2154))/1000)::double precision, min((st_length(st_transform(geom_trip, 2154))/1000)::double precision), min((st_length(st_transform(geom_trip, 2154))/1000))::numeric(10,3), , , , %(day_ag)(total_dist)::numeric(10,3), %(day_ag)(total_dist)::numeric(10,3), %(day_ag)(total_dist)::numeric(10,3), NULL, NULL, sum(distance/1000)::numeric(10,3), (st_length(st_transform(geom, 2154))/1000)::numeric(10,3), NULL, NULL, NULL, f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (8, 'véh.km (jour)', f, t, f, veh_km, NULL, (st_length(st_transform(geom, 2154))/1000*count(distinct trip_id_int))::double precision, NULL, min(st_length(st_transform(geom_trip, 2154))/1000)*count(trip_id_int)::numeric(10,0), sum(st_length(st_transform(geom_trip, 2154))::double precision/1000)::numeric(10,3), sum(st_length(st_transform(geom_trip, 2154))::double precision/1000)::numeric(10,3), , %(day_ag)(veh_km)::numeric(10,3), %(day_ag)(veh_km)::numeric(10,3), %(day_ag)(veh_km)::numeric(10,3), %(day_ag)(veh_km)::numeric(10,3), %(day_ag)(veh_km)::numeric(10,3), NULL, NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (9, 'Zones desservies', f, f, f, zones_list, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, t, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (10, 'Population des zones desservies', f, t, f, zones_pop, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, t, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (11, 'Modes de transports utilisés', f, f, f, t_modes, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array_agg(step_mode order by step_mode), NULL, NULL, NULL, NULL, f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (12, 'Temps de parcours du premier au dernier arrêt', f, f, f, stops_time, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL , max(CASE WHEN step_mode = 'Public transport' THEN (last_d_time - first_o_time)::time END), NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (13, 'Heure de départ du premier arrêt', f, f, f, dep_stops, NULL, NULL, min(departure_time), NULL, NULL, NULL, NULL, NULL, (((%(day_ag)(dep_stops))::character varying || 'seconds')::interval)::character varying, NULL, NULL, NULL, min(CASE WHEN step_mode = 'Public transport' THEN first_o_time ELSE NULL END), NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (14, 'Heure d''arrivée au dernier arrêt', f, f, f, arr_stops, NULL, NULL, max(arrival_time), NULL, NULL, NULL, NULL, NULL, (((%(day_ag)(arr_stops))::character varying || 'seconds')::interval)::character varying, , , , max(CASE WHEN step_mode= 'Public transport' THEN last_d_time ELSE NULL END), NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (17, 'Décomposition des temps par mode', f, f, f, compo_time, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array_agg(travel_time::time order by step_mode), NULL, NULL, NULL, NULL, f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (18, 'Décomposition des distances par mode', f, f, f, compo_dist, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, array_agg(distance/1000 order by step_mode), NULL, NULL, NULL, NULL, f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (19, 'Liste d''arrêts de correspondance', f, f, f, tran_stops, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, (max(tran_stops))[2:], NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (20, 'Liste d''arrêts desservis', f, f, f, all_stops, NULL, NULL, array_agg(stop_name ORDER BY stop_sequence), NULL, NULL, NULL, NULL, NULL, min(all_stops), NULL, NULL, NULL, max(all_stops.all_stops), all_stops, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (21, 'Liste des lignes empruntées', f, f, f, routes, array_agg(DISTINCT route_long_name), array_agg(DISTINCT route_long_name), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, max(routes), NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (22, 'Temps d''attente total', f, f, f, wait_time, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, max(wait_o_time::time), NULL, NULL, NULL, NULL, f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (23, 'Nombre de correspondances', f, t, f, tran_numb, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, (pt_changes)::numeric(10,0), %(day_ag)(tran_numb)::numeric(10,0), %(node_ag)(pt_changes)::numeric(10,0), f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (25, 'Nombre de chang. de mode', f, t, f, mode_chang, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, (CASE WHEN mode_changes=-1 THEN 0 ELSE mode_changes END)::numeric(10,0), %(day_ag)(CASE WHEN mode_chang=-1 THEN 0 ELSE mode_chang END)::numeric(10,0), %(node_ag)(CASE WHEN mode_changes=-1 THEN 0 ELSE mode_changes END)::numeric(10,0), f, t);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (6, 'Temps total (sec ou min)', f, t, t, total_time2, NULL, %(time_ag)(arrival_time-departure_time), max(arrival_time)-min(departure_time), %(time_ag)(arrival_time - departure_time), NULL, NULL, NULL, %(day_ag)(total_time2)::numeric(10,0), %(day_ag)(total_time2)::numeric(10,0), %(day_ag)(total_time2)::numeric(10,0), NULL, NULL, NULL, NULL, (total_cost)::numeric(10,0), %(day_ag)(total_time2)::numeric(10,0), %(node_ag)(total_cost)::numeric(10,0), f, f);
INSERT INTO tempus_access.indicators(code, lib, map_size, map_color, sur_color, col_name, time_ag_stops, time_ag_sections, time_ag_trips, time_ag_stops_routes, time_ag_routes, time_ag_agencies, day_ag_stops, day_ag_sections, day_ag_trips, day_ag_stops_routes, day_ag_routes, day_ag_agencies, day_ag_paths, day_ag_paths_details, indic_paths_trees, day_ag_comb_paths_trees, node_ag_comb_paths_trees, needs_zoning, needs_pt)
VALUES (24, 'Vitesse (km/h)', f, t, f, speed_kmh, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, ((st_length(st_transform(geom, 2154))/1000)/(extract(hour from (d_time - o_time)) + extract(minute from (d_time - o_time))/60.0 + extract(second from (d_time – o_time))/3600.0))::numeric(10,1), (CASE WHEN cost>0 THEN (st_length(st_transform(st_makeline(st_setsrid(st_makepoint(x_from, y_from), 4326), st_setsrid(st_makepoint(x, y), 4326)), 2154))/(cost*60))*3.6 END), NULL, NULL, f, f);

  

DROP TABLE IF EXISTS tempus_access.indic_catalog;
CREATE TABLE tempus_access.indic_catalog
(
  id serial NOT NULL, -- Primary key - numerical ID of the calculated layer
  layer_name character varying NOT NULL, -- Layer name
  obj_type character varying NOT NULL, -- Object type contained by the layer
  indics integer[], -- List of available indics
  o_node bigint, -- Origin node numerical ID
  d_node bigint, -- Destination node numerical ID
  node_type integer, -- Node type : origins or destinations
  o_nodes integer[], -- Nodes list (origins or destinations)
  d_nodes integer[],
  nodes_ag integer, -- Agregation method of the results between the different origin/destination nodes
  symb_size character varying, -- Indicator to map with a variable symbol size
  symb_color character varying, -- Indicator to map with a variable symbol color
  days date[], -- Days on which the indicators are calculated
  day_type integer, -- Day type (see "tempus_access.modality" table for modality details)
  per_type integer, -- Period type (see "tempus_access.modality" table for modality details)
  per_start date, -- Date of the begining of the time period
  per_end date, -- Date of the END of the time period
  day_ag integer, -- Agregation method of the daily results
  time_start time without time zone, -- Time of the begining of the time period (inside a day)
  time_inter integer, 
  all_services boolean, 
  time_end time without time zone, -- Time of the END of the time period (inside a day)
  time_ag integer, -- Agregation method of the results inside the time period
  time_point time without time zone, -- Time point used at origin or destination to calculate a path
  constraint_date_after boolean, 
  indic_zoning integer, 
  zoning_filter integer, -- Type of areas of the restriction
  zones character varying[], -- Selected areas, NULL when no area restriction
  route integer, -- Forced route (only stops, sections and PT paths using this route will be kept in the result)
  stop integer, -- Forced stops ID (stop which must be used)
  pt_networks integer[], -- Array of the GTFS feed IDs allowed in the calculation
  agencies integer[], -- Array of agency IDs which are allowed in the calculation
  pt_modes integer[], -- Array of public transport modes IDs allowed in the calculation
  i_modes integer[], -- Array of individual modes IDs allowed in the calculation
  walk_speed double precision, 
  cycl_speed double precision, 
  max_cost integer, 
  criterion integer, -- Criterion of path optimization
  calc_time integer, 
  classes_num integer, 
  rep_meth integer,
  param double precision, 
  parent_layer character varying,
  CONSTRAINT indic_catalog_pkey PRIMARY KEY (id)
) ;

COMMENT ON COLUMN tempus_access.indic_catalog.id IS 'Primary key - numerical ID of the calculated layer';
COMMENT ON COLUMN tempus_access.indic_catalog.layer_name IS 'Layer name';
COMMENT ON COLUMN tempus_access.indic_catalog.obj_type IS 'Object type contained by the layer';
COMMENT ON COLUMN tempus_access.indic_catalog.indics IS 'List of available indics';
COMMENT ON COLUMN tempus_access.indic_catalog.o_node IS 'Origin node numerical ID';
COMMENT ON COLUMN tempus_access.indic_catalog.d_node IS 'Destination node numerical ID';
COMMENT ON COLUMN tempus_access.indic_catalog.node_type IS 'Node type : stop areas or road nodes';
COMMENT ON COLUMN tempus_access.indic_catalog.o_nodes IS 'Origin nodes list';
COMMENT ON COLUMN tempus_access.indic_catalog.d_nodes IS 'Destination nodes list';
COMMENT ON COLUMN tempus_access.indic_catalog.nodes_ag IS 'Agregation method of the results between the different origin/destination nodes';
COMMENT ON COLUMN tempus_access.indic_catalog.symb_size IS 'Indicator to map with a variable symbol size';
COMMENT ON COLUMN tempus_access.indic_catalog.symb_color IS 'Indicator to map with a variable symbol color';
COMMENT ON COLUMN tempus_access.indic_catalog.days IS 'Days on which the indicators are calculated';
COMMENT ON COLUMN tempus_access.indic_catalog.day_type IS 'Day type (see "tempus_access.modality" table for modality details)';
COMMENT ON COLUMN tempus_access.indic_catalog.per_type IS 'Period type (see "tempus_access.modality" table for modality details)';
COMMENT ON COLUMN tempus_access.indic_catalog.per_start IS 'Date of the begining of the time period';
COMMENT ON COLUMN tempus_access.indic_catalog.per_end IS 'Date of the END of the time period';
COMMENT ON COLUMN tempus_access.indic_catalog.day_ag IS 'Agregation method of the daily results';
COMMENT ON COLUMN tempus_access.indic_catalog.time_start IS 'Time of the begining of the time period (inside a day)';
COMMENT ON COLUMN tempus_access.indic_catalog.time_end IS 'Time of the END of the time period (inside a day)';
COMMENT ON COLUMN tempus_access.indic_catalog.time_inter IS 'Time interval between to paths searches';
COMMENT ON COLUMN tempus_access.indic_catalog.all_services IS 'True when all paths between two stops are searched for a time period';
COMMENT ON COLUMN tempus_access.indic_catalog.time_ag IS 'Agregation method of the results inside the time period';
COMMENT ON COLUMN tempus_access.indic_catalog.time_point IS 'Time point used at origin or destination to calculate a path';
COMMENT ON COLUMN tempus_access.indic_catalog.constraint_date_after IS 'True if time constraint is Leave after..., false if it is Arrive before..., null if not relevant for the query';
COMMENT ON COLUMN tempus_access.indic_catalog.zoning_filter IS 'ID of the zoning used for filtering result';
COMMENT ON COLUMN tempus_access.indic_catalog.zones IS 'Zones kept in the filtered result';
COMMENT ON COLUMN tempus_access.indic_catalog.indic_zoning IS 'ID of the zoning used for zonal indicators, like population';
COMMENT ON COLUMN tempus_access.indic_catalog.route IS 'Forced route (only stops, sections and PT paths using this route will be kept in the result)';
COMMENT ON COLUMN tempus_access.indic_catalog.stop IS 'Forced stop ID (stop which must be used)';
COMMENT ON COLUMN tempus_access.indic_catalog.pt_networks IS 'Array of the GTFS feed IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.agencies IS 'Array of agency IDs which are allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.pt_modes IS 'Array of public transport modes IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.i_modes IS 'Array of individual modes IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.walk_speed IS 'Walking speed used for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.cycl_speed IS 'Cycling speed used for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.max_cost IS 'Maximum travel time in minutes for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.criterion IS 'Criterion of path optimization';
COMMENT ON COLUMN tempus_access.indic_catalog.calc_time IS 'Calculation time in seconds';
COMMENT ON COLUMN tempus_access.indic_catalog.classes_num IS 'Number of classes for paths tree/combination of paths trees representation'; 
COMMENT ON COLUMN tempus_access.indic_catalog.param IS 'Parameter for paths tree/combination of paths trees surface representation'; 
COMMENT ON COLUMN tempus_access.indic_catalog.rep_meth IS 'Method for paths tree/combination of paths trees surface representation';
COMMENT ON COLUMN tempus_access.indic_catalog.parent_layer IS 'Name of the principal layer used to derive this layer'; 


-- Function used to ucalendar_date the "symbol_size" or the "symbol_color" field of an indicator table, used for layer displaying in QGIS
CREATE OR REPLACE FUNCTION tempus_access.map_indicator(
    layer_name character varying, 
    indic_name character varying, 
    map_mode character varying, -- 'color' or 'size'
    min_value double precision, 
    max_value double precision, 
    max_indic double precision
    )
  RETURNS void AS
$BODY$

DECLARE
s character varying;

BEGIN
    IF (min_value = max_value) THEN min_value = 0; END IF; 
    s=$$
    UPDATE indic.$$ || layer_name || $$ 
    SET symbol_$$ || map_mode || $$ = ($$ || indic_name || $$ - $$ || min_value::character varying || $$) / ($$ || max_value::character varying || $$/$$ || max_indic || $$::double precision)
    $$;
    EXECUTE (s);
    
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION tempus_access.days(
    day date,
    day_type integer,
    per_type integer,
    per_start date,
    per_end date)
  RETURNS date[] AS
$BODY$

    DECLARE
    s character varying;
    r record;
    days date[];

    BEGIN    
        IF (day IS NOT NULL)
        THEN days = ARRAY[day];
        ELSE
            s=$$SELECT array_agg(dd::date)
            FROM generate_series('$$ || per_start || $$'::date, '$$ || per_end || $$'::date, '1 day'::interval) dd
            WHERE ARRAY[extract('dow' FROM dd::date)] <@ '$$ || (SELECT mod_data FROM tempus_access.modalities WHERE var='day_type' AND mod_code = day_type) || $$' -- days of the week
              AND $$ || (SELECT mod_data FROM tempus_access.modalities WHERE var = 'per_type' AND mod_code = per_type) -- holidays
              ;
              RAISE NOTICE '%', s;
            
            FOR r in EXECUTE(s)
            LOOP days=r.array_agg;
            END LOOP;
        END IF;
        RETURN days;
    END;

$BODY$
LANGUAGE plpgsql; 


CREATE TABLE tempus_stored_results.paths_calculation
(
    req_id integer NOT NULL, 
    req_start_nodes bigint[], 
    req_end_nodes bigint[], 
    req_date date NOT NULL, 
    req_time time NOT NULL, 
    section_id integer NOT NULL, 
    pred_section_id integer, 
    tmode_id integer REFERENCES tempus_tmode.transport_mode, 
    road_section_id integer REFERENCES tempus_road.section, 
    road_abscissa_from double precision, 
    road_abscissa_to double precision, 
    pt_trip_id integer REFERENCES tempus_pt.trip, 
    pt_stop_id_from integer REFERENCES tempus_pt.stop, 
    pt_stop_id_to integer REFERENCES tempus_pt.stop,
    intermod_section_id integer REFERENCES tempus_intermod.section, 
    wait_time time, 
    dep_time time, 
    arr_time time, 
    dep_cost double precision, 
    arr_cost double precision, 
    PRIMARY KEY(req_id, section_id)
); 

COMMENT ON COLUMN tempus_stored_results.paths_calculation.req_id IS 'ID of the paths tree request';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.section_id IS 'Section ID in the paths tree'; 
COMMENT ON COLUMN tempus_stored_results.paths_calculation.req_start_nodes IS 'Start nodes of the paths tree request'; 
COMMENT ON COLUMN tempus_stored_results.paths_calculation.req_end_nodes IS 'End nodes of the paths tree request';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.req_date IS 'Date of departure or arrival of the paths tree request';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.req_time IS 'Time of departure or arrival of the paths tree request';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.pred_section_id IS 'Predecessor section OD in the paths tree';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.road_section_id IS 'Road section ID in the graph';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.road_abscissa_from IS 'Abscissa of the origin on the road section (0 if the road section is traveled as a whole)';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.road_abscissa_to IS 'Abscissa of the destination on the road section (1 if the road section is traveled as a whole)';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.tmode_id IS 'Transport mode used on the section';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.pt_trip_id IS 'Section PT trip ID';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.pt_stop_id_from IS 'Section origin PT stop ID';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.pt_stop_id_to IS 'Section destination PT stop ID';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.intermod_section_id IS 'Intermodal section ID';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.wait_time IS 'Wait time at the origin of the section before departure';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.dep_time IS 'Departure time of the origin of the section';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.arr_time IS 'Arrival time at the destination of the section';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.dep_cost IS 'Cost of the path at the origin of the section (before waiting)';
COMMENT ON COLUMN tempus_stored_results.paths_calculation.arr_cost IS 'Cost of the path at the destination of the section';


