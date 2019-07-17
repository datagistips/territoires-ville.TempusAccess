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


from data_dir_manager import DataDirManager

class ImportRoadTempus(DataDirManager):
    """This class enables to load IGN data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    IMPORT_DBFSHPFILES = [ 
                           ('road_nodes', True), 
                           ('road_sections', True), 
                           ('time_periods', False), 
                           ('time_penalties', False), 
                           ('tolls', False) 
                         ]
    # SQL files to execute before loading shapefiles
    PRE_SQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POST_SQL = ['import_road_tempus.sql','import_road_post_load.sql']
    
    
    