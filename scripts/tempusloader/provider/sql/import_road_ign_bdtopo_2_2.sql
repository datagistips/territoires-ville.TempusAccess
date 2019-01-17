-- Tempus - Road BDTopo SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
*/

do $$
begin
raise notice '==== Create graph topology (with PGRouting) ===';
end$$;

ALTER TABLE _tempus_import.route
ADD COLUMN source bigint, 
ADD COLUMN target bigint, 
ADD COLUMN geom_2d Geometry('Linestring', 2154);

UPDATE _tempus_import.route
SET geom_2d = st_transform(st_force2d(geom), 2154); 

SELECT pgr_createTopology('_tempus_import.route', 1, 'geom_2d', 'gid');

-- Graph topology coherence checking
SELECT pgr_analyzeGraph('_tempus_import.route', 
				1, 
				'geom_2d', 
				'gid'
		       );

SELECT pgr_analyzeOneway('_tempus_import.route',                
				ARRAY['Double', 'Inverse'],
				ARRAY['Double', 'Direct'],
				ARRAY['Double', 'Direct'],
				ARRAY['Double', 'Inverse'], 
                oneway:='sens'
			);

ALTER TABLE _tempus_import.route
ADD COLUMN chk boolean DEFAULT TRUE;

UPDATE _tempus_import.route
SET chk = FALSE
FROM _tempus_import.route_vertices_pgr 
WHERE (ein=0 OR eout=0 OR route_vertices_pgr.chk=1) AND (route.source = route_vertices_pgr.id OR route.target = route_vertices_pgr.id); 

do $$
begin
raise notice '==== Road node table ===';
end$$;

DROP TABLE IF EXISTS _tempus_import.route_vertices_pgr_idmap;
CREATE TABLE _tempus_import.route_vertices_pgr_idmap
(
        id bigserial primary key,
        vendor_id varchar
);

SELECT setval('_tempus_import.route_vertices_pgr_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_node), False);

INSERT INTO _tempus_import.route_vertices_pgr_idmap (vendor_id)
       SELECT id::character varying
       FROM _tempus_import.route_vertices_pgr
       ORDER BY id; 
CREATE INDEX route_vertices_pgr_idmap_vendor_id_idx ON _tempus_import.route_vertices_pgr_idmap(vendor_id);

INSERT INTO tempus.road_node(id, vendor_id, network_id, bifurcation, geom, chk)
(
    SELECT (select id from _tempus_import.route_vertices_pgr_idmap where vendor_id = route_vertices_pgr.id::character varying) as id,  
           null, -- No node table in the original source: BDTopo 
           (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id,
           CASE WHEN cnt>2 THEN TRUE ELSE FALSE END, 
           ST_Force3DZ(st_transform(the_geom,4326)), 
           CASE WHEN chk=1 or ein = 0 or eout=0 THEN FALSE ELSE TRUE END 
    FROM _tempus_import.route_vertices_pgr
);

-- Update altitude in node geometries
UPDATE tempus.road_node
SET geom = st_setsrid(st_makepoint(st_x(road_node.geom), st_y(road_node.geom), route.z_ini), 4326)
FROM _tempus_import.route
WHERE route.source = road_node.id; 

UPDATE tempus.road_node
SET geom = st_setsrid(st_makepoint(st_x(road_node.geom), st_y(road_node.geom), route.z_fin), 4326)
FROM _tempus_import.route
WHERE route.target = road_node.id; 

do $$
begin
raise notice '==== Road section table ===';
end$$;

drop table if exists _tempus_import.route_idmap;
create table _tempus_import.route_idmap
(
        id serial primary key,
        vendor_id character varying
);

SELECT setval('_tempus_import.route_idmap_id_seq', (SELECT CASE WHEN max(id) is null THEN 1 ELSE max(id)+1 END FROM tempus.road_section), False);

INSERT INTO _tempus_import.route_idmap (vendor_id)
    SELECT id::character varying FROM _tempus_import.route;
       
CREATE INDEX route_idmap_vendor_id_idx ON _tempus_import.route_idmap(vendor_id); 

INSERT INTO tempus.road_section(id, vendor_id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, lane, geom, chk)
(
    SELECT (SELECT id FROM _tempus_import.route_idmap WHERE vendor_id = route.id) as id, 
        route.id as vendor_id, 
       (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id,
       case when (nature ='Chemin' or nature = 'Sentier' or nature = 'Escalier' or nature = 'Piste cyclable') then 4
            when (nature = 'Route empierrée' or nature='Route à 1 chaussée') then 3 
            when (nature = 'Route à 2 chaussées') then 2
            when (nature = 'Autoroute' or nature = 'Quasi-autoroute' or nature = 'Bretelle') then 1 
       end as road_type, 
       (select id from _tempus_import.route_vertices_pgr_idmap where vendor_id = source::character varying), 
       (select id from _tempus_import.route_vertices_pgr_idmap where vendor_id = target::character varying), 
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
    FROM _tempus_import.route
    WHERE etat!='En construction'
); 
