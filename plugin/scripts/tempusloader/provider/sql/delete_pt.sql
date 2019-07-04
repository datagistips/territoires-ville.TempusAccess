-- Tempus - PT delete Wrapper
-- Parameter %(source_name) : PT network name to delete

-- Predelete


-- Delete
DELETE FROM tempus_gtfs.feed_info
WHERE feed_id = '%(source_name)';

DELETE FROM tempus.road_network
WHERE name = 'transfers_%(source_name)';


-- Postdelete



VACUUM FULL ANALYSE;


