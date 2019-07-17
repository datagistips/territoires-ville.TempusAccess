-- Tempus - Road BDTopo SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
*/

do $$
begin
raise notice '==== Create graph topology (with PGRouting) ===';
end$$;

ALTER TABLE %(temp_schema).route
ADD COLUMN source bigint, 
ADD COLUMN target bigint, 
ADD COLUMN geom_2d Geometry('Linestring', 2154);

UPDATE %(temp_schema).route
SET geom_2d = st_transform(st_force2d(geom), 2154); 

SELECT pgr_createTopology('%(temp_schema).route', 1, 'geom_2d', 'gid');

-- Graph topology coherence checking
SELECT pgr_analyzeGraph('%(temp_schema).route', 
				1, 
				'geom_2d', 
				'gid'
		       );

SELECT pgr_analyzeOneway('%(temp_schema).route',                
				ARRAY['Double', 'Inverse'],
				ARRAY['Double', 'Direct'],
				ARRAY['Double', 'Direct'],
				ARRAY['Double', 'Inverse'], 
                oneway:='sens'
			);

ALTER TABLE %(temp_schema).route
ADD COLUMN chk boolean DEFAULT TRUE;

UPDATE %(temp_schema).route
SET chk = FALSE
FROM %(temp_schema).route_vertices_pgr 
WHERE (ein=0 OR eout=0 OR route_vertices_pgr.chk=1) AND (route.source = route_vertices_pgr.id OR route.target = route_vertices_pgr.id); 

do $$
begin
raise notice '==== Road node table ===';
end$$;

DROP TABLE IF EXISTS %(temp_schema).route_vertices_pgr_idmap;
CREATE TABLE %(temp_schema).route_vertices_pgr_idmap
(
        id bigserial primary key,
        vendor_id varchar
);

