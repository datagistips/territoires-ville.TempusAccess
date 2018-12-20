
-- Feed info
DELETE FROM tempus_gtfs.feed_info 
WHERE feed_id = '%(source_name)'; 

-- store the last feed id
create temp table _last_feed as
select
  feed_id
  , id
from
  tempus_gtfs.feed_info
where
  id = (select max(id) from tempus_gtfs.feed_info);

--
-- compute stop geometries
do $$
begin
raise notice '==== compute stop geometries ===';
end$$;

update
  tempus_gtfs.stops
set
  geom = st_setsrid(st_makepoint(stop_lon, stop_lat, 0), 4326)
;

do $$
begin
raise notice '==== road section spatial matching ===';
end$$;

--
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
    select * from tempus_gtfs.stops where feed_id = (select feed_id from _last_feed limit 1)
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


do $$
begin
raise notice '==== add new transport modes ===';
end$$;

--
-- Create new transport modes
--
drop sequence if exists transport_mode_id_seq;
create sequence transport_mode_id_seq start with 1;
select setval('transport_mode_id_seq', (select max(id) from tempus.transport_mode));

insert into tempus.transport_mode(id, name, public_transport, gtfs_route_type, gtfs_feed_id)
select
        nextval('transport_mode_id_seq') as id
        , (case
        when r.route_type = 0 then 'Tram'
        when r.route_type = 1 then 'Subway'
        when r.route_type = 2 then 'Train'
        when r.route_type = 3 then 'Bus'
        when r.route_type = 4 then 'Ferry'
        when r.route_type = 5 then 'Cable-car'
        when r.route_type = 6 then 'Suspended Cable-Car'
        when r.route_type = 7 then 'Funicular'
        end) || ' (' || (select feed_id from _last_feed limit 1) || ')'
	, true
	, r.route_type
        , (select id from _last_feed limit 1)
from (
  select distinct route_type from tempus_gtfs.routes
  -- only routes from last feed
  where feed_id = (select feed_id from _last_feed limit 1)
) r
;


do $$
begin
raise notice '==== compute shapes ===';
end$$;

update
  tempus_gtfs.shapes
set
  geom = t.geom
from
(
  select
    shape_id
    , st_makeline(array_agg(st_setsrid(st_makepoint(shape_pt_lon, shape_pt_lat, 0.0), 4326) order by shape_pt_sequence)) as geom
  from
    tempus_gtfs.shape_pts
  group by
    shape_id
) t
where
  shapes.shape_id = t.shape_id
  and shapes.feed_id = (select feed_id from _last_feed limit 1)
;

do $$
begin
raise notice '==== compute sections ===';
end$$;

insert into tempus_gtfs.sections (feed_id, stop_from, stop_to, geom)
select
  (select id from _last_feed limit 1)
  , st1.id
  , st2.id
  , st_makeline(st1.geom, st2.geom)
from
(  
select
  distinct on (st1.stop_id, st2.stop_id)
  st1.stop_id as stop1
  , st2.stop_id as stop2
from
  tempus_gtfs.stop_times st1
  join tempus_gtfs.stop_times st2 on (st1.trip_id = st2.trip_id) and (st1.feed_id = st2.feed_id) and (st2.stop_sequence = st1.stop_sequence + 1)
where
  st1.feed_id = (select feed_id from _last_feed limit 1)
) t
join tempus_gtfs.stops st1 on st1.stop_id = stop1
join tempus_gtfs.stops st2 on st2.stop_id = stop2
;

