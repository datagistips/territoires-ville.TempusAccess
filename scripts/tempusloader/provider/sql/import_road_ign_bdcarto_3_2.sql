-- Tempus - Road BDCarto SQL import Wrapper
/*
        Substitutions options
        %(source_name): name of the road network
*/

do $$
begin
raise notice '==== Create graph topology (with PGRouting) ===';
end$$;

ALTER TABLE _tempus_import.troncon_route
ADD COLUMN source bigint, 
ADD COLUMN target bigint, 
ADD COLUMN geom_2d Geometry('Linestring', 2154);

UPDATE _tempus_import.troncon_route
SET geom_2d = st_transform(st_force2d(geom), 2154); 

SELECT pgr_createTopology('_tempus_import.troncon_route',  0.01, 'geom_2d', 'gid');

-- Graph topology coherence checking
SELECT pgr_analyzeGraph('_tempus_import.troncon_route', 
				0.01, 
				'geom_2d', 
				'gid'
		       );

SELECT pgr_analyzeOneway('_tempus_import.troncon_route',
				ARRAY['Double sens', 'Sens inverse'],
				ARRAY['Double sens', 'Sens unique'],
				ARRAY['Double sens', 'Sens unique'],
				ARRAY['Double sens', 'Sens inverse'],
				oneway:='sens'
			);

ALTER TABLE _tempus_import.troncon_route
ADD COLUMN chk boolean DEFAULT TRUE;

UPDATE _tempus_import.troncon_route
SET chk = FALSE
FROM _tempus_import.troncon_route_vertices_pgr 
WHERE (ein=0 OR eout=0 OR troncon_route_vertices_pgr.chk=1) AND (troncon_route.source = troncon_route_vertices_pgr.id OR troncon_route.target = troncon_route_vertices_pgr.id); 


do $$
begin
raise notice '==== road_node table ===';
end$$;

DROP TABLE IF EXISTS _tempus_import.troncon_route_vertices_pgr_idmap;
CREATE TABLE _tempus_import.troncon_route_vertices_pgr_idmap
(
        id bigserial primary key,
        vendor_id character varying
);