SELECT setval('%(temp_schema).route_vertices_pgr_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_node), False);

INSERT INTO %(temp_schema).route_vertices_pgr_idmap (vendor_id)
       SELECT id::character varying
       FROM %(temp_schema).route_vertices_pgr
       ORDER BY id; 
CREATE INDEX route_vertices_pgr_idmap_vendor_id_idx ON %(temp_schema).route_vertices_pgr_idmap(vendor_id);

INSERT INTO tempus.road_node(id, vendor_id, network_id, bifurcation, geom, chk)
(
    SELECT (select id from %(temp_schema).route_vertices_pgr_idmap where vendor_id = route_vertices_pgr.id::character varying) as id,  
           null, -- No node table in the original source: BDTopo 
           (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id,
           CASE WHEN cnt>2 THEN TRUE ELSE FALSE END, 
           ST_Force3DZ(st_transform(the_geom,4326)), 
           CASE WHEN chk=1 or ein = 0 or eout=0 THEN FALSE ELSE TRUE END 
    FROM %(temp_schema).route_vertices_pgr
);

-- Update altitude in node geometries
UPDATE tempus.road_node
SET geom = st_setsrid(st_makepoint(st_x(road_node.geom), st_y(road_node.geom), route.z_ini), 4326)
FROM %(temp_schema).route
WHERE route.source = road_node.id; 

UPDATE tempus.road_node
SET geom = st_setsrid(st_makepoint(st_x(road_node.geom), st_y(road_node.geom), route.z_fin), 4326)
FROM %(temp_schema).route
WHERE route.target = road_node.id; 

do $$
begin
raise notice '==== Road section table ===';
end$$;

drop table if exists %(temp_schema).route_idmap;
create table %(temp_schema).route_idmap
(
        id serial primary key,
        vendor_id character varying
);

SELECT setval('%(temp_schema).route_idmap_id_seq', (SELECT CASE WHEN max(id) is null THEN 1 ELSE max(id)+1 END FROM tempus.road_section), False);

INSERT INTO %(temp_schema).route_idmap (vendor_id)
    SELECT id::character varying FROM %(temp_schema).route;
       
CREATE INDEX route_idmap_vendor_id_idx ON %(temp_schema).route_idmap(vendor_id); 

INSERT INTO tempus.road_section(id, vendor_id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, lane, geom, chk)
(
    SELECT (SELECT id FROM %(temp_schema).route_idmap WHERE vendor_id = route.id) as id, 
        route.id as vendor_id, 
       (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id,
       case when (nature ='Chemin' or nature = 'Sentier' or nature = 'Escalier' or nature = 'Piste cyclable') then 4
            when (nature = 'Route empierrée' or nature='Route à 1 chaussée') then 3 
            when (nature = 'Route à 2 chaussées') then 2
            when (nature = 'Autoroute' or nature = 'Quasi-autoroute' or nature = 'Bretelle') then 1 
       end as road_type, 
       (select id from %(temp_schema).route_vertices_pgr_idmap where vendor_id = source::character varying), 
       (select id from %(temp_schema).route_vertices_pgr_idmap where vendor_id = target::character varying), 
       case when (nature ='Chemin' or nature = 'Sentier') then 3 -- Pedestrians and bicycles
            when (nature = 'Escalier') then 1 -- Pedestrians
            when (nature = 'Piste cyclable') then 2 -- Bicycles
            when (nature = 'Route empierrée' or nature = 'Route à 1 chaussée')  then
                case when (sens = 'Direct' or sens = 'Double') then 15 -- Pedestrians, bicycles, cars and taxis
                     else 1 -- Pedestrians
                end
            when (nature='Autoroute' or nature='Quasi-autoroute' or nature='Bretelle') then 
                case when (sens = 'Direct' or sens = 'Double') then 12 -- Cars and taxis
                     else 0
                end
            else 0
       end as traffic_rules_ft, 
       case when (nature = 'Chemin' or nature = 'Sentier') then 3 -- Pedestrians and bicycles
            when (nature = 'Escalier') then 1 -- Pedestrians
            when (nature = 'Piste cyclable') then 2 -- Bicycles
            when (nature = 'Route empierrée' or nature='Route à 1 chaussée')  then
                case when (sens='Inverse' or sens='Double') then 15 -- Pedestrians, bicycles, cars and taxis
                     else 1 -- Pedestrians
                end
            when (nature='Route à 2 chaussées' or nature='Autoroute' or nature='Quasi-autoroute' or nature='Bretelle') then 
                case when (sens='Inverse' or sens='Double') then 12 -- Cars and taxis
                     else 0
                end
            else 0
       end as traffic_rules_tf, 
       st_length(geom)::double precision as length, 
       coalesce(nom_voie_g, nom_voie_d) as road_name, 
       nb_voies as lane, 
       ST_Transform(ST_Force3DZ(ST_LineMerge(geom)), 4326) as geom,
       chk
    FROM %(temp_schema).route
    WHERE etat!='En construction'
); 


do $$
begin
raise notice '==== road_section_speed tables ===';
end$$;

-- Speed profile for cars (speed_rule = 5) : 30 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(1,0,5,1440,30); 

-- Speed profile for cars (speed_rule = 5) : 50 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(2,0,5,1440,50); 

-- Speed profile for cars (speed_rule = 5) : 70 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(3,0,5,1440,70); 

-- Speed profile for cars (speed_rule = 5) : 90 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(4,0,5,1440,80); 

-- Speed profile for cars (speed_rule = 5) : 110 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(5,0,5,1440,110); 

-- Speed profile for cars (speed_rule = 5) : 130 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(6,0,5,1440,130); 

-- Cars at 30 km/h
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 1
FROM tempus.road_section
WHERE ((road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0) AND (road_section.road_type >= 4 OR road_section.road_type IS NULL); 

-- Cars at 50 km/h
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 2
FROM tempus.road_section
WHERE ((road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0) AND (road_section.road_type = 3); 

-- Cars at 70 km/h
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 3
FROM tempus.road_section
WHERE ((road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0) AND (road_section.road_type = 2); 

-- Cars at 80 km/h
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 4
FROM tempus.road_section
WHERE ((road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0) AND (road_section.road_type = 1);
