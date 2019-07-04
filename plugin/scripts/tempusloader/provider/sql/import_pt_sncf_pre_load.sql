
-- Feed info
DELETE FROM tempus_gtfs.feed_info 
WHERE feed_id = '%(source_name)'; 

do $$
begin
raise notice '==== Remove constraints (performances concern) ===';
end$$;

-- Remove all related constraints
ALTER TABLE tempus_gtfs.stops 
    DROP CONSTRAINT IF EXISTS stops_road_section_id_fkey;

DROP INDEX IF EXISTS tempus_gtfs.stops_id_idx; 
DROP INDEX IF EXISTS tempus_gtfs.stops_station_id_int_idx;
DROP INDEX IF EXISTS tempus_gtfs.stops_geom_idx;

ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_road_section_id_fkey;
ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_station_id_int_fkey;
ALTER TABLE tempus_gtfs.stops DROP CONSTRAINT IF EXISTS stops_zone_id_int_fkey;

ALTER TABLE tempus_gtfs.stop_times DROP CONSTRAINT IF EXISTS stop_times_stop_id_int_fkey;
ALTER TABLE tempus_gtfs.stop_times DROP CONSTRAINT IF EXISTS stop_times_trip_id_int_fkey;

ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_shape_id_int_fkey;
ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_stop_from_fkey;
ALTER TABLE tempus_gtfs.sections DROP CONSTRAINT IF EXISTS sections_stop_to_fkey; 

ALTER TABLE tempus_gtfs.routes DROP CONSTRAINT IF EXISTS routes_agency_id_int_fkey;

ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_route_id_int_fkey;   
ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_service_id_int_fkey;  
ALTER TABLE tempus_gtfs.trips DROP CONSTRAINT IF EXISTS trips_shape_id_int_fkey; 
    
do $$
begin
raise notice '==== Remove road nodes and sections indexes ===';
end
$$;

SELECT _drop_index('tempus', 'road_node', 'geom');
SELECT _drop_index('tempus', 'road_section', 'geom');
SELECT _drop_index('tempus', 'road_section', 'node_from');
SELECT _drop_index('tempus', 'road_section', 'node_to');

DROP TRIGGER IF EXISTS delete_isolated_road_nodes ON tempus.road_section;
DROP TRIGGER IF EXISTS retrace_section ON tempus_gtfs.stops;
DROP TRIGGER IF EXISTS delete_artificial_stop_road_section ON tempus_gtfs.stops;

do $$
begin
raise notice '==== Reset import schema ===';
end$$;

/* Drop import schema and recreate it */
DROP SCHEMA IF EXISTS _tempus_import CASCADE;
CREATE SCHEMA _tempus_import;
