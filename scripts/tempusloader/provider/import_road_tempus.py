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

import os
import sys

from importer import ShpImporter

class ImportRoadTempus(ShpImporter):
    """This class enables to load IGN data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = [ 'road_nodes', 'road_sections' ]
    OPT_SHAPEFILES = [ 'time_periods', 'time_penalties', 'tolls' ]
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_road_tempus.sql','import_road_post_load.sql']

