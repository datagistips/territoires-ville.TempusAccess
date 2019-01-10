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
    
-- Speed profile for pedestrians (speed_rule = 1) : 3.6 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(1,0,1,1440,3.6); 

-- Speed profile for bicycles (speed_rule = 2) : 15 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(2,0,2,1440,15); 

-- Speed profile for cars (speed_rule = 5) : 30 km/h
INSERT INTO tempus.road_daily_profile(profile_id, begin_time, speed_rule, end_time, average_speed)
VALUES(3,0,5,1440,30); 

INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 1
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 1) > 0 OR (road_section.traffic_rules_tf::integer & 1) > 0; 

INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 2
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 2) > 0 OR (road_section.traffic_rules_tf::integer & 2) > 0; 

-- Cars at 30 km/h
INSERT INTO tempus.road_section_speed(
            road_section_id, period_id, profile_id)
SELECT id, 0, 3
FROM tempus.road_section
WHERE (road_section.traffic_rules_ft::integer & 4) > 0 OR (road_section.traffic_rules_tf::integer & 4) > 0;

 