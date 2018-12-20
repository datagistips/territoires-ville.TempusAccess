psql ... -c "\copy (SELECT agency_id,agency_name,agency_url,agency_timezone,agency_lang FROM tempus_gtfs2.agency) TO ...agency.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date FROM tempus_gtfs2.calendar) TO ...calendar.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT service_id,date,exception_type FROM tempus_gtfs2.calendar_dates) TO ...calendar_dates.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT route_id,agency_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color FROM tempus_gtfs2.routes) TO ...routes.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled FROM tempus_gtfs2.stop_times) TO ...stop_times.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT stop_id,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station FROM tempus_gtfs2.stops) TO ...stops.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT from_stop_id,to_stop_id,transfer_type,min_transfer_time FROM tempus_gtfs2.transfers) TO ...transfers.csv CSV HEADER DELIMITER ','" username
psql ... -c "\copy (SELECT route_id,service_id,trip_id,trip_headsign,direction_id,block_id,shape_id FROM tempus_gtfs2.trips) TO ...trips.csv CSV HEADER DELIMITER ','" username

