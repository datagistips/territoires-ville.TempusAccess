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
La documentation complète se situe dans le wiki

La documentation disponible est la suivante \:
1. [Installation et configuration](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/(Fr)-1.-Installation-et-configuration) ;
2. [Gestion des données](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/(Fr)-2.-Gestion-des-donn%C3%A9es) ;
3. [Calcul des indicateurs](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/(Fr)-3.-Calcul-des-indicateurs) ;
4. [Affichage des indicateurs](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/(Fr)-4.-Affichage-des-indicateurs).

Vous pouvez consulter [ici](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/(Fr)-Sites-et-projets-li%C3%A9s) une liste de projets ou sites web en lien avec TempusAccess, notamment des plateformes fournissant des données GTFS sur l'offre de transport collectif.
