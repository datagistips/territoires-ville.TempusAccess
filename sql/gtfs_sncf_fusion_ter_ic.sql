-- Feed info
DELETE FROM tempus_gtfs.feed_info WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.feed_info(feed_id)
SELECT 'sncf'; 

-- Temporary table containing joined stop times, trips, routes and agencies data. 
-- When stop times exist in both sources (normally only for TER buses), stop times are attributed to TER agency. 
-- When a route exists in both sources, but with different trip ids and stop times, the route is duplicated. 
DROP TABLE IF EXISTS tempus_access.stop_times; 
CREATE TABLE tempus_access.stop_times AS
(
    SELECT max(stop_times.feed_id) as feed_id, 
           stop_times.trip_id, 
           stop_sequence, 
           stop_id, 
           substring(stop_id FROM length(stop_id) - 7 FOR 8) || '-' || route_type AS new_stop_id, 
           substring(stop_id FROM position(':' in stop_id)+1 FOR position('-' in stop_id) - position(':' in stop_id)-1) as trip_type, 
           arrival_time, 
           departure_time, 
           interpolated, 
           shape_dist_traveled, 
           timepoint, pickup_type, 
           drop_off_type, 
           stop_headsign, 
           route_type, 
           max(routes.route_id) as route_id, 
           max(agency.agency_id) as agency_id, 
           string_agg((trips.service_id || ' - ' || trips.feed_id)::character varying, ';') as service_id
    FROM tempus_gtfs.stop_times JOIN tempus_gtfs.trips ON (trips.feed_id = stop_times.feed_id and stop_times.trip_id = trips.trip_id)
		                  JOIN tempus_gtfs.routes ON (routes.feed_id = trips.feed_id and routes.route_id = trips.route_id)
		                  JOIN tempus_gtfs.agency ON (agency.feed_id = routes.feed_id and agency.agency_id = routes.agency_id)
    WHERE stop_times.feed_id = any(ARRAY['ter', 'ic'])
    GROUP BY stop_times.trip_id, 
           stop_sequence, 
           stop_id, 
           substring(stop_id FROM length(stop_id) - 7 FOR 8) || '-'  || route_type, 
           substring(stop_id FROM position(':' in stop_id)+1 FOR position('-' in stop_id) - position(':' in stop_id)-1), 
           arrival_time, 
           departure_time, 
           interpolated, 
           shape_dist_traveled, 
           timepoint, 
           pickup_type, 
           drop_off_type, 
           stop_headsign, 
           route_type 
    ORDER BY stop_times.trip_id, 
           stop_sequence, 
           arrival_time, 
           departure_time, 
           interpolated, 
           shape_dist_traveled, 
           timepoint, 
           pickup_type, 
           drop_off_type, 
           stop_headsign
); 


-- Agency
DELETE FROM tempus_gtfs.agency 
WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.agency
(
    SELECT DISTINCT ON (stop_times.feed_id, stop_times.agency_id) 
			'sncf', 
			agency.agency_id || ' - ' || agency.feed_id, 
			agency.agency_name || ' (' || agency.feed_id || ')', 
			agency_url, 
			agency_timezone, 
			agency_lang
    FROM tempus_access.stop_times JOIN tempus_gtfs.agency ON (stop_times.feed_id = agency.feed_id AND stop_times.agency_id = agency.agency_id)
); 

-- Routes
DELETE FROM tempus_gtfs.routes 
WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.routes (feed_id, route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color)
(
    SELECT DISTINCT ON (stop_times.feed_id, stop_times.route_id) 
			'sncf', 
			routes.route_id || ' - ' || routes.feed_id, 
			routes.agency_id || ' - ' || routes.feed_id, 
			route_short_name, 
			route_long_name, 
			stop_times.trip_type as route_desc, 
			routes.route_type, 
			route_url, 
			route_text_color
    FROM tempus_access.stop_times JOIN tempus_gtfs.routes ON (stop_times.feed_id = routes.feed_id AND stop_times.route_id = routes.route_id AND stop_times.agency_id = routes.agency_id)
    ORDER BY stop_times.route_id, stop_times.feed_id
);

