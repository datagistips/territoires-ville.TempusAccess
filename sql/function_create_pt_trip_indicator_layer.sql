CREATE OR REPLACE FUNCTION tempus_access.create_pt_trip_indicator_layer(
                                                                           indics integer[],
                                                                           gtfs_feeds integer[],
                                                                           route_types integer[], 
                                                                           agencies integer[], 
                                                                           day date,
                                                                           day_type integer,
                                                                           per_type integer, 
                                                                           per_start date, 
                                                                           per_end date, 
                                                                           day_ag integer,
                                                                           time_start time,
                                                                           time_end time, 
                                                                           time_ag integer,
                                                                           area_type integer, 
                                                                           areas character varying[],
                                                                           route integer, 
                                                                           stop_area integer
                                                                       )
  RETURNS void AS
$BODY$
DECLARE
    s character varying;
    t character varying; 
    indics_time_ag character varying;
    indics_day_ag character varying;
    from_table_day_ag character varying;
    join_area character varying; 
    r record;
    
    time_filter character varying;
    areas_filter character varying;
    routes_filter character varying;
    stops_filter character varying;

    indics_str character varying;
    area2 boolean;

BEGIN
    -- Obligatory parameters
    IF (array_length(gtfs_feeds, 1)=0 OR array_length(route_types, 1)=0 OR array_length(agencies, 1)=0 OR array_length(indics, 1)=0)
    THEN RAISE EXCEPTION 'Parameters 1, 2, 3 and 4 must be non-empty arrays';
    END IF;
    
    -- Facultative parameters
    
    -- Areas filter
    IF (area_type = -1 OR array_length(areas, 1)=0 OR areas IS NULL)
    THEN areas_filter = $$$$;
    ELSE areas_filter = $$ 
                        AND trips.id IN 
                        (
                            SELECT trips.id
                            FROM tempus_gtfs.trips JOIN tempus_gtfs.stop_times ON (trips.trip_id = stop_times.trip_id AND trips.feed_id = stop_times.feed_id )
                                                   JOIN tempus_gtfs.stops ON (stop_times.stop_id = stops.stop_id AND stop_times.feed_id = stops.feed_id)
                            WHERE stops.id IN 
                            (
                                SELECT stops.id
                                FROM tempus_gtfs.stops JOIN tempus_access.area_type$$ || area_type::character varying || $$ area ON st_within(stops.geom, area.geom)
                                WHERE ARRAY[area.char_id] <@ '$$ || areas::character varying || $$'
                            )
                        )
                        $$;
    END IF;
    
    -- Routes filter : trips must belong to the specified routes
    IF (route IS NULL)
    THEN routes_filter = $$$$;
    ELSE routes_filter = $$ 
                         AND routes.id = $$ || route::character varying || $$
                         $$;
    END IF;
    
    -- Stops filter : selected trips must serve at least one stop of the parameter set
    IF (stop_area IS NULL)
    THEN stops_filter = $$$$;
    ELSE stops_filter = $$ 
                        AND trips.id IN 
                        (
                            SELECT trips.id
                            FROM tempus_gtfs.trips JOIN tempus_gtfs.stop_times ON (trips.trip_id = stop_times.trip_id AND trips.feed_id = stop_times.feed_id)
                                                   JOIN tempus_gtfs.stops ON (stop_times.stop_id = stops.stop_id AND stop_times.feed_id = stops.feed_id)
                            WHERE ((stops.feed_id, stops.parent_station_id) = (SELECT feed_id, stop_id FROM tempus_gtfs.stops WHERE id = $$ || stop_area::character varying || $$)) 
                        ) 
                        $$ ;
    END IF;
    
    -- Time filter
    IF (time_start IS NULL OR time_end IS NULL)
    THEN time_filter = $$(1=1)$$;
    ELSE time_filter = $$((s.departure_time <= extract(epoch FROM INTERVAL '$$ || time_end::character varying || $$') AND (s.departure_time >= extract(epoch FROM INTERVAL '$$ || time_start::character varying || $$'))))$$;
    END IF; 
    
    indics_time_ag = ''; 
    indics_day_ag = ''; 
    join_area = '';
    indics_str='';
    
    CREATE SCHEMA IF NOT EXISTS indic;
    
    area2 = False;
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        if (r.col_name = 'serv_num') -- Number of services
        THEN 
            indics_time_ag = indics_time_ag  || '(count(distinct trip_id))::integer as serv_num, '; 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(serv_num)::double precision as serv_num, ';
        END IF; 
        
        IF (r.col_name = 'first_serv') -- First service
        THEN 
            indics_time_ag = indics_time_ag || 'min(departure_times[1]) as first_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(first_serv))::character varying || '' seconds'')::interval)::character varying as first_serv, '; 
        END IF;
        
        IF (r.col_name = 'last_serv') -- Last service
        THEN 
            indics_time_ag = indics_time_ag || 'max(departure_times[1]) as last_serv, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv))::character varying || '' seconds'')::interval)::character varying as last_serv, ';
        END IF;
        
        IF (r.col_name = 'time_ampl') -- Time amplitude
        THEN 
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(last_serv-first_serv)/3600::double precision as time_ampl, ';
        END IF;
        
        IF (r.col_name = 'total_time') -- Total travel time
        THEN 
            indics_time_ag = indics_time_ag || (CASE WHEN time_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = time_ag) END)::character varying || '(arrival_times[array_length(all_stops,1)]-departure_times[1]) as total_time, ';
            indics_day_ag = indics_day_ag || '(((' || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(total_time))::character varying || '' seconds'')::interval)::character varying as total_time, ';
        END IF; 
        
        IF (r.col_name = 'total_dist') -- Total distance
        THEN 
            indics_time_ag = indics_time_ag || 'st_length(st_transform(q.geom, 2154))/1000 as total_dist, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(total_dist) as total_dist, '; 
        END IF;
        
        IF (r.col_name = 'veh_km') -- Vehicle.km
        THEN
            indics_time_ag = indics_time_ag || '(st_length(st_transform(q.geom, 2154))/1000*count(distinct trip_id)) as veh_km, ';
            indics_day_ag = indics_day_ag || (CASE WHEN day_ag IS NULL THEN 'avg' ELSE (SELECT func_name FROM tempus_access.agregates WHERE code = day_ag) END)::character varying || '(veh_km) as veh_km, '; 
        END IF; 
        
        IF ((area2 = False) AND ((r.col_name = 'area2_list') OR (r.col_name = 'area2_pop'))) -- List of type 2 areas 2 served by public transport
        THEN
            area2=True;
            indics_str = ', array_agg(DISTINCT char_id ORDER BY char_id) AS area2_list';
            join_area = ' LEFT JOIN tempus_access.area_type2 area ON (st_within(stops.geom, area.geom)) ';   
            indics_time_ag = indics_time_ag || 'min(area2_list) as area2_list, ';
            indics_day_ag = indics_day_ag || 'min(area2_list) as area2_list, '; 
        END IF;        
        
    END LOOP;
    
    indics_day_ag = substring(indics_day_ag from 1 for length(indics_day_ag) - 2);
    indics_time_ag = substring(indics_time_ag from 1 for length(indics_time_ag) - 2);
    
    s = $$
    DROP TABLE IF EXISTS indic.trips; 
    CREATE TABLE indic.trips AS
    (
        WITH r AS (
             WITH q AS (
                -- Apply filters
                SELECT s.feed_id, 
                       trips.trip_id, 
                       routes.route_long_name, 
                       agency.agency_name, 
                       routes.route_type, 
                       calendar_dates.date, 
                       shapes.geom_multi as geom, 
                       array_agg(stops.stop_name order by stop_sequence) as all_stops, 
                       array_agg(s.departure_time order by stop_sequence) as departure_times, 
                       array_agg(s.arrival_time order by stop_sequence) as arrival_times
                       $$ || indics_str || $$ -- Communes
                FROM tempus_gtfs.stop_times s JOIN tempus_gtfs.stops ON (s.feed_id = stops.feed_id AND s.stop_id = stops.stop_id)
                                              JOIN tempus_gtfs.trips ON (s.feed_id = trips.feed_id AND s.trip_id = trips.trip_id)
                                              JOIN tempus_gtfs.routes ON (routes.route_id = trips.route_id AND routes.feed_id = trips.feed_id)
                                              JOIN tempus_gtfs.shapes ON (shapes.feed_id = trips.feed_id AND shapes.shape_id = trips.shape_id)
                                              JOIN tempus_gtfs.calendar_dates ON (calendar_dates.feed_id = trips.feed_id AND calendar_dates.service_id = trips.service_id)
                                              JOIN tempus_gtfs.agency ON (agency.feed_id = routes.feed_id AND agency.agency_id = routes.agency_id)
                                              $$ || join_area || $$ 
                WHERE stops.feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ '$$ || gtfs_feeds::character varying || $$') -- GTFS feeds filter
                  AND ARRAY[routes.route_type] <@ '$$ || route_types::character varying || $$' -- Route types filter
                  AND ARRAY[agency.id] <@ '$$ || agencies::character varying || $$' -- Agencies filter
                  AND ARRAY[calendar_dates.date] <@ '$$ || (SELECT array_agg(days) FROM tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$' -- Days filter
                  AND $$ || time_filter || $$ -- Time filter
                  $$ || areas_filter || $$ -- Facultative : areas filter
                  $$ || routes_filter || $$ -- Facultative : routes filter
                  $$ || stops_filter || $$ -- Facultative : stops filter
                GROUP BY s.feed_id, 
                         trips.trip_id, 
                         routes.route_type, 
                         routes.route_long_name, 
                         agency.agency_name, 
                         calendar_dates.date, 
                         shapes.geom_multi
            )
            -- Aggregate day by day
            ( -- Mode by mode
                SELECT feed_id, 
                       all_stops, 
                       route_type, 
                       route_long_name, 
                       agency_name, 
                       date, 
                       q.geom, 
                       $$ || indics_time_ag || $$ 
                FROM q 
                GROUP BY feed_id, all_stops, route_type, route_long_name, agency_name, date, q.geom
            )
        ) 
        SELECT row_number() over() as gid, 
               feed_id, 
               all_stops, 
               route_type, 
               route_long_name, 
               agency_name, 
               geom as the_geom, 
               $$ || indics_day_ag || $$ 
        FROM r
        GROUP BY feed_id, all_stops, geom, route_type, route_long_name, agency_name
    );
    
    ALTER TABLE indic.trips ADD COLUMN symbol_size real;
    ALTER TABLE indic.trips ADD COLUMN symbol_color real;
    ALTER TABLE indic.trips ADD CONSTRAINT trips_pkey PRIMARY KEY(gid);
    $$; 
    
    RAISE NOTICE '%', s; 
    EXECUTE(s);
    
    FOR r IN (SELECT col_name FROM tempus_access.indicators WHERE ARRAY[code] <@ indics)
    LOOP
        IF (r.col_name = 'area2_pop')
        THEN
            t=$$ALTER TABLE indic.trips ADD COLUMN area2_pop double precision;
            UPDATE indic.trips SET area2_pop = q.population
            FROM
            (
                SELECT trips.gid, sum(area.population) as population
                FROM indic.trips JOIN tempus_access.area_type2 area ON ARRAY[area.char_id] <@ trips.area2_list
                GROUP BY trips.gid
            ) q
            WHERE q.gid = trips.gid;
            UPDATE indic.trips SET area2_pop = NULL WHERE TRUE = ANY (SELECT unnest(area2_list) IS NULL);
            $$;
            EXECUTE(t);
            RAISE NOTICE '%', t; 
        END IF; 
    END LOOP; 
    
    
    
    t=$$DELETE FROM tempus_access.indic_catalog WHERE layer_name = 'trips';
    INSERT INTO tempus_access.indic_catalog(layer_name,obj_type,indics,days,day_type,per_type,per_start,per_end,day_ag,time_start,time_end,time_ag,area_type,areas,route,stop,gtfs_feeds,agencies,pt_modes,req)
    VALUES ('trips', 
           (SELECT code FROM tempus_access.obj_type WHERE def_name = 'trips')::character varying, 
           $$ || coalesce($$'$$ || indics::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || (SELECT tempus_access.days(day, day_type, per_type, per_start, per_end))::character varying || $$'$$, $$NULL$$) || $$::date[], 
           $$ || coalesce(day_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(per_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || per_start::character varying || $$'$$, $$NULL$$)|| $$::date, 
           $$ || coalesce($$'$$ || per_end::character varying || $$'$$, $$NULL$$) || $$::date,
           $$ || coalesce(day_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || time_start::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce($$'$$ || time_end::character varying || $$'$$, $$NULL$$) || $$::time, 
           $$ || coalesce(time_ag::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce(area_type::character varying, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || areas::character varying|| $$'$$, $$NULL$$) || $$::character varying[], 
           $$ || coalesce($$'$$ || route::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || stop_area::character varying || $$'$$, $$NULL$$) || $$::integer, 
           $$ || coalesce($$'$$ || gtfs_feeds::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           $$ || coalesce($$'$$ || agencies::character varying || $$'$$, $$NULL$$) || $$::integer[], 
           (SELECT array_agg(id) AS pt_modes FROM tempus.transport_mode WHERE array[gtfs_route_type]<@ '$$ || route_types::character varying || $$' and array[gtfs_feed_id] <@ '$$ || gtfs_feeds::character varying || $$')::integer[], 
           '$$ || replace(s, $$'$$, $$''$$) || $$' );$$;
        RAISE NOTICE '%', t;
    EXECUTE(t);
    
    
    RETURN;
END; 

$BODY$
LANGUAGE plpgsql; 

