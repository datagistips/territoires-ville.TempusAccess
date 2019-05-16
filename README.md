# TempusAccess
TempusAccess est un plugin QGIS, distribué sous [licence GPL](https://github.com/CEREMA/territoires-ville.TempusAccess/blob/master/LICENSE), de calcul d'**indicateurs d'accessibilité des territoires permise par l'offre de transport** (disponible aux formats GTFS et géographiques).
 
# Atouts
Ses principaux atouts sont : 
* le **calcul** d'indicateurs d'offre de transport via une interface utilisateur ergonomique ;
* le **requêtage** direct, en SQL, de la base PostgreSQL sous-jacente, au moyen de fonctions dédiées, ce qui permet de lancer des requêtes plus complexes et de réaliser des traitements par lots qui seraient fastidieux à réaliser via l'interface utilisateur ;
* l'intégration de nombreux **formats** de données acceptés en entrée du plugin : GTFS, Visum, IGN, OpenStreetMap, permettant l'intégration facilitée de multiples sources dans la base ;
* une **représentation cartographique** automatique de base des indicateurs (quand ils ont une dimension géographique), personnalisable ensuite selon les souhaits de l'utilisateur grâce aux fonctions classiques de QGIS.

## Routing et filtrage
Parmi les indicateurs proposés, certains font appel à des **calculs de plus court chemin** au sens du temps de parcours, avec prise en compte des **itinéraires multimodaux** (itinéraire le plus court entre deux points, isochrone au départ d'un ou plusieurs points, etc.). 

Il est possible de **filtrer** la période horaire, les jours, de même que les arrêts, certaines lignes, sur lesquels le calcul d'indicateurs portera.

# Documentation
La documentation complète se situe dans le [wiki](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki) !