-- Trips
DELETE FROM tempus_gtfs.trips 
WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.trips (feed_id, trip_id, route_id, service_id, shape_id, wheelchair_accessible, bikes_allowed, exact_times, frequency_generated, trip_headsign, trip_short_name, direction_id, block_id)
( 
    SELECT DISTINCT ON (stop_times.feed_id, stop_times.trip_id, trips.service_id) 
			'sncf' as feed_id, 
			stop_times.trip_id, 
			trips.route_id || ' - ' || trips.feed_id as route_id, 
			stop_times.service_id, 
			shape_id, 
			wheelchair_accessible, 
			bikes_allowed, 
			exact_times, 
			frequency_generated, 
			trip_type, 
			trip_short_name, 
			direction_id, 
			block_id
        FROM tempus_access.stop_times JOIN tempus_gtfs.trips ON (stop_times.feed_id = trips.feed_id AND stop_times.trip_id = trips.trip_id) 
        WHERE stop_times.feed_id = any(ARRAY['ter', 'ic'])
    ORDER BY stop_times.feed_id, stop_times.trip_id, trips.service_id DESC  
);

-- Stops
UPDATE tempus_gtfs.stops
SET artificial_road_section=FALSE
WHERE feed_id = any(ARRAY['ter', 'ic']); 

DELETE FROM tempus_gtfs.stops 
WHERE feed_id = 'sncf';
INSERT INTO tempus_gtfs.stops (
				feed_id, 
				stop_id, 
				parent_station_id, 
				location_type, 
				stop_name, 
				stop_lat, 
				stop_lon, 
				wheelchair_boarding, 
				stop_code, 
				stop_desc, 
				zone_id, 
				stop_url, 
				stop_timezone, 
				geom, 
				road_section_id, 
				abscissa_road_section, 
				artificial_road_section)
(       
        SELECT DISTINCT ON (CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) END, substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8))
                'sncf', 
                CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) END AS stop_id, 
                substring(stops.parent_station_id FROM length(stops.parent_station_id) - 7 FOR 8) as parent_station_id, 
                stops.location_type, 
                stops.stop_name, 
                stops.stop_lat, 
                stops.stop_lon, 
                stops.wheelchair_boarding, 
                stops.stop_code, 
                stops.stop_desc, 
                stops.zone_id, 
                stops.stop_url, 
                stops.stop_timezone, 
                st_force3d(
				CASE WHEN (stops.parent_station_id IS NOT NULL) AND (stop_times.new_stop_id LIKE '%-%')
					THEN st_setsrid(st_makepoint(st_x(stops.geom)--+0.0001*stop_times.route_type
								   , st_y(stops.geom)), 4326) 
				     ELSE stops.geom
			        END
		          ) as geom, 
                road_section_id, 
                abscissa_road_section, 
                artificial_road_section
        FROM tempus_access.stop_times RIGHT JOIN tempus_gtfs.stops ON substring(stop_times.new_stop_id FROM 1 FOR 8) = substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
        WHERE stops.feed_id = any(ARRAY['ter', 'ic']) AND (CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) END IS NOT NULL)
        ORDER BY CASE WHEN stops.parent_station_id IS NOT NULL THEN stop_times.new_stop_id ELSE substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8) END, substring(stops.stop_id FROM length(stops.stop_id) - 7 FOR 8)
); 


UPDATE tempus_gtfs.stops
SET geom = st_force3d(CASE WHEN (stops.parent_station_id IS NOT NULL) AND (stops.stop_id LIKE '%-%') THEN st_setsrid(st_makepoint(st_x(ref_stops.geom)--+0.0001*substring(stops.stop_id from length(stops.stop_id) for 1)::integer
																, st_y(ref_stops.geom)), 4326) 
                           ELSE ref_stops.geom
                      END), stop_name = ref_stops.stop_name
FROM tempus_access.stops ref_stops
WHERE stops.feed_id = 'sncf' AND ref_stops.feed_id = 'sncf' AND (substring(stops.stop_id FROM 1 FOR 8)=ref_stops.stop_id) ; 

UPDATE tempus_gtfs.stops
SET stop_lon = st_x(geom), stop_lat =st_y(geom); 



-- Insert artificial road sections
-- 1. attach each stop to the closest road section in a 50 meters radius
--

-- first, create an index on road_section geography 
create index on tempus.road_section using gist(geography(geom));

-- reset sequences
drop sequence if exists tempus.seq_road_node_id;
create sequence tempus.seq_road_node_id start with 1;
select setval('tempus.seq_road_node_id', (select max(id) from tempus.road_node));

