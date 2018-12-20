#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2012-2013 IFSTTAR (http://www.ifsttar.fr)
 *   Copyright (C) 2012-2013 Oslandia <infos@oslandia.com>
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Library General Public
 *   License as published by the Free Software Foundation; either
 *   version 2 of the License, or (at your option) any later version.
 *   
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Library General Public License for more details.
 *   You should have received a copy of the GNU Library General Public
 *   License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */
"""

#
# Tempus data loader



import os
import sys

from importer import ShpImporter

# Module to load IGN road data (Route120, Route500, ...)
class ImportRoadIGNRoute120_1_1(ShpImporter):
    """This class enables to load IGN Route120 data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['troncon_route','communication_restreinte']
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_road_ign_route120_1_1.sql','import_road_post_load.sql']

class ImportRoadIGNRoute500_2_1(ShpImporter):
    """This class enables to load IGN Route500 data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['troncon_route','communication_restreinte']
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_road_ign_route500_2_1.sql','import_road_post_load.sql']

class ImportRoadIGNBDTopo_2_2(ShpImporter):
    """This class enables to load IGN data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['route']
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_road_ign_bdtopo_2_2.sql','import_road_post_load.sql']

class ImportRoadIGNBDCarto_3_2(ShpImporter):
    """This class enables to load IGN data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['troncon_route','communication_restreinte']
    # SQL files to execute before loading shapefiles
    PRELOADSQL = [ 'import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_road_ign_bdcarto_3_2.sql','import_road_post_load.sql']

    