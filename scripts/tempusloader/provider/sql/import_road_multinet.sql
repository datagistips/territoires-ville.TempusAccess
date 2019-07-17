-- Tempus - Road Multinet SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
        To update: network_id to insert in data
*/

do $$
begin
raise notice '==== road_node table ===';
end$$;

DROP TABLE IF EXISTS %(temp_schema).road_node_idmap;
CREATE TABLE %(temp_schema).road_node_idmap
(
        id bigserial primary key,
        vendor_id varchar
);
SELECT setval('%(temp_schema).road_node_idmap_id_seq', (SELECT CASE WHEN max(id) IS NULL THEN 1 ELSE max(id)+1 END FROM tempus.road_node), False);

INSERT INTO %(temp_schema).road_node_idmap (vendor_id)
       SELECT id::bigint::character varying FROM %(temp_schema).jc
       ORDER BY id::bigint; 
CREATE INDEX road_node_idmap_vendor_id_idx ON %(temp_schema).road_node_idmap(vendor_id);

INSERT INTO tempus.road_node(id, bifurcation, geom, network_id, vendor_id)
SELECT DISTINCT
	(select id from %(temp_schema).road_node_idmap WHERE vendor_id = jc.id::bigint::character varying),
    jc.jncttyp = 2 AS bifurcation,
	ST_Force3DZ(st_transform(geom, 4326)) AS geom, 
	(select max(id) from tempus.road_network where name = '%(source_name)'),
    jc.id
FROM %(temp_schema).jc AS jc
WHERE jc.feattyp = 4120; -- 4120 means road node, 4220 means rail node

do $$
begin
raise notice '==== road_section table ===';
end$$;


drop table if exists %(temp_schema).road_section_idmap;
create table %(temp_schema).road_section_idmap
(
        id bigserial primary key,
        vendor_id character varying
);
SELECT setval('%(temp_schema).road_section_idmap_id_seq', (SELECT CASE WHEN max(id) is null THEN 1 ELSE max(id)+1 END FROM tempus.road_section), False);

-- create index to speed up next query
ANALYSE %(temp_schema).sr;
ANALYSE %(temp_schema).nw; 
CREATE INDEX idx%(temp_schema)_sr_id ON %(temp_schema).sr (id);
CREATE INDEX idx%(temp_schema)_nw_id ON %(temp_schema).nw (id);

INSERT INTO %(temp_schema).road_section_idmap(vendor_id)
    SELECT id::bigint::character varying FROM %(temp_schema).nw
    ORDER BY id::bigint;
CREATE INDEX road_section_idmap_vendor_id_idx on %(temp_schema).road_section_idmap(vendor_id); 

INSERT INTO tempus.road_section(id, vendor_id, network_id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, car_speed_limit, road_name, lane, tollway, geom)
SELECT *
FROM
	(
	SELECT
	    (select id from %(temp_schema).road_section_idmap where vendor_id=nw.id::bigint::character varying) as id, 
        nw.id::bigint::character varying as vendor_id, 
        (select max(id) from tempus.road_network where name = '%(source_name)') as network_id, 
        CASE frc
		WHEN 0 THEN 1
		WHEN 1 THEN 2
		WHEN 2 THEN 2
                WHEN 3 THEN 3
                WHEN 4 THEN 3
                WHEN 5 THEN 3
                WHEN 6 THEN 4
                WHEN 7 THEN 5
                WHEN 8 THEN 7
		ELSE NULL
		END AS road_type,
		(select id from %(temp_schema).road_node_idmap where vendor_id = f_jnctid::bigint::character varying) AS node_from, 
        (select id from %(temp_schema).road_node_idmap where vendor_id = t_jnctid::bigint::character varying) AS node_to, 
		CASE
			WHEN oneway IS NULL AND frc <= 2 THEN 4 + 32 + 64
			WHEN oneway IS NULL THEN 1 + 2 + 4 + 32 + 64 -- [and frc > 2]
			WHEN oneway = 'N' THEN 1
			WHEN oneway = 'TF' THEN 1 -- [and test is true]
			WHEN frc <= 2 then 4 + 32 + 64 -- [and oneway = 'FT' and test is true]
			ELSE 1 + 2 + 4 + 32 + 64 -- [and oneway = 'FT' and test is true and frc > 2]
		END AS traffic_rules_ft, 
        CASE
			WHEN oneway IS NULL AND frc <= 2 then 4 + 32 + 64
			WHEN oneway IS NULL THEN  1 + 2 + 4 + 32 + 64  -- [and frc > 2]
			WHEN oneway = 'N' then 1
			WHEN oneway = 'FT' then 1 -- [and test is false]
			WHEN frc <= 2 then 4 + 32 + 64 -- [and oneway = 'TF' and test is false]
			ELSE 1 + 2 + 4 + 32 + 64 -- [and oneway = 'TF' and test is false and frc > 2]
		END AS traffic_rules_tf, 
		meters AS length, 
        speed.car_speed_limit,
		"name" as road_name,
        CASE lanes
			WHEN 0 THEN NULL
			ELSE lanes
		END AS lane,
        CASE tollrd
			WHEN 'B' THEN true
			WHEN 'FT' THEN true
			WHEN 'TF' THEN true
			ELSE false
		END AS tollway,
        ST_Transform(ST_Force3DZ(ST_LineMerge(nw.geom)), 4326) AS geom
	FROM %(temp_schema).nw AS nw
	LEFT JOIN (
				SELECT sr.id, min(speed) as car_speed_limit
				FROM
				%(temp_schema).sr
				group by sr.id
			  ) as speed on nw.id=speed.id
	WHERE nw.feattyp = 4110 or nw.feattyp = 4130
	) q
WHERE node_from IS NOT null AND node_to IS NOT NULL; 


-- Removing vehicles not allowed to go through the positive direction (ft)
UPDATE tempus.road_section
SET traffic_rules_ft = traffic_rules_ft -
	(traffic_rules_ft & ( CASE WHEN ARRAY[0] <@ array_agg then 1 + 2 + 4 + 8 + 16 + 32 + 64
	ELSE CASE WHEN ARRAY[11] <@ array_agg THEN 4 + 16 ELSE 0 END
		+ CASE WHEN ARRAY[16] <@ array_agg THEN 8 ELSE 0 END
		+ CASE WHEN ARRAY[24] <@ array_agg THEN 2 ELSE 0 END
	END ) )
FROM
    (
        SELECT id::bigint::character varying, array_agg(vt::integer ORDER BY vt)
        FROM %(temp_schema).rs
        WHERE feattyp = 4110 AND restrtyp = 'DF' AND (restrval = 2 OR restrval = 4)
        GROUP BY id 
    ) q
WHERE q.id = road_section.vendor_id ;

-- Removing vehicles not allowed to go through the negative direction (tf)
UPDATE tempus.road_section
SET traffic_rules_tf = traffic_rules_tf -
	(traffic_rules_ft & ( CASE WHEN ARRAY[0] <@ array_agg then 1 + 2 + 4 + 8 + 16 + 32 + 64
	ELSE CASE WHEN ARRAY[11] <@ array_agg THEN 4 + 16 ELSE 0 END
		+ CASE WHEN ARRAY[16] <@ array_agg THEN 8 ELSE 0 END
		+ CASE WHEN ARRAY[24] <@ array_agg THEN 2 ELSE 0 END
	END ) )
FROM
    (
        SELECT id::bigint::character varying, array_agg(vt::integer ORDER BY vt)
        FROM %(temp_schema).rs
        WHERE feattyp = 4110 AND restrtyp = 'DF' AND (restrval = 3 OR restrval = 4)
        GROUP BY id 
    ) q
WHERE q.id = road_section.vendor_id ;

CREATE TABLE %(temp_schema).speed_profiles
(
	id serial, 
	car_speed_limit integer
);
SELECT setval('%(temp_schema).speed_profiles_id_seq', (SELECT CASE WHEN max(profile_id) IS NULL THEN 1 ELSE max(profile_id)+1 END FROM tempus.road_daily_profile), False); 

INSERT INTO %(temp_schema).speed_profiles(car_speed_limit)
(
        SELECT DISTINCT car_speed_limit
        FROM tempus.road_section
		WHERE car_speed_limit IS NOT NULL
        ORDER BY 1
);

-- Speed profile for cars (speed_rule = 5), one for each car speed limit value
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
SELECT id,0,5,1440,car_speed_limit
FROM %(temp_schema).speed_profiles;

-- When no speed limit is defined, a default value of 30 km/h is attributed
INSERT INTO tempus.road_section_speed(road_section_id, period_id, profile_id)
SELECT id, 0, coalesce(road_daily_profile.profile_id, (SELECT profile_id FROM tempus.road_daily_profile WHERE average_speed=30 AND begin_time = 0 AND end_time = 1440 AND speed_rule = 5))
FROM tempus.road_section LEFT JOIN tempus.road_daily_profile ON road_section.car_speed_limit = road_daily_profile.average_speed
WHERE speed_rule=5 AND (road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0; 


do $$
begin
raise notice '==== road_restriction and road_restriction_time_penalty tables ===';
end$$;

drop table if exists %(temp_schema).road_restriction_idmap;
create table %(temp_schema).road_restriction_idmap
(
        id bigserial primary key,
        vendor_id character varying
);
select setval('%(temp_schema).road_restriction_idmap_id_seq', (select case when max(id) is null then 1 else max(id)+1 end from tempus.road_restriction), false);

INSERT INTO %(temp_schema).road_restriction_idmap (vendor_id)
       SELECT DISTINCT ON (id) id::bigint::character varying 
	   FROM %(temp_schema).mp
       ORDER BY id;
CREATE INDEX road_restriction_idmap_vendor_id_idx on %(temp_schema).road_restriction_idmap(vendor_id);

INSERT INTO tempus.road_restriction(id, network_id, vendor_id, sections)
SELECT (select id from %(temp_schema).road_restriction_idmap where vendor_id=mp.id::bigint::character varying) as id, 
       (select max(id) from tempus.road_network where name = '%(source_name)'),
       mp.id::bigint::character varying, 
       array_agg(trpelid::bigint order by seqnr)
FROM %(temp_schema).mp LEFT JOIN %(temp_schema).mn ON mp.id = mn.id
WHERE mn.feattyp IN (2101,2103) AND mp.trpeltyp = 4110 AND mn.promantyp = 0 
GROUP BY mp.id;
    
--
-- TABLE tempus.road_restriction_time_penalty
INSERT INTO tempus.road_restriction_time_penalty(restriction_id, period_id, traffic_rules, time_value)
SELECT
        road_restriction.id,
        0 as period_id,
        CASE WHEN ARRAY[0::smallint] <@ array_agg then 1 + 2 + 4 + 8 + 16 + 32 + 64
        ELSE CASE WHEN ARRAY[11::smallint] <@ array_agg THEN 4 + 16 ELSE 0 END
            + CASE WHEN ARRAY[16::smallint] <@ array_agg THEN 8 ELSE 0 END
            + CASE WHEN ARRAY[24::smallint] <@ array_agg THEN 2 ELSE 0 END
        END
        AS traffic_rules,
        'Infinity'::float as time_value
FROM
    (
        SELECT id::bigint::character varying, array_agg(vt::integer order by vt)
        FROM %(temp_schema).rs
        WHERE rs.feattyp in (2101, 2103) AND vt in (0, 11, 16, 24)
        GROUP BY id
    ) q JOIN tempus.road_restriction ON q.id = road_restriction.vendor_id;

-- TODO : add blocked passage (table rs, restrtyp = 'BP') => defined with an edge and a blocked extreme node (from_node if restrval = 1, to_node if restrval = 2)
-- Could be represented as a road_restriction composed of the edge and each adjacent edge from the chosen extreme node


-- Vacuuming database
VACUUM FULL ANALYSE;