drop sequence if exists tempus.seq_road_section_id;
create sequence tempus.seq_road_section_id start with 1;
select setval('tempus.seq_road_section_id', (select max(id) from tempus.road_section));

create or replace function notice(msg text, data anyelement)
returns anyelement
language plpgsql
as $$
begin
  raise notice 'notice % %', msg, data;
  return data;
end;
$$;

do $$
declare
  l_road_section_id bigint;
  l_node1_id bigint;
  l_node2_id bigint;
  l_abscissa_road_section float8;
  l_artificial boolean;
  stop record;
begin
  -- Use a loop here in order to make sure stops are compared to road sections
  -- while new road sections are created.
  for stop in
    select * from tempus_gtfs.stops where feed_id = 'sncf'
  loop
    l_road_section_id := null;
    -- get the closest road section (if any)
    select
      into l_road_section_id, l_abscissa_road_section, l_artificial
    road_section_id, abscissa, false
    from
    (
      select
        rs.id as road_section_id
        , st_linelocatepoint(rs.geom, stop.geom) as abscissa
        , false
        , st_distance(rs.geom, stop.geom) dist
      from
        tempus.road_section rs
      where
        st_dwithin(geography(stop.geom), geography(rs.geom), 50)
        -- attach to roads waklable by pedestrians
        and
          ((rs.traffic_rules_ft & 1) > 0
            or (rs.traffic_rules_tf & 1) > 0)
      order by
        dist
      limit 1
    ) t
    ;

    if l_road_section_id is null then
      -- no section, create a fake one, from the stop geometry
      l_road_section_id := nextval('tempus.seq_road_section_id');
      l_abscissa_road_section := 0.5;
      l_artificial := true;
      l_node1_id := nextval('tempus.seq_road_node_id')::bigint;
      l_node2_id := nextval('tempus.seq_road_node_id')::bigint;

      -- new nodes
      insert into tempus.road_node
      select
        l_node1_id
        , false as bifurcation
        , st_translate(stop.geom, -0.0001, 0, 0)
      union all
      select
        l_node2_id
        , false as bifurcation
        , st_translate(stop.geom, +0.0001, 0, 0)
      ;

      -- new section
      insert into tempus.road_section
        (id, road_type, node_from, node_to, traffic_rules_ft, traffic_rules_tf, length, car_speed_limit, road_name, lane, roundabout, bridge, tunnel, ramp, tollway, geom)
      select
        l_road_section_id
        , 1 as road_type
        , l_node1_id as node_from
        , l_node2_id as node_to
        , 32767 as traffic_rules_ft
        , 32767 as traffic_rules_tf
        , 0 as length
        , 0 as car_speed_limit
        , '' as road_name
        , 1 as lane
        , false as roundabout
        , false as bridge
        , false as tunnel
        , false as ramp
        , false as tollway
        , st_makeline(st_translate(stop.geom, -0.0001, 0, 0),
                      st_translate(stop.geom, +0.0001, 0, 0))
      ;
    end if;

    -- attach the stop to the road section
    update
      tempus_gtfs.stops
    set
      road_section_id = l_road_section_id
      , abscissa_road_section = l_abscissa_road_section
      , artificial_road_section = l_artificial
    where
      id = stop.id;
  end loop;    
end;
$$;


drop index tempus.road_section_geography_idx;

-- Delete artificial road sections which are no longer used
DELETE FROM tempus.road_section
  WHERE id not in (select distinct road_section_id from tempus_gtfs.stops);


-- Calendar
DELETE FROM tempus_gtfs.calendar WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.calendar(feed_id, service_id)
(
    SELECT DISTINCT 'sncf', service_id
    FROM tempus_access.stop_times
);

-- Calendar dates
DELETE FROM tempus_gtfs.calendar_dates WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.calendar_dates(feed_id, service_id, date)
(
    SELECT DISTINCT 'sncf', stop_times.service_id, calendar_dates.date
    FROM tempus_access.stop_times JOIN tempus_gtfs.calendar_dates ON (calendar_dates.service_id || ' - ' || calendar_dates.feed_id = split_part(stop_times.service_id, ';', 1)) 
    WHERE calendar_dates.feed_id = any(ARRAY['ter', 'ic'])
    UNION DISTINCT
    SELECT DISTINCT 'sncf', stop_times.service_id, calendar_dates.date
    FROM tempus_access.stop_times JOIN tempus_gtfs.calendar_dates ON (calendar_dates.service_id || ' - ' || calendar_dates.feed_id = split_part(stop_times.service_id, ';', 2)) 
    WHERE calendar_dates.feed_id = any(ARRAY['ter', 'ic'])	
);

