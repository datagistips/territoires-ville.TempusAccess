CREATE LANGUAGE plpython3u;
CREATE EXTENSION IF NOT EXISTS pgtempus;
CREATE EXTENSION IF NOT EXISTS pgrouting;
CREATE EXTENSION IF NOT EXISTS pg_trgm;


CREATE SCHEMA IF NOT EXISTS indic;
COMMENT ON SCHEMA indic
  IS 'Stockage des résultats des calculs d''indicateurs d''accessibilité';

COMMENT ON SCHEMA tempus
  IS 'Données générales de description des réseaux + description du réseau routier';
COMMENT ON SCHEMA tempus_gtfs
  IS 'Données de description des réseaux de transport collectif';
CREATE SCHEMA IF NOT EXISTS tempus_access;
COMMENT ON SCHEMA tempus_access
  IS 'Données et fonctions spécifiques au calcul d''accessibilité';

--------------------------------------------------------------------------------------------------
-- tempus_access schema
--------------------------------------------------------------------------------------------------

CREATE TABLE tempus_access.formats
(
    format_type character varying,
    format_id integer, 
    format_name character varying,
    format_short_name character varying,
    model_version character varying,
    default_encoding character varying,
    default_srid integer, 
    path_type character varying
); 
COMMENT ON TABLE tempus_access.formats
  IS 'Plugin system table: do not modify!';


CREATE TABLE tempus_access.agregates
(
    code integer,
    lib character varying,
    func_name character varying
); 
COMMENT ON TABLE tempus_access.agregates
  IS 'Plugin system table: do not modify !';


CREATE TABLE tempus_access.modalities
(
    var character varying, 
    mod_code integer, 
    mod_lib character varying,
    mod_data character varying,
    CONSTRAINT modalities_pkey PRIMARY KEY (var, mod_code)
); 
COMMENT ON TABLE tempus_access.modalities
  IS 'Plugin system table: do not modify !';

CREATE TABLE tempus_access.obj_type
(
  code integer NOT NULL,
  lib character varying,
  indic_list character varying,
  def_name character varying,
  CONSTRAINT obj_type_pkey PRIMARY KEY (code)
); 
COMMENT ON TABLE tempus_access.obj_type
  IS 'Plugin system table: do not modify !';

COMMENT ON COLUMN tempus_access.obj_type.code IS 'Integer code';
COMMENT ON COLUMN tempus_access.obj_type.lib IS 'Object name';
COMMENT ON COLUMN tempus_access.obj_type.indic_list IS 'List of available indics';
COMMENT ON COLUMN tempus_access.obj_type.def_name IS 'Default name of the layer';


CREATE TABLE tempus_access.indicators
(
  code integer NOT NULL,
  lib character varying,
  map_size boolean,
  map_color boolean,
  sur_color boolean,
  col_name character varying,
  CONSTRAINT indics_pkey PRIMARY KEY (code)
);
COMMENT ON TABLE tempus_access.indicators
  IS 'Plugin system table: do not modify !';

-- Table containing the modalities used to fill the comboBoxes of the user interface in QGIS
CREATE TABLE tempus_access.areas_param
(
    code integer, 
    lib character varying, 
    file_name character varying, 
    id_field character varying, 
    name_field character varying,
    from_srid integer,
    CONSTRAINT areas_param_pkey PRIMARY KEY (code)
); 
COMMENT ON TABLE tempus_access.areas_param
  IS 'Areas definition : do not modify this table directly in the database. If you want to add a new area type, add a line in the corresponding CSV file, in the "data/areas" folder, add the areas SHP file in the same folder and reinit the database. ';

-- Function that gives the last stop of a public transport trip
CREATE FUNCTION tempus_access.end_trip_stops()
  RETURNS SETOF character varying AS
$BODY$
    SELECT distinct stop_name
    FROM
    (
        SELECT init.stop_id
        FROM tempus_gtfs.stop_times init,
        (
            SELECT trip_id, min(stop_sequence)
              FROM tempus_gtfs.stop_times
              GROUP BY trip_id
        ) q 
        WHERE q.trip_id=init.trip_id AND q.min=init.stop_sequence
        UNION
        SELECT fin.stop_id
        FROM tempus_gtfs.stop_times fin,
        (
            SELECT trip_id, max(stop_sequence)
              FROM tempus_gtfs.stop_times
              GROUP BY trip_id
        ) r
        WHERE r.trip_id=fin.trip_id AND r.max=fin.stop_sequence
    ) s , tempus_gtfs.stops
    WHERE s.stop_id=stops.stop_id
$BODY$
LANGUAGE sql; 


CREATE TABLE tempus_access.stops
(
  feed_id character varying(254),
  stop_id character varying(254),
  stop_name character varying(254),
  prec numeric(10,0),
  valid_from date,
  valid_to date,
  geom geometry(Point,4326),
  CONSTRAINT ref_stops_pkey PRIMARY KEY (feed_id, stop_id)
);

CREATE OR REPLACE FUNCTION tempus_access.road_node_from_stop_id(id integer)
  RETURNS bigint AS
$BODY$
    SELECT road_section.node_from
    FROM tempus_gtfs.stops JOIN tempus.road_section ON (stops.road_section_id = road_section.id)
    WHERE stops.id = $1;
$BODY$
  LANGUAGE sql;

CREATE FUNCTION tempus_access.road_node_from_stop_area_id(id integer)
RETURNS bigint AS 
$BODY$
    SELECT road_section.node_from
    FROM tempus_gtfs.stops JOIN tempus.road_section ON (stops.road_section_id = road_section.id)
    WHERE (stops.feed_id, stops.parent_station_id) IN (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $1 LIMIT 1);
$BODY$
LANGUAGE sql; 



CREATE OR REPLACE FUNCTION tempus_access.locate_stop_to_city_center_sncf_open_data
(
    feed_id character varying,
    stop_id character varying,
    city_code character varying
) RETURNS void AS
$BODY$
DECLARE
s character varying;
BEGIN
        s=$$UPDATE tempus_gtfs.stops
        SET geom = st_force3D(st_transform(st_centroid(area.geom), 4326))
        FROM tempus_access.area_type2
        WHERE feed_id = '$$ || $1 || $$' AND (stop_id = '$$ || $2 || $$' OR 'a' || stop_id = '$$ || $2 || $$') AND area.char_id = '$$ || $3 || $$';
        
        UPDATE tempus_access.stops
        SET geom = st_transform(st_centroid(area.geom), 4326)
        FROM tempus_access.area_type2
        WHERE feed_id = 'sncf' AND stop_id = '$$ || $2 || $$' AND '$$ || $2 || $$' NOT LIKE 'a%' AND area.char_id = '$$ || $3 || $$';
        
        INSERT INTO tempus_access.stops(feed_id, stop_id, stop_name, geom, prec)
            SELECT ''sncf'', stop_id, stops.stop_name, st_force2d(stops.geom), 2
            FROM tempus_gtfs.stops
            WHERE feed_id = '$$ || $1 || $$' AND stop_id = '$$ || $2 || $$' AND '$$ || $2 || $$' NOT LIKE 'a%' AND ('sncf', stop_id) NOT IN (SELECT feed_id, stop_id FROM tempus_access.stops);
            
        REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode; $$;
        EXECUTE(s); 
END;
$BODY$
  LANGUAGE plpgsql; 


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
  area_type integer, -- Type of areas of the restriction
  areas character varying[], -- Selected areas, NULL when no area restriction
  route integer, -- Forced route (only stops, sections and PT paths using this route will be kept in the result)
  stop integer, -- Forced stops ID (stop which must be used)
  gtfs_feeds integer[], -- Array of the GTFS feed IDs allowed in the calculation
  agencies integer[], -- Array of agency IDs which are allowed in the calculation
  pt_modes integer[], -- Array of public transport modes IDs allowed in the calculation
  i_modes integer[], -- Array of individual modes IDs allowed in the calculation
  walk_speed double precision, 
  cycl_speed double precision, 
  max_cost integer, 
  criterion integer, -- Criterion of path optimization
  calc_time integer, 
  req character varying, 
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
COMMENT ON COLUMN tempus_access.indic_catalog.area_type IS 'Type of areas of the restriction';
COMMENT ON COLUMN tempus_access.indic_catalog.areas IS 'Selected areas, NULL when no area restriction';
COMMENT ON COLUMN tempus_access.indic_catalog.route IS 'Forced route (only stops, sections and PT paths using this route will be kept in the result)';
COMMENT ON COLUMN tempus_access.indic_catalog.stop IS 'Forced stop ID (stop which must be used)';
COMMENT ON COLUMN tempus_access.indic_catalog.gtfs_feeds IS 'Array of the GTFS feed IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.agencies IS 'Array of agency IDs which are allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.pt_modes IS 'Array of public transport modes IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.i_modes IS 'Array of individual modes IDs allowed in the calculation';
COMMENT ON COLUMN tempus_access.indic_catalog.walk_speed IS 'Walking speed used for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.cycl_speed IS 'Cycling speed used for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.max_cost IS 'Maximum travel time in minutes for isochrons';
COMMENT ON COLUMN tempus_access.indic_catalog.criterion IS 'Criterion of path optimization';
COMMENT ON COLUMN tempus_access.indic_catalog.calc_time IS 'Calculation time in seconds';
COMMENT ON COLUMN tempus_access.indic_catalog.req IS 'Executed request'; 
COMMENT ON COLUMN tempus_access.indic_catalog.classes_num IS 'Number of classes for paths tree/combination of paths trees representation'; 
COMMENT ON COLUMN tempus_access.indic_catalog.param IS 'Parameter for paths tree/combination of paths trees surface representation'; 
COMMENT ON COLUMN tempus_access.indic_catalog.rep_meth IS 'Method for paths tree/combination of paths trees surface representation';
COMMENT ON COLUMN tempus_access.indic_catalog.parent_layer IS 'Name of the principal layer used from this layer derives'; 




