-- Tempus - Road OSM SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
        To update: network_id to insert in data
*/
do $$
begin
raise notice '==== Update restrictions time penalties ===';
end$$;

INSERT INTO tempus.road_restriction_time_penalty (restriction_id, period_id, traffic_rules, time_value)
SELECT
  id
  , 0
  , 4+8+16+32 -- private cars + taxis + trucks + coaches
  , 'Infinity'::double precision
FROM tempus.road_restriction;

do $$
begin
raise notice '==== Update road network IDs ===';
end$$;

UPDATE tempus.road_section
SET network_id = (SELECT id FROM tempus.road_network WHERE name = '%(source_name)')
WHERE network_id IS NULL; 

UPDATE tempus.road_node
SET network_id = (SELECT id FROM tempus.road_network WHERE name = '%(source_name)')
WHERE network_id IS NULL; 

UPDATE tempus.road_restriction
SET network_id = (SELECT id FROM tempus.road_network WHERE name = '%(source_name)')
WHERE network_id IS NULL; 

do $$
begin
raise notice '==== road_section_speed tables ===';
end$$; 

CREATE TABLE _tempus_import.speed_profiles
(
	id serial, 
	car_speed_limit integer
);

SELECT setval('_tempus_import.speed_profiles_id_seq', (SELECT CASE WHEN max(profile_id) IS NULL THEN 1 ELSE max(profile_id)+1 END FROM tempus.road_daily_profile), False); 

INSERT INTO _tempus_import.speed_profiles(car_speed_limit)
(
        SELECT DISTINCT car_speed_limit
        FROM tempus.road_section
        ORDER BY 1
);

-- Speed profile for cars (speed_rule = 5), one for each car speed limit value
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
SELECT id,0,5,1440,car_speed_limit
FROM _tempus_import.speed_profiles;

INSERT INTO tempus.road_section_speed(road_section_id, period_id, profile_id)
SELECT id, 0, (SELECT profile_id FROM tempus.road_daily_profile WHERE speed_rule=5 AND road_section.car_speed_limit = road_daily_profile.average_speed)
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0; 

