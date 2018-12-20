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