-- Function used to update the "symbol_size" or the "symbol_color" field of an indicator table, used for layer displaying in QGIS
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
                                                   day date, -- A fixed day
                                                   day_type integer, -- Weekday type code
                                                   per_type integer, -- Period type code
                                                   per_start date, -- Begining date of the period
                                                   per_end date -- End date of the period
                                             )
RETURNS date[] AS
$BODY$

DECLARE
days_filter character varying;
r record;
days date[];

BEGIN

    IF (day IS NOT NULL)
    THEN days_filter = $$calendar_dates.date='$$ || day::character varying || $$'::date$$;
    ELSE days_filter = $$ARRAY[extract('dow' FROM calendar_dates.date)] <@ '$$ || (SELECT mod_data FROM tempus_access.modalities WHERE var='day_type' AND mod_code = day_type) || $$' 
                        AND calendar_dates.date IN $$ || (SELECT mod_data FROM tempus_access.modalities WHERE var = 'per_type' AND mod_code = per_type) || $$ 
                        AND calendar_dates.date >= '$$ || per_start::character varying || $$'::date AND calendar_dates.date <= '$$ || per_end::character varying || $$'::date$$;
    END IF;
    raise notice '%', days_filter;
    FOR r IN EXECUTE ($$SELECT array_agg(DISTINCT date ORDER BY Date) AS days FROM tempus_gtfs.calendar_dates WHERE $$ || days_filter)
    LOOP
        days=r.days; 
    END LOOP; 
    RETURN days;
END;
$BODY$
LANGUAGE plpgsql;



DROP TABLE tempus_access.tempus_paths_results;
CREATE TABLE tempus_access.tempus_paths_results
(
  gid serial, 
  path_id integer NOT NULL,
  step_id integer NOT NULL, -- Sequence number of the step in the path
  starting_date_time timestamp without time zone, -- Starting date and time of the path
  step_type integer, -- Step type 0: road, 1: public transport, 2: transfer
  initial_mode integer, -- initial transport mode, refers to tempus.transport_mode
  final_mode integer, -- final transport_mode, refers to tempus.transport_mode
  costs double precision[], -- array of costs
  road_edge_id bigint, -- road edge id
  road_movement text, -- text for the navigation
  pt_network_id integer, -- public transport network id. Refers to tempus_gtfs.feed_info
  pt_trip_id bigint, -- trip id. Refers to tempus_gtfs.trips
  pt_wait_time_min double precision, -- waiting time before going on the transport
  pt_departure_time_min double precision, -- actual departure time at the beginning of the step
  pt_arrival_time_min double precision, -- actual arrival time at the END of the step
  source_road_vertex_id bigint, -- Road node id, if the transfer starts from a road
  source_pt_stop_id bigint, -- Stop id, if the transfer starts on a public transport
  source_poi_id bigint, -- POI id, if the transfer starts on a POI
  target_road_vertex_id bigint, -- Road node id, if the transfer ends from a road
  target_pt_stop_id bigint, -- Stop id, if the transfer ends on a public transport
  target_poi_id bigint, -- POI id, if the transfer ends on a POI
  pt_o_stop character varying,
  pt_d_stop character varying,
  wait_o_time time, 
  o_time time, 
  d_time time, 
  all_stops character varying[], 
  pt_route character varying, 
  route_type integer,
  step_mode character varying,
  geom Geometry('MultiLinestring', 4326),
  CONSTRAINT tempus_paths_results_pkey PRIMARY KEY (path_id, step_id)
); 

