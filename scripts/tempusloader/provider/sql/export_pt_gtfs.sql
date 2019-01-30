-- Tempus - PT export Wrapper
-- Parameter %(source_name) : PT network to export

DROP SCHEMA IF EXISTS _tempus_export CASCADE;
CREATE SCHEMA _tempus_export; 

CREATE VIEW _tempus_export.agency AS
(
    SELECT agency_id,agency_name,agency_url,agency_timezone,agency_lang 
    FROM tempus_gtfs.agency 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.calendar AS
(
    SELECT id as service_id, id as monday, id as tuesday, id as wednesday, id as thursday, id as friday, id as saturday, id as sunday, id as start_date, id as end_date
    FROM tempus_gtfs.calendar
    WHERE 1=0
);
    
CREATE VIEW _tempus_export.calendar_dates AS
(
    SELECT service_id,to_char(date, 'YYYYMMDD') as date,1 as exception_type 
    FROM tempus_gtfs.calendar_dates 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.routes AS
(
    SELECT route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color 
    FROM tempus_gtfs.routes 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.stop_times AS
(
    SELECT trip_id,(arrival_time::character varying || ' seconds')::interval as arrival_time,(departure_time::character varying || ' seconds')::interval as departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled 
    FROM tempus_gtfs.stop_times 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.stops AS
(
    SELECT stop_id,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station_id as parent_station 
    FROM tempus_gtfs.stops 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.transfers AS
(
    SELECT from_stop_id,to_stop_id,transfer_type,min_transfer_time 
    FROM tempus_gtfs.transfers 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.trips AS
(
    SELECT route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id 
    FROM tempus_gtfs.trips 
    WHERE feed_id = '%(source_name)'
);
    
CREATE VIEW _tempus_export.shapes AS
(
    SELECT shape_id, shape_pt_lat, shape_pt_lon, row_number() over(partition by shape_id) as shape_pt_sequence 
        FROM (
            SELECT shape_id, st_y(st_transform((st_dumppoints(geom)).geom, 4326)) as shape_pt_lat, st_x(st_transform((st_dumppoints(geom)).geom, 4326)) as shape_pt_lon 
            FROM tempus_gtfs.shapes 
            WHERE feed_id = '%(source_name)' 
            ORDER BY shape_id, (st_dumppoints(geom)).path
        ) q
); 


    
