-- Tempus - Road Tempus SQL import Wrapper
 /*
        Substitutions options
        %(source_name): name of the road network
*/

INSERT INTO tempus.road_network(name)
VALUES('%(source_name)');