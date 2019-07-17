
DROP SCHEMA IF EXISTS %(temp_schema) CASCADE;
CREATE SCHEMA %(temp_schema); 

CREATE TABLE %(temp_schema).formats
(
    data_type character varying,
    data_format character varying, 
    data_format_name character varying,
    model_version character varying,
    default_encoding character varying,
    default_srid integer, 
    path_type character varying
); 
COMMENT ON TABLE %(temp_schema).formats IS 'Plugin system table: do not modify!';


CREATE TABLE %(temp_schema).agregates
(
    code integer,
    lib character varying,
    func_name character varying
); 
COMMENT ON TABLE %(temp_schema).agregates IS 'Plugin system table: do not modify !';


CREATE TABLE %(temp_schema).modalities
(
    var character varying, 
    mod_code integer, 
    mod_lib character varying,
    mod_data character varying, 
    needs_pt boolean, 
    CONSTRAINT modalities_pkey PRIMARY KEY (var, mod_code)
); 
COMMENT ON TABLE %(temp_schema).modalities IS 'Plugin system table: do not modify !';

CREATE TABLE %(temp_schema).obj_type
(
  code integer NOT NULL,
  lib character varying,
  indic_list character varying,
  def_name character varying,
  needs_pt boolean, 
  CONSTRAINT obj_type_pkey PRIMARY KEY (code)
); 
COMMENT ON TABLE %(temp_schema).obj_type
  IS 'Plugin system table: do not modify !';

COMMENT ON COLUMN %(temp_schema).obj_type.code IS 'Integer code';
COMMENT ON COLUMN %(temp_schema).obj_type.lib IS 'Object name';
COMMENT ON COLUMN %(temp_schema).obj_type.indic_list IS 'List of available indics';
COMMENT ON COLUMN %(temp_schema).obj_type.def_name IS 'Default name of the layer';



CREATE TABLE %(temp_schema).indicators
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
COMMENT ON TABLE %(temp_schema).indicators
  IS 'Plugin system table: do not modify !';

CREATE TABLE %(temp_schema).holidays
(
  id serial NOT NULL,
  name character varying,
  start_date date,
  end_date date
);


  