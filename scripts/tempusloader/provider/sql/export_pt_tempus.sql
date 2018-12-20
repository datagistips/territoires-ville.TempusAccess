-- Tempus - PT export Wrapper
-- Parameter %(source_name) : PT network to export

DROP SCHEMA IF EXISTS _tempus_export CASCADE;
CREATE SCHEMA _tempus_export; 

CREATE VIEW _tempus_export.stops AS
(
    SELECT stop_id,stop_name,stop_desc,zone_id,stop_url,location_type,parent_station_id as parent_station, geom
    FROM tempus_gtfs.stops 
    WHERE feed_id = '%(source_name)'
); 

CREATE VIEW _tempus_export.sections AS
(
    SELECT stop_id,stop_name,stop_desc,zone_id,stop_url,location_type,parent_station_id as parent_station, geom
    FROM tempus_gtfs.sections 
    WHERE feed_id = (SELECT max(id) FROM tempus_gtfs.feed_info WHERE name ='%(source_name)')
); 

