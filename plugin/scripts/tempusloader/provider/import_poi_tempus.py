#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2012-2013 IFSTTAR (http://www.ifsttar.fr)
 *   Copyright (C) 2012-2013 Oslandia <infos@oslandia.com>
 *   Copyright (C) 2019-2020 Cerema (http://www.cerema.fr) 
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

from importer import DataImporter

# Module to load a POI shape file
class ImportPOITempus(DataImporter):
    """This class enables to load POI data into a PostGIS database and link it to
    an existing network."""
    # Shapefile names to load, without the extension and prefix. 
    # Source shapefile set by user for this importer
    # this is used for table name
    DBFSHAPEFILES = [('poi', True)]
    CSVFILES = []
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ["import_poi_pre_load.sql"]
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ["import_poi_tempus.sql"]