COMMENT ON COLUMN tempus_access.tempus_paths_results.path_id IS 'ID of the path';
COMMENT ON COLUMN tempus_access.tempus_paths_results.step_id IS 'Sequence number of the step in the path'; 
COMMENT ON COLUMN tempus_access.tempus_paths_results.starting_date_time IS 'Starting date and time of the path'; 
COMMENT ON COLUMN tempus_access.tempus_paths_results.step_type IS 'Step type 0: road, 1: public transport, 2: transfer';
COMMENT ON COLUMN tempus_access.tempus_paths_results.initial_mode IS 'initial transport mode, refers to tempus.transport_mode';
COMMENT ON COLUMN tempus_access.tempus_paths_results.final_mode IS 'final transport_mode, refers to tempus.transport_mode';
COMMENT ON COLUMN tempus_access.tempus_paths_results.costs IS 'array of costs';
COMMENT ON COLUMN tempus_access.tempus_paths_results.road_edge_id IS 'road edge id';
COMMENT ON COLUMN tempus_access.tempus_paths_results.road_movement IS 'text for the navigation';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_network_id IS 'public transport network id. Refers to tempus_gtfs.feed_info';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_trip_id IS 'trip id. Refers to tempus_gtfs.trips';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_wait_time_min IS 'waiting time before going on the transport';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_departure_time_min IS 'actual departure time at the beginning of the step';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_arrival_time_min IS 'actual arrival time at the END of the step';
COMMENT ON COLUMN tempus_access.tempus_paths_results.source_road_vertex_id IS 'Road node id, if the transfer starts from a road';
COMMENT ON COLUMN tempus_access.tempus_paths_results.source_pt_stop_id IS 'Stop id, if the transfer starts on a public transport';
COMMENT ON COLUMN tempus_access.tempus_paths_results.source_poi_id IS 'POI id, if the transfer starts on a POI';
COMMENT ON COLUMN tempus_access.tempus_paths_results.target_road_vertex_id IS 'Road node id, if the transfer ends from a road';
COMMENT ON COLUMN tempus_access.tempus_paths_results.target_pt_stop_id IS 'Stop id, if the transfer ends on a public transport';
COMMENT ON COLUMN tempus_access.tempus_paths_results.target_poi_id IS 'POI id, if the transfer ends on a POI';
COMMENT ON COLUMN tempus_access.tempus_paths_results.wait_o_time IS 'Waiting time at the origin node of the section';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_o_stop IS 'PT origin stop name';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_d_stop IS 'PT destination stop name';
COMMENT ON COLUMN tempus_access.tempus_paths_results.o_time IS 'Departure time from the origin node of the section';
COMMENT ON COLUMN tempus_access.tempus_paths_results.d_time IS 'Arrival time to the destination node of the section';
COMMENT ON COLUMN tempus_access.tempus_paths_results.pt_route IS 'PT route name';
COMMENT ON COLUMN tempus_access.tempus_paths_results.route_type IS 'GTFS route type : 0 = underground, 1 = tram, 2 = train, 3 = bus, 7 = funicular...';
COMMENT ON COLUMN tempus_access.tempus_paths_results.all_stops IS 'PT stops, including intermediate stops';
COMMENT ON COLUMN tempus_access.tempus_paths_results.geom IS 'Geometry of the section';


DROP TABLE IF EXISTS tempus_access.tempus_paths_tree_results;
CREATE TABLE tempus_access.tempus_paths_tree_results
(
  gid serial, 
  path_tree_id integer, 
  dep_arr_time timestamp,
  constraint_date_after boolean,
  root_node integer,
  x float,              -- X coordinate of the node
  y float,              -- Y coordinate of the node
  transport_mode int,   -- transport_mode. Refers to tempus.transport_mode
  cost float,           -- cost (duration in minutes)
  total_cost float,     -- cumulated cost (in minutes)
  mode_changes int,     -- number of transport mode changes so far
  pt_changes int,       -- number of changes on the public transport network
  uid int,              -- unique id of this node
  predecessor int,      -- id of its predecessor, back to the origin where id = predecessor
  wait_time float,       -- waiting time (possibly for PT stop), in minutes
  x_from float, 
  y_from float,
  CONSTRAINT tempus_paths_tree_results_pkey PRIMARY KEY (gid)
); 

COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.path_tree_id IS 'ID of the path tree';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.dep_arr_time IS 'Departure or arrival time';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.constraint_date_after IS 'True if constraint fixed on departure, false if constraint fixed on arrival';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.root_node IS 'Root of the paths tree (departure or arrival node)';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.x IS 'X coordinate of the node'; 
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.y IS 'Y coordinate of the node'; 
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.transport_mode IS 'transport_mode. Refers to tempus.transport_mode';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.cost IS 'cost (duration in minutes)';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.total_cost IS 'cumulated cost (in minutes)';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.mode_changes IS 'number of transport mode changes so far';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.pt_changes IS 'number of changes on the public transport network';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.uid IS 'unique id of this node';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.predecessor IS 'id of its predecessor, back to the origin where id = predecessor';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.wait_time IS 'waiting time (possibly for PT stop), in minutes';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.pt_node_id IS 'Public transport node ID, corresponding to the (x,y) coordinates';
COMMENT ON COLUMN tempus_access.tempus_paths_tree_results.road_node_id IS 'Road transport node ID, corresponding to the (x,y) coordinates';



-- Returns the next departure time to test inside a time period and on the same day (when the next departure time to test is outside the time period, returns NULL)
CREATE OR REPLACE FUNCTION tempus_access.next_pt_timestamp(
                                                        time_bound time, -- End time if constraint_date_after = true, begin time if constraint_date_after = false
                                                        day date, 
                                                        constraint_date_after boolean
                                                       )
RETURNS timestamp without time zone AS
$BODY$

DECLARE
t timestamp;
r record;
s character varying;

BEGIN
    
    IF (constraint_date_after = True)
    THEN s=$$SELECT CASE WHEN ((min((pt_departure_time_min + pt_wait_time_min)::integer)::character varying || ' minute')::interval + '1 minute'::interval)::time < '$$ || time_bound::character varying || $$'::time
                    THEN (min(starting_date_time)::date::character varying || ' ' || ((min((pt_departure_time_min + pt_wait_time_min)::integer)::character varying || ' minute')::interval + '1 minute'::interval)::time::character varying)::timestamp
                    ELSE '$$ || day::character varying || $$ $$ || time_bound::character varying || $$'::timestamp
                    END AS next_time 
             FROM tempus_access.tempus_paths_results 
             WHERE path_id = (SELECT max(path_id) FROM tempus_access.tempus_paths_results) AND starting_date_time::date = '$$ || day::character varying || $$'::date$$;
    ELSIF (constraint_date_after = False)
    THEN s=$$SELECT CASE WHEN ((max(pt_arrival_time_min::integer)::character varying || ' minute')::interval - '1 minute'::interval)::time > '$$ || time_bound::character varying || $$'::time
                    THEN (max(starting_date_time)::date::character varying || ' ' || ((max(pt_arrival_time_min::integer)::character varying || ' minute')::interval - '1 minute'::interval)::time::character varying)::timestamp
                    ELSE '$$ || day::character varying || $$ $$ || time_bound::character varying || $$'::timestamp
                    END AS next_time 
             FROM tempus_access.tempus_paths_results 
             WHERE path_id = (SELECT max(path_id) FROM tempus_access.tempus_paths_results) AND starting_date_time::date = '$$ || day::character varying || $$'::date$$;
    END IF; 
    
    FOR r IN EXECUTE(s)
    LOOP
        t=r.next_time;
    END LOOP; 
    
    RETURN t;
END;
$BODY$
LANGUAGE plpgsql; 


CREATE OR REPLACE FUNCTION tempus_access.next_timestamp(cur_timestamp timestamp, inter integer, bound_timestamp timestamp, constraint_date_after boolean)
RETURNS timestamp AS 
$BODY$

DECLARE
t timestamp;
r record;
s character varying;

