-- Tempus - Road export Wrapper
-- Parameter %(source_name) : Road network name to export

DROP SCHEMA IF EXISTS _tempus_export CASCADE;
CREATE SCHEMA _tempus_export; 

CREATE VIEW _tempus_export.node AS
(
    SELECT id, geom
    FROM tempus.road_node
    WHERE network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
);

CREATE VIEW _tempus_export.section AS
(
    SELECT id, road_type, node_from, node_to, traffic_rules_ft, 
       traffic_rules_tf, length, car_speed_limit, tollway, geom
    FROM tempus.road_section
    WHERE network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
);

CREATE VIEW _tempus_export.days_period AS
(
    SELECT id, start_date, end_date, name, bank_holiday, day_before_bank_holiday, 
                  holidays, 
                  day_before_holidays, 
                  monday, 
                  tuesday, 
                  wednesday, 
                  thursday, 
                  friday, 
                  saturday, 
                  sunday
        FROM tempus.road_validity_period
        WHERE id IN 
        (
            (
                SELECT period_id 
                FROM tempus.road_restriction_time_penalty JOIN tempus.road_restriction ON (road_restriction_time_penalty.restriction_id = road_restriction.id)
                WHERE road_restriction.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
            )
            UNION
            (
                SELECT period_id
                FROM tempus.road_section_speed JOIN tempus.road_section ON (road_section_speed.road_section_id = road_section.id)
                WHERE road_section.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
            )
        )
); 



CREATE VIEW _tempus_export.speed_daily_profile AS
(
    SELECT road_daily_profile.profile_id, 
           begin_time as start_time, 
           end_time, 
           speed_rule, 
           average_speed
    FROM tempus.road_daily_profile JOIN tempus.road_section_speed ON (road_section_speed.profile_id = road_daily_profile.profile_id)
                                   JOIN tempus.road_section ON (road_section.id = road_section_speed.road_section_id)
    WHERE road_section.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
); 


CREATE VIEW _tempus_export.section_speed AS
(
    SELECT road_section_id, 
           period_id as days_period_id, 
           profile_id
    FROM tempus.road_section_speed JOIN tempus.road_section ON (road_section_speed.road_section_id = road_section.id)
    WHERE road_section.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
); 

CREATE VIEW _tempus_export.restriction AS
(
    SELECT id, 
           sections
    FROM tempus.road_restriction
    WHERE network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
); 

CREATE VIEW _tempus_export.time_penalty AS
(
    SELECT restriction_id, 
           traffic_rules, 
           period_id as days_period_id, 
           time_value
    FROM tempus.road_restriction_time_penalty JOIN tempus.road_restriction ON (road_restriction.id = road_restriction_time_penalty.restriction_id)
    WHERE road_restriction.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
); 

CREATE VIEW _tempus_export.toll AS
(
    SELECT restriction_id, 
           toll_rules as toll_classes, 
           period_id as days_period_id, 
           toll_value
    FROM tempus.road_restriction_toll JOIN tempus.road_restriction ON (road_restriction.id = road_restriction_toll.restriction_id)
    WHERE road_restriction.network_id = (SELECT max(id) FROM tempus.road_network WHERE name = '%(source_name)')
); 




