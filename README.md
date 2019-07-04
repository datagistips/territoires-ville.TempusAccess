# <img src="https://github.com/CEREMA/territoires-ville.TempusAccess/blob/master/plugin/icons/icon_tempus.jpg" alt="Icone Tempus Access" width="40"/> TempusAccess
**TempusAccess** est un plugin QGIS, distribué sous [licence GPL](https://github.com/CEREMA/territoires-ville.TempusAccess/blob/master/LICENSE), de calcul d'**indicateurs d'accessibilité des territoires permise par l'offre de transport** (disponible aux formats GTFS et géographiques).

![](https://github.com/CEREMA/territoires-ville.TempusAccess/raw/master/doc/img56.png)
 
## Un environnement applicatif très complet
Ses principaux atouts sont : 
* le **calcul** d'indicateurs d'offre de transport via une interface ergonomique
* le **requêtage** direct, en SQL, de la base PostgreSQL sous-jacente, au moyen de fonctions dédiées, ce qui permet de lancer des requêtes plus complexes et de réaliser des traitements par lots qui seraient fastidieux à réaliser via l'interface utilisateur et l'accès au panel très riche de fonctions de l'[**API Tempus**](https://oslandia.com/tag/tempus-fr/) d'Oslandia
* l'intégration de nombreux **formats** : GTFS, Visum, IGN, OpenStreetMap
* une **représentation cartographique** automatique des indicateurs (personnalisable selon les souhaits de l'utilisateur grâce aux fonctions classiques de QGIS)

## Des fonctions de routing et de requêtage embarquées
Parmi les indicateurs proposés, certains font appel à des **calculs de plus court chemin** au sens du temps de parcours, avec prise en compte des **itinéraires multimodaux** (itinéraire le plus court entre deux points, isochrone au départ d'un ou plusieurs points, etc.). 

Il est possible de **filtrer** la période horaire, les jours, de même que les arrêts, certaines lignes, sur lesquels le calcul d'indicateurs portera.

## Une liste très complète d'indicateurs d'accessibilité
TempusAccess calcule en un clic tout un lot d'indicateurs d'accessibilité très utiles, tels que le nombre de passages, l'amplitude horaire, le temps nécessaire pour rejoindre un arrêt depuis un autre..

[Accédez la liste complète d'indicateurs](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/Indicateurs-d'accessibilit%C3%A9)

## Documentation
:books: [Pour savoir comment l'installer et l'utiliser, rendez-vous sur le wiki](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki). Vous y trouverez [le guide de démarrage](https://github.com/CEREMA/territoires-ville.TempusAccess/wiki/Guide-de-d%C3%A9marrage)  !