-- Stop times
DELETE FROM tempus_gtfs.stop_times 
WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.stop_times(feed_id, trip_id, stop_sequence, stop_id, arrival_time, departure_time, interpolated, shape_dist_traveled, timepoint, pickup_type, drop_off_type, stop_headsign)
(
    SELECT 'sncf', trip_id, stop_sequence, new_stop_id, arrival_time, departure_time, interpolated, shape_dist_traveled, timepoint, pickup_type, drop_off_type, stop_headsign
    FROM tempus_access.stop_times
    ORDER BY trip_id, stop_sequence
); 

-- Création des sections en ligne droite
DELETE FROM tempus_gtfs.sections WHERE feed_id IN (SELECT id FROM tempus_gtfs.feed_info WHERE feed_id = 'sncf'); 
INSERT INTO tempus_gtfs.sections (feed_id, stop_from, stop_to, geom)
(
    SELECT
      (select id from tempus_gtfs.feed_info WHERE feed_id = 'sncf')
      , st1.id
      , st2.id
      , st_makeline(st1.geom, st2.geom)
    FROM
    (
        SELECT DISTINCT ON (st1.new_stop_id, st2.new_stop_id)
          st1.new_stop_id as stop1, 
          st2.new_stop_id as stop2
        FROM tempus_access.stop_times st1 JOIN tempus_access.stop_times st2 ON ((st1.trip_id = st2.trip_id) and (st1.feed_id = st2.feed_id) and (st2.stop_sequence = st1.stop_sequence + 1))
    ) t
    JOIN tempus_gtfs.stops st1 on st1.stop_id = t.stop1 AND st1.feed_id = 'sncf'
    JOIN tempus_gtfs.stops st2 on st2.stop_id = t.stop2 AND st2.feed_id = 'sncf'
); 

-- Transfers
DELETE FROM tempus_gtfs.transfers WHERE feed_id = 'sncf'; 
INSERT INTO tempus_gtfs.transfers(feed_id, from_stop_id, to_stop_id, transfer_type, min_transfer_time)
(
    -- From stop to stop : 10 minutes
    SELECT stops1.feed_id, stops1.stop_id as stop_id_from, stops2.stop_id as stop_id_to, 2, 10*60
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = 'sncf' AND stops1.parent_station_id = stops2.parent_station_id AND stops1.stop_id != stops2.stop_id
)
UNION
(
    -- From stop to stop area : 0 minutes
    SELECT stops1.feed_id, stops1.stop_id as stop_id_from, stops2.stop_id as stop_id_to, 2, 0
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = 'sncf' AND stops1.parent_station_id = stops2.stop_id
)
UNION
(
    -- From stop area to stop : 10 minutes
    SELECT stops1.feed_id, stops1.stop_id as stop_id_from, stops2.stop_id as stop_id_to, 2, 10*60
    FROM tempus_gtfs.stops stops1, tempus_gtfs.stops stops2
    WHERE stops1.feed_id = stops2.feed_id AND stops1.feed_id = 'sncf' AND stops1.stop_id = stops2.parent_station_id
)
ORDER BY stop_id_from, stop_id_to; 


-- Shapes will be built after retracing train sections

INSERT INTO tempus.transport_mode(id, name, public_transport, gtfs_route_type, gtfs_feed_id)
SELECT nextval('transport_mode_id_seq'), 'Tram', True, 0, (select id from tempus_gtfs.feed_info WHERE feed_id = 'sncf') as gtfs_feed_id
union
select nextval('transport_mode_id_seq'), 'Train', True, 2, (select id from tempus_gtfs.feed_info WHERE feed_id = 'sncf')
union 
select nextval('transport_mode_id_seq'), 'Bus', True, 3, (select id from tempus_gtfs.feed_info WHERE feed_id = 'sncf')
union
select nextval('transport_mode_id_seq'), 'Funicular', True, 7, (select id from tempus_gtfs.feed_info WHERE feed_id = 'sncf'); 

DROP TABLE tempus_access.stop_times;

REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode;
REFRESH MATERIALIZED VIEW tempus_access.sections_by_mode;
REFRESH MATERIALIZED VIEW tempus_access.trips_by_mode;