BEGIN
    
    IF (constraint_date_after = True)
    THEN RETURN (SELECT CASE WHEN cur_timestamp + (inter::character varying || ' minute')::interval <= bound_timestamp THEN cur_timestamp + (inter::character varying || ' minute')::interval ELSE bound_timestamp END); 
    ELSIF (constraint_date_after = False)
    THEN RETURN (SELECT CASE WHEN cur_timestamp - (inter::character varying || ' minute')::interval >= bound_timestamp THEN cur_timestamp - (inter::character varying || ' minute')::interval ELSE bound_timestamp END); 
    END IF;
END;
$BODY$
LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION tempus_access.shortest_path(
    road_node_from bigint,
    road_node_to bigint,
    tran_modes integer[],
    dep_arr_time timestamp without time zone,
    dep boolean)
  RETURNS void AS
$BODY$
    INSERT INTO tempus_access.tempus_paths_results(
                                                   path_id, 
                                                   step_id, 
                                                   starting_date_time, 
                                                   step_type, 
                                                   initial_mode, 
                                                   final_mode, 
                                                   costs, 
                                                   road_edge_id, 
                                                   road_movement, 
                                                   pt_network_id, 
                                                   pt_trip_id, 
                                                   pt_wait_time_min, 
                                                   pt_departure_time_min, 
                                                   pt_arrival_time_min, 
                                                   source_road_vertex_id, 
                                                   source_pt_stop_id, 
                                                   source_poi_id, 
                                                   target_road_vertex_id, 
                                                   target_pt_stop_id, 
                                                   target_poi_id
                                                  )

    SELECT (SELECT coalesce(max(path_id)+ 1,1) FROM tempus_access.tempus_paths_results), *
    FROM multimodal_request(
                                road_node_from, 
                                road_node_to, 
                                CASE WHEN ARRAY[1] <@ tran_modes THEN tran_modes ELSE tran_modes || ARRAY[1] END, 
                                dep_arr_time, 
                                dep, 
                                false
                            )
    ;
$BODY$
  LANGUAGE sql;


CREATE OR REPLACE FUNCTION tempus_access.shortest_path2(
                                                        road_node_from bigint, 
                                                        road_node_to bigint, 
                                                        tran_modes integer[], 
                                                        dep_arr_time timestamp, 
                                                        dep boolean
                                                      )
RETURNS void AS
$BODY$
    INSERT INTO tempus_access.tempus_paths_results(
                                                   path_id, 
                                                   step_id, 
                                                   starting_date_time, 
                                                   step_type, 
                                                   initial_mode, 
                                                   final_mode, 
                                                   costs, 
                                                   road_edge_id, 
                                                   road_movement, 
                                                   pt_network_id, 
                                                   pt_trip_id, 
                                                   pt_wait_time_min, 
                                                   pt_departure_time_min, 
                                                   pt_arrival_time_min, 
                                                   source_road_vertex_id, 
                                                   source_pt_stop_id, 
                                                   source_poi_id, 
                                                   target_road_vertex_id, 
                                                   target_pt_stop_id, 
                                                   target_poi_id
                                                  )
    WITH forward as (        
        SELECT step_id, 
               starting_date_time, 
               step_type, 
               initial_mode, 
               final_mode, 
               unnest(costs) as cost, 
               road_edge_id, 
               road_movement, 
               pt_network_id, 
               pt_trip_id, 
               pt_wait_time_min, 
               pt_departure_time_min, 
               pt_arrival_time_min, 
               source_road_vertex_id, 
               source_pt_stop_id, 
               source_poi_id, 
               target_road_vertex_id, 
               target_pt_stop_id, 
               target_poi_id
        FROM multimodal_request(
                                road_node_from, 
                                road_node_to, 
                                CASE WHEN ARRAY[1] <@ tran_modes THEN tran_modes ELSE tran_modes || ARRAY[1] END, 
                                dep_arr_time, 
                                dep, 
                                false
                                )
    )
    SELECT (SELECT coalesce(max(path_id)+ 1,1) FROM tempus_access.tempus_paths_results), *
    FROM multimodal_request(
                                road_node_from, 
                                road_node_to, 
                                CASE WHEN ARRAY[1] <@ tran_modes THEN tran_modes ELSE tran_modes || ARRAY[1] END, 
                                case when dep=true then dep_arr_time + ((SELECT (sum(cost)*60)::integer + 60 FROM forward)::character varying || ' seconds')::interval
                                     when dep=false then (select min(starting_date_time) - '60 seconds'::interval FROM forward)
                                end,  
                                case when dep = true then false when dep = false then true end, 
                                false
                            )
    ;
