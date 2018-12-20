-- Tempus - Visum SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
        %(pedestrian): character used to describe walking mode
        %(bike): character used to describe bicycle mode
        %(car): character used to describe car mode
        %(taxi): character used to describe taxi mode
*/

do $$
begin
raise notice '==== Table road_node ===';
end$$;

DROP TABLE IF EXISTS _tempus_import.road_node_idmap;
CREATE TABLE _tempus_import.road_node_idmap
(
        id bigserial primary key,
        vendor_id varchar
);

SELECT setval('_tempus_import.road_node_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_node), False);
INSERT INTO _tempus_import.road_node_idmap (vendor_id)
       SELECT %(node_NO) 
       FROM _tempus_import.node
       ORDER BY %(node_NO);
CREATE INDEX road_node_idmap_vendor_id_idx ON _tempus_import.road_node_idmap(vendor_id);


INSERT INTO tempus.road_node(id, network_id, vendor_id, bifurcation, geom)
SELECT DISTINCT
	(SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = %(node_NO)::character varying) as id,
    (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id, 
    n.%(node_NO) AS vendor_id,
	False AS bifurcation, -- number of incident edges (to be set below)
	ST_Force3DZ(ST_Transform(ST_SetSRID(geom, 2154), 4326)) AS geom
FROM _tempus_import.node AS n
ORDER BY n.%(node_NO);

do $$
begin
raise notice '==== Tables road_section, road_daily_profile and road_section_speed ===';
end$$;

-- create index to speed up next query
ANALYSE _tempus_import.node;
ANALYSE _tempus_import.link;
CREATE INDEX idx_tempus_import_node_id ON _tempus_import.node(%(node_NO));
CREATE INDEX idx_tempus_import_link_id ON _tempus_import.link(%(link_NO));

-- create sequences for auto-incremented ids
--DROP SEQUENCE IF EXISTS nb_sections_fflow;
--CREATE SEQUENCE nb_sections_fflow MINVALUE 0 START WITH 1;
--DROP SEQUENCE IF EXISTS nb_sections_loaded;
--CREATE SEQUENCE nb_sections_loaded MINVALUE 0 START WITH 1;
--DROP SEQUENCE IF EXISTS nb_profiles;
--CREATE SEQUENCE nb_profiles MINVALUE 0 START WITH 11;

-- Modify nb_sections value if more edges have to be added to the network
--SELECT setval('nb_sections_fflow', (SELECT GREATEST(MAX(id)+1, nextval('nb_sections_fflow'))-1 FROM tempus.road_section));
--SELECT setval('nb_sections_loaded', (SELECT GREATEST(MAX(id)+1, nextval('nb_sections_loaded'))-1 FROM tempus.road_section));
--SELECT setval('nb_profiles',(SELECT GREATEST(MAX(profile_id)+1, nextval('nb_profiles'))-1 FROM tempus.road_daily_profile));

DROP TABLE IF EXISTS _tempus_import.road_link_idmap;
CREATE TABLE _tempus_import.road_link_idmap
(
        id bigserial primary key,
        vendor_id varchar
);

SELECT setval('_tempus_import.road_link_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_section), False);
INSERT INTO _tempus_import.road_link_idmap (vendor_id)
       SELECT %(link_NO) 
       FROM _tempus_import.link
       ORDER BY %(link_NO);
CREATE INDEX road_link_idmap_vendor_id_idx ON _tempus_import.road_link_idmap(vendor_id); 


-- Create temporary table for database populating (tables road_section, road_daily_profile, and road_section_speed)
CREATE TABLE _tempus_import.full_info AS
(
    SELECT
        %(link_NO) AS section_id,
        l.%(link_FROMNODENO) AS node_from,
        l.%(link_TONODENO) AS node_to,
        CASE WHEN '%(pedestrian)' = ANY(STRING_TO_ARRAY(l.%(link_TSYSSET), ',')) THEN 1 ELSE 0 END
        + CASE WHEN '%(bike)' = ANY(STRING_TO_ARRAY(l.%(link_TSYSSET), ',')) THEN 2 ELSE 0 END
        + CASE WHEN '%(car)' = ANY(STRING_TO_ARRAY(l.%(link_TSYSSET), ',')) THEN 4 ELSE 0 END
        + CASE WHEN '%(taxi)' = ANY(STRING_TO_ARRAY(l.%(link_TSYSSET), ',')) THEN 8 ELSE 0 END
            AS traffic_rules_ft,
        CASE WHEN '%(pedestrian)' = ANY(STRING_TO_ARRAY(l.%(link_R_TSYSSET), ',')) THEN 1 ELSE 0 END
        + CASE WHEN '%(bike)' = ANY(STRING_TO_ARRAY(l.%(link_R_TSYSSET), ',')) THEN 2 ELSE 0 END
        + CASE WHEN '%(car)' = ANY(STRING_TO_ARRAY(l.%(link_R_TSYSSET), ',')) THEN 4 ELSE 0 END
        + CASE WHEN '%(taxi)' = ANY(STRING_TO_ARRAY(l.%(link_R_TSYSSET), ',')) THEN 8 ELSE 0 END 
            AS traffic_rules_tf,
        CAST(substring(l.%(link_LENGTH), '[0-9]*.[0-9]*') AS double precision)*1000 AS length,
        l.%(link_NOMROUTE) AS road_name,
        l.%(link_NUMLANES) AS lane_ft, 
        l.%(link_R_NUMLANES) AS lane_tf,
        CAST(l."%(link_TOLL_PRTSYS(V))" AS double precision) > 0 AS tollway,
        CAST(substring(l.%(link_V0PRT), '[0-9]*') AS double precision) AS free_flow_speed,
        CAST(substring(l."%(link_VCUR_PRTSYS(V))", '[0-9]*') AS double precision) AS loaded_speed, 
        ST_Force3DZ(ST_LineMerge(ST_Transform(ST_SetSrid(geom, 2154), 4326))) AS geom
    FROM
        _tempus_import.link AS l
);

-- insert the records into tempus tables and drop temporary table
INSERT INTO tempus.road_section(id, network_id, vendor_id, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, lane_ft, lane_tf, roundabout, tollway, geom)
SELECT DISTINCT ON (section_id)
	(SELECT id FROM _tempus_import.road_link_idmap WHERE vendor_id = section_id::character varying) as id,
    (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id, 
    section_id::character varying AS vendor_id,
	(SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = node_from::character varying) AS node_from,
	(SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = node_to::character varying) AS node_to,
	traffic_rules_ft AS traffic_rules_ft,
	traffic_rules_tf AS traffic_rules_tf,
	length AS length,
	road_name AS road_name,
	lane_ft AS lane_ft,
    lane_tf AS lane_tf, 
	false AS roundabout,
	tollway AS tollway,
	geom AS geom
FROM _tempus_import.full_info
WHERE traffic_rules_ft > 0 OR traffic_rules_tf > 0;

CREATE TABLE _tempus_import.profile
(
    id serial,
    free_flow_speed integer, 
    loaded_speed integer, 
    road_section_ids integer[]
);

SELECT setval('_tempus_import.profile_id_seq', (SELECT CASE WHEN max(profile_id) IS NULL THEN 1 ELSE max(profile_id)+1 END FROM tempus.road_daily_profile), False);

INSERT INTO _tempus_import.profile(free_flow_speed, loaded_speed, road_section_ids)
SELECT free_flow_speed, loaded_speed, array_agg((SELECT id FROM _tempus_import.road_link_idmap WHERE vendor_id = section_id::character varying)) as road_section_ids 
FROM _tempus_import.full_info 
WHERE traffic_rules_ft>=4 OR traffic_rules_tf>=4 
GROUP BY free_flow_speed, loaded_speed; 


INSERT INTO tempus.road_daily_profile (profile_id, begin_time, end_time, speed_rule, average_speed)
(
    SELECT 
      profile.id, 
      0 as begin_time,
      300 as end_time,
      5 as speed_rule, -- car
      free_flow_speed
    FROM _tempus_import.profile
    )
    UNION
    (
    SELECT 
      profile.id, 
      1020 as begin_time,
      1140 as end_time,
      5 as speed_rule, -- car
      loaded_speed
    FROM _tempus_import.profile
); 

INSERT INTO tempus.road_section_speed(road_section_id, period_id, profile_id)
(
    SELECT 
            unnest(road_section_ids) as road_section_id, 
            0, 
            id
    FROM _tempus_import.profile
); 

-- Set road_section.roundabout flag
UPDATE tempus.road_section
SET
        roundabout = true
WHERE id IN
(
        SELECT
                rs.id AS id
        FROM
                _tempus_import.node AS n,
                tempus.road_section AS rs
        WHERE
                rs.node_from = n.%(node_NO)
	AND
                CAST(n."%(node_CONTROLTYPE)" AS double precision) = 5
);

do $$
begin
raise notice '==== Tables road_restriction and road_restriction_time_penalty ===';
end$$;

-- Integration of road penalized movements
CREATE TABLE _tempus_import.restriction
(
    id serial, 
    sections integer[],
    time_penalty integer
); 

SELECT setval('_tempus_import.restriction_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_restriction), False);

INSERT INTO _tempus_import.restriction(sections, time_penalty)
(
	SELECT ARRAY[road_section1.id, road_section2.id] as sections, 
           mov.%(mov_T0TI) as time_penalty
	FROM _tempus_import.mov JOIN tempus.road_section as road_section1 
                                ON (road_section1.node_from = (SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = mov.%(mov_NUMNOEUDO)::character varying) 
                                   AND road_section1.node_to = (SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = mov.%(mov_NUMVIANOEUD)::character varying))
						    JOIN tempus.road_section as road_section2 
                                ON (road_section2.node_from = (SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = mov.%(mov_NUMVIANOEUD)::character varying) 
                                   AND road_section2.node_to = (SELECT id FROM _tempus_import.road_node_idmap WHERE vendor_id = mov.%(mov_NUMNOEUDD)::character varying))
);

INSERT INTO tempus.road_restriction(id, network_id, sections)
SELECT id, (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id, sections
FROM _tempus_import.restriction;

INSERT INTO tempus.road_restriction_time_penalty(restriction_id, time_value, period_id, traffic_rules)
(
    SELECT id, time_penalty, 0, 4
    FROM _tempus_import.restriction
);

