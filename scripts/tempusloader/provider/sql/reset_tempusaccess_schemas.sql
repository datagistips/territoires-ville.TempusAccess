DROP LANGUAGE IF EXISTS plpython3u CASCADE;
CREATE LANGUAGE plpython3u;
CREATE EXTENSION IF NOT EXISTS pgtempus;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS intarray;

DROP SCHEMA IF EXISTS tempus_access CASCADE;
DROP SCHEMA IF EXISTS indic CASCADE;
DROP SCHEMA IF EXISTS zoning CASCADE;

COMMENT ON SCHEMA tempus IS 'General data and road networks description';
COMMENT ON SCHEMA tempus_gtfs IS 'Public transport networks description';
CREATE SCHEMA IF NOT EXISTS tempus_access;
COMMENT ON SCHEMA tempus_access IS 'Accessibility calculations specific data and functions';
CREATE SCHEMA IF NOT EXISTS indic;
COMMENT ON SCHEMA indic IS 'Accessibility calculations results';
CREATE SCHEMA IF NOT EXISTS zoning;
COMMENT ON SCHEMA zoning IS 'Zoning data'; 




do $$
begin
raise notice '==== TempusAccess schema creation ====';
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
COMMENT ON TABLE tempus_access.formats IS 'Plugin system table: do not modify!';


CREATE TABLE tempus_access.agregates
(
    code integer,
    lib character varying,
    func_name character varying
); 
COMMENT ON TABLE tempus_access.agregates IS 'Plugin system table: do not modify !';

CREATE TABLE tempus_access.modalities
(
    var character varying, 
    mod_code integer, 
    mod_lib character varying,
    mod_data character varying,
    needs_pt boolean, 
    CONSTRAINT modalities_pkey PRIMARY KEY (var, mod_code)
); 
COMMENT ON TABLE tempus_access.modalities IS 'Plugin system table: do not modify !';

CREATE TABLE tempus_access.obj_type
(
  code integer NOT NULL,
  lib character varying,
  indic_list character varying,
  def_name character varying,
  needs_pt boolean,
  CONSTRAINT obj_type_pkey PRIMARY KEY (code)
); 
COMMENT ON TABLE tempus_access.obj_type
  IS 'Plugin system table: do not modify !';

COMMENT ON COLUMN tempus_access.obj_type.code IS 'Integer code';
COMMENT ON COLUMN tempus_access.obj_type.lib IS 'Object name';
COMMENT ON COLUMN tempus_access.obj_type.indic_list IS 'List of available indics';
COMMENT ON COLUMN tempus_access.obj_type.def_name IS 'Default name of the layer';
COMMENT ON COLUMN tempus_access.obj_type.needs_pt IS 'True if a PT network is needed for this object type';


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
    needs_zoning boolean, 
    needs_pt boolean
);
COMMENT ON TABLE tempus_access.indicators
  IS 'Plugin system table: do not modify !';

-- Table containing the modalities used to fill the comboBoxes of the user interface in QGIS
CREATE TABLE zoning.zoning_source
(
    id serial PRIMARY KEY, 
    name character varying, 
    comment character varying
); 
COMMENT ON TABLE zoning.zoning_source
  IS 'Zonings definition : do not modify this table directly in the database. If you want to add a new zoning, use tempus_loader. ';

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