SELECT setval('_tempus_import.troncon_route_vertices_pgr_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_node), False);

INSERT INTO _tempus_import.troncon_route_vertices_pgr_idmap (vendor_id)
       SELECT id::character varying
       FROM _tempus_import.troncon_route_vertices_pgr
       ORDER BY id::integer; 
CREATE INDEX troncon_route_vertices_pgr_idmap_vendor_id_idx ON _tempus_import.troncon_route_vertices_pgr_idmap(vendor_id);

INSERT INTO tempus.road_node(id, network_id, bifurcation, geom, chk)
(
    SELECT id,
           (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)') as network_id, 
           CASE WHEN cnt>2 THEN TRUE ELSE FALSE END, 
           ST_Force3DZ(st_transform(the_geom,4326)), 
           CASE WHEN chk=1 or ein = 0 or eout=0 THEN FALSE ELSE TRUE END 
    FROM _tempus_import.troncon_route_vertices_pgr
);



do $$
begin
raise notice '==== road_section table ==='; 
end$$;

drop table if exists _tempus_import.troncon_route_idmap;
create table _tempus_import.troncon_route_idmap
(
        id serial primary key,
        vendor_id character varying
);

SELECT setval('_tempus_import.troncon_route_idmap_id_seq', (SELECT CASE WHEN max(id) is null THEN 1 ELSE max(id)+1 END FROM tempus.road_section), False);

INSERT INTO _tempus_import.troncon_route_idmap (vendor_id)
    SELECT id FROM _tempus_import.troncon_route;
       
CREATE INDEX troncon_route_idmap_vendor_id_idx on _tempus_import.troncon_route_idmap(vendor_id); 

INSERT INTO tempus.road_section(id, vendor_id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, road_name, lane, tollway, geom, chk)
SELECT
	(select id from _tempus_import.troncon_route_idmap where vendor_id=troncon_route.id) as id, 
	id as vendor_id, 
    (select max(id) from tempus.road_network where name = '%(source_name)') as network_id, 
	CASE vocation
		WHEN 'Type autoroutier' THEN 1
		WHEN 'Liaison principale' THEN 2
		WHEN 'Liaison régionale' THEN 3
		WHEN 'Liaison locale' THEN 4
		ELSE 5 -- Others
	END AS road_type,	
	(select id from _tempus_import.troncon_route_vertices_pgr_idmap where vendor_id = source::character varying) as node_from, 
    (select id from _tempus_import.troncon_route_vertices_pgr_idmap where vendor_id = target::character varying) as node_to,   
	CASE
		WHEN (sens = 'Double sens' OR sens = 'Sens unique') AND vocation != 'Type autoroutier' THEN 8+4+2+1 -- Taxis, cars, bicycles and pedestrians
		WHEN (sens = 'Double sens' OR sens = 'Sens unique') AND vocation = 'Type autoroutier' THEN 8+4 -- Taxis and cars
		ELSE 1 -- Pedestrians only
	END as traffic_rules_ft, 
    
        CASE
		WHEN (sens = 'Double sens' OR sens = 'Sens inverse') AND vocation != 'Type autoroutier' THEN 8+4+2+1 -- Taxis, cars, bicycles and pedestrians
		WHEN (sens = 'Double sens' OR sens = 'Sens inverse') AND vocation = 'Type autoroutier' THEN 8+4 -- Taxis and cars
		ELSE 1 -- Pedestrians only
	END as traffic_rules_tf, 
    
	st_length(geom) AS length,

	num_route AS road_name,

	CASE nb_voies
		WHEN '1 ou 2 voies étroites' THEN 1
		WHEN '2 voies larges' THEN 2
		WHEN '3 voies' THEN 3
		WHEN '4 voies' THEN 4
		WHEN 'Plus de 4 voies' THEN 5
		ELSE NULL
	END AS lane,

	CASE WHEN acces='A péage' THEN True ELSE False END AS tollway,

	ST_Transform(ST_Force3DZ(ST_LineMerge(geom)), 4326) AS geom,
	-- FIXME remove ST_LineMerge call as soon as loader will use Simple geometry option
	chk
FROM _tempus_import.troncon_route; 

do $$
begin
raise notice '==== road_restriction and road_restriction_time_penalty tables ===';
end$$;

drop table if exists _tempus_import.communication_restreinte_idmap;
create table _tempus_import.communication_restreinte_idmap
(
        id serial primary key,
        vendor_id character varying
);

select setval('_tempus_import.communication_restreinte_idmap_id_seq', (select case when max(id) is null then 1 else max(id)+1 end from tempus.road_restriction), false);

insert into _tempus_import.communication_restreinte_idmap (vendor_id)
       select id from _tempus_import.communication_restreinte;
       
create index communication_restreinte_idmap_vendor_id_idx on _tempus_import.communication_restreinte_idmap(vendor_id);


INSERT INTO tempus.road_restriction(id, network_id, vendor_id, sections)
SELECT (select id from _tempus_import.communication_restreinte_idmap where vendor_id=communication_restreinte.id) as id, 
       (select max(id) from tempus.road_network where name = '%(source_name)'),
       id, 
       array[(select id from _tempus_import.troncon_route_idmap where vendor_id = id_tro_ini), (select id from _tempus_import.troncon_route_idmap where vendor_id = id_tro_fin)]
    FROM _tempus_import.communication_restreinte
    WHERE interdit = 'Totale';
    
--
-- TABLE tempus.road_restriction_time_penalty
INSERT INTO tempus.road_restriction_time_penalty(restriction_id, period_id, traffic_rules, time_value)
SELECT
        (select id from _tempus_import.communication_restreinte_idmap where vendor_id =communication_restreinte.id) as id,
        0 as period_id,
        4+8+16+32 as traffic_rules,
        'Infinity'::float as time_value
FROM
	_tempus_import.communication_restreinte
WHERE
    interdit = 'Totale';



    