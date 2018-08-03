UPDATE tempus.road_section
SET traffic_rules_ft=13
WHERE traffic_rules_ft=5;

UPDATE tempus.road_section
SET traffic_rules_tf=13
WHERE traffic_rules_tf=13;

UPDATE tempus.road_section
SET traffic_rules_ft=12
WHERE traffic_rules_ft=4;

UPDATE tempus.road_section
SET traffic_rules_tf=12
WHERE traffic_rules_tf=12;

UPDATE tempus.transport_mode
SET name = 'Voiture sans contrainte de stationnement'
WHERE name='Taxi';

UPDATE tempus.transport_mode
SET name = 'Vélo'
WHERE name='Private bicycle';


UPDATE tempus.transport_mode
SET name = 'Voiture avec contrainte de dispo/stationnement'
WHERE name='Private car';

UPDATE tempus.transport_mode
SET name = 'Marche'
WHERE name='Walking';