CREATE TABLE tempus_access.tempus_paths_tree_results
(
  gid serial PRIMARY KEY, 
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
  pt_node_id integer, 
  road_node_id integer
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

-- A décommenter quand le problème d'installation de PgTempus sera résolu
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


CREATE OR REPLACE VIEW tempus_access.indic_complete_data AS
(
	SELECT stops.feed_id,
            stops.id AS stop_id_int,
            stops.stop_id,
            stops.stop_name,
            stops.geom AS geom_stop,
            ( SELECT parent.id
                   FROM tempus_gtfs.stops parent
                  WHERE stops.parent_station_id::text = parent.stop_id::text AND parent.feed_id::text = stops.feed_id::text) AS parent_stop_id_int,
            stops.parent_station_id AS parent_stop_id,
            ( SELECT parent.stop_name
                   FROM tempus_gtfs.stops parent
                  WHERE stops.parent_station_id::text = parent.stop_id::text AND parent.feed_id::text = stops.feed_id::text) AS parent_stop_name,
            ( SELECT parent.geom
                   FROM tempus_gtfs.stops parent
                  WHERE stops.parent_station_id::text = parent.stop_id::text AND parent.feed_id::text = stops.feed_id::text) AS geom_parent_stop,
            trips.id AS trip_id_int,
            trips.trip_id,
            routes.id AS route_id_int,
            routes.route_id, 
            routes.route_short_name,
            routes.route_long_name,
            routes.route_type,
            agency.id AS agency_id_int,
            agency.agency_id, 
            agency.agency_name,
            calendar_dates.date,
            stop_times.arrival_time,
            stop_times.departure_time,
            stop_times.stop_sequence, 
            shapes.geom AS geom_trip
    FROM tempus_gtfs.stop_times
    JOIN tempus_gtfs.stops ON stop_times.stop_id_int = stops.id
    JOIN tempus_gtfs.trips ON stop_times.trip_id_int = trips.id
    JOIN tempus_gtfs.routes ON routes.id = trips.route_id_int
    JOIN tempus_gtfs.agency ON agency.id = routes.agency_id_int
    JOIN tempus_gtfs.calendar_dates ON calendar_dates.service_id_int = trips.service_id_int
    LEFT JOIN tempus_gtfs.shapes ON shapes.id = trips.shape_id_int
);


CREATE OR REPLACE VIEW tempus_access.sections_indic_complete_data AS
(
    SELECT sections.id as section_id_int, 
           s1.feed_id, 
           stops1.id as stop_id_from_int, 
           s1.stop_id as stop_id_from, 
           stops1.parent_station_id as parent_station_id_from, 
           stops1.stop_name as stop_name_from, 
           stops2.id as stop_id_to_int, 
           s2.stop_id as stop_id_to, 
           stops2.parent_station_id as parent_station_id_to, 
           stops2.stop_name as stop_name_to, 
           trips.id AS trip_id_int, 
           s1.departure_time, 
           s2.arrival_time, 
           routes.id as route_id_int, 
           routes.route_id, 
           routes.route_short_name, 
           routes.route_long_name, 
           routes.route_type, 
           agency.id as agency_id_int, 
           calendar_dates.date, 
           st_force2D(sections.geom)::Geometry(Linestring, 4326) as geom
    FROM tempus_gtfs.sections JOIN tempus_gtfs.stops stops1 ON sections.stop_from = stops1.id
                              JOIN tempus_gtfs.stops stops2 ON sections.stop_to = stops2.id
                              JOIN tempus_gtfs.stop_times s1 ON s1.stop_id_int = stops1.id
                              JOIN tempus_gtfs.stop_times s2 ON (s2.stop_id_int = stops2.id AND s1.trip_id_int = s2.trip_id_int AND s1.stop_sequence=s2.stop_sequence - 1)
                              JOIN tempus_gtfs.trips ON trips.id = s1.trip_id_int
                              JOIN tempus_gtfs.routes ON routes.id = trips.route_id_int
                              JOIN tempus_gtfs.calendar_dates ON calendar_dates.service_id_int = trips.service_id_int
                              JOIN tempus_gtfs.agency ON agency.id = routes.agency_id_int
);

CREATE OR REPLACE VIEW tempus_access.paths_indic_complete_data AS
(
    SELECT 
           path_id, 
           step_id, 
           step_mode, 
           wait_o_time, 
           coalesce((starting_date_time::date::character varying || ' ' || (pt_departure)::character varying)::timestamp,
                    starting_date_time + ((sum((cost*60)::integer) over(partition by path_id order by path_id, step_id) || ' second')::character varying)::interval - ((cost*60)::integer::character varying || ' second')::interval + coalesce(wait_o_time,'00:00:00')
                   ) as o_time, 
           coalesce((starting_date_time::date::character varying || ' ' || (pt_arrival)::character varying)::timestamp, 
                    starting_date_time + ((sum((cost*60)::integer) over(partition by path_id order by path_id, step_id) || ' second')::character varying)::interval
                   ) as d_time,        
           pt_o_stop, 
           pt_d_stop, 
           all_stops, 
           pt_route, 
           route_type, 
           geom
    FROM
    (
        SELECT path_id, 
               step_id, 
               starting_date_time, 
               unnest(costs) as cost, 
               stop_o.stop_name as pt_o_stop, 
               stop_d.stop_name as pt_d_stop, 
               (((pt_wait_time_min*60)::integer)::character varying || ' second')::interval as wait_o_time,
               ((pt_departure_time_min*60)::integer || ' second')::interval as pt_departure,                    
               ((pt_arrival_time_min*60)::integer || ' second')::interval as pt_arrival, 
               (SELECT array_agg(stop_name order by stop_sequence) FROM (SELECT * FROM tempus_access.pt_all_stops(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer) as (id integer, stop_id character varying, stop_name character varying, stop_sequence integer)) q) as all_stops, 
               routes.route_long_name as pt_route, 
               routes.route_type as route_type, 
               CASE WHEN tempus_paths_results.step_type = 1 THEN 'Public transport' 
                    ELSE transport_mode.name 
               END AS step_mode, 
               CASE WHEN tempus_paths_results.step_type = 0 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) -- Road section
                      THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE (node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id) OR (node_to = tempus_paths_results.source_road_vertex_id AND node_from = tempus_paths_results.target_road_vertex_id))
                    WHEN tempus_paths_results.step_type = 1 -- PT section
                      THEN (SELECT st_multi(st_force2d(tempus_access.pt_section(stop_o.id, stop_d.id, tempus_paths_results.pt_trip_id::integer)))) 
                    WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_road_vertex_id IS NOT NULL) -- Transfer section
                      THEN (SELECT st_multi(st_force2d(geom)) FROM tempus.road_section WHERE (node_from = tempus_paths_results.target_road_vertex_id AND node_to = tempus_paths_results.source_road_vertex_id) OR (node_to = tempus_paths_results.source_road_vertex_id AND node_from = tempus_paths_results.target_road_vertex_id))
                    WHEN tempus_paths_results.step_type = 2 AND (source_road_vertex_id IS NOT NULL AND target_pt_stop_id IS NOT NULL) 
                      THEN (SELECT st_multi(st_force2d(tempus_access.road_section(target_pt_stop_id::integer, source_road_vertex_id::integer))))
                    WHEN tempus_paths_results.step_type = 2 AND (target_road_vertex_id IS NOT NULL AND source_pt_stop_id IS NOT NULL) 
                      THEN (SELECT st_multi(st_force2d(tempus_access.road_section(source_pt_stop_id::integer, target_road_vertex_id::integer))))
               END::Geometry(Multilinestring, 4326) AS geom 
        FROM tempus_access.tempus_paths_results 
             LEFT JOIN tempus.transport_mode ON (transport_mode.id = least(tempus_paths_results.final_mode, tempus_paths_results.initial_mode))
             LEFT JOIN tempus_gtfs.trips ON (trips.id = tempus_paths_results.pt_trip_id)
             LEFT JOIN tempus_gtfs.routes ON (trips.route_id_int = routes.id)
             LEFT JOIN tempus_gtfs.stops stop_o ON (stop_o.id = tempus_paths_results.source_pt_stop_id)
             LEFT JOIN tempus_gtfs.stops stop_d ON (stop_d.id = tempus_paths_results.target_pt_stop_id)
             LEFT JOIN tempus_gtfs.shapes ON (shapes.id = trips.shape_id_int)
        ORDER BY path_id, step_id
    ) q
);