$BODY$
LANGUAGE sql; 


CREATE OR REPLACE FUNCTION tempus_access.shortest_paths_tree(
                                                        root_node integer, 
                                                        tran_modes integer[], 
                                                        max_cost integer, 
                                                        walking_speed double precision, 
                                                        cycling_speed double precision, 
                                                        dep_arr_time timestamp, 
                                                        constraint_date_after boolean
                                                      )
RETURNS void AS
$BODY$
    INSERT INTO tempus_access.tempus_paths_tree_results(
                                                        path_tree_id, 
                                                        dep_arr_time, 
                                                        constraint_date_after, 
                                                        root_node, 
                                                        x, 
                                                        y, 
                                                        transport_mode, 
                                                        cost, 
                                                        total_cost, 
                                                        mode_changes, 
                                                        pt_changes, 
                                                        uid, 
                                                        predecessor, 
                                                        wait_time
                                                     )    
    
    SELECT (SELECT coalesce(max(path_tree_id)+ 1,1) FROM tempus_access.tempus_paths_tree_results), dep_arr_time, constraint_date_after, root_node, *
    FROM mm_isochrone_request(
                                root_node, 
                                CASE WHEN ARRAY[1] <@ tran_modes THEN tran_modes ELSE tran_modes || ARRAY[1] END, 
                                max_cost, 
                                walking_speed, 
                                cycling_speed,
                                dep_arr_time, 
                                constraint_date_after
                            )
    ;
$BODY$
LANGUAGE sql; 


CREATE OR REPLACE FUNCTION tempus_access.pt_all_stops(stop_id_o integer, stop_id_d integer, trip_id integer)
RETURNS SETOF record AS
$BODY$
    SELECT stops.id, stops.stop_id, stops.stop_name, stop_times.stop_sequence
    FROM tempus_gtfs.stop_times JOIN tempus_gtfs.stops ON (stops.feed_id = stop_times.feed_id AND stops.stop_id = stop_times.stop_id)
    WHERE (stop_times.feed_id, stop_times.trip_id) IN (SELECT feed_id, trip_id FROM tempus_gtfs.trips WHERE id = $3) 
    AND (stop_times.stop_sequence >= (SELECT stop_sequence as stop_seq_o FROM tempus_gtfs.stop_times WHERE (feed_id, trip_id) IN (SELECT feed_id, trip_id FROM tempus_gtfs.trips WHERE id = $3) AND (feed_id, stop_id) IN (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $1)))
    AND (stop_times.stop_sequence <= (SELECT stop_sequence as stop_seq_d FROM tempus_gtfs.stop_times WHERE (feed_id, trip_id) IN (SELECT feed_id, trip_id FROM tempus_gtfs.trips WHERE id = $3) AND (feed_id, stop_id) IN (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $2)))
     ORDER BY  stop_times.stop_sequence
$BODY$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION tempus_access.pt_section(stop_id_o integer, stop_id_d integer, trip_id integer)
RETURNS Geometry AS
$BODY$
    SELECT st_linemerge(st_union(sections.geom)) as geom
    FROM (
        SELECT lag(id)  over (order by stop_sequence) as stop_from, id as stop_to 
        FROM (SELECT * FROM tempus_access.pt_all_stops($1, $2, $3) AS (id integer, stop_id character varying, stop_name character varying, stop_sequence integer)) q
         ) r
    JOIN tempus_gtfs.sections on (sections.stop_from = r.stop_from AND sections.stop_to = r.stop_to)
$BODY$
LANGUAGE sql; 


CREATE OR REPLACE FUNCTION tempus_access.road_section(stop_id integer, road_node_id integer)
RETURNS Geometry AS
$BODY$
    SELECT CASE WHEN stop.abscissa_road_section = st_linelocatepoint(road_section.geom, (SELECT geom FROM tempus.road_node WHERE id = $2)) then null else st_linesubstring(road_section.geom, least(stop.abscissa_road_section, st_linelocatepoint(road_section.geom, (SELECT geom FROM tempus.road_node WHERE id = $2))), greatest(stop.abscissa_road_section, st_linelocatepoint(road_section.geom, (SELECT geom FROM tempus.road_node WHERE id = $2)))) end
    FROM tempus_gtfs.stops stop JOIN tempus.road_section ON stop.road_section_id = road_section.id
    WHERE stop.id = $1; 
$BODY$
LANGUAGE sql; 

-
