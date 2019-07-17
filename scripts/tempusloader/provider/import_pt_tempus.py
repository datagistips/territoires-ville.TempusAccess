#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2012-2017 Oslandia <infos@oslandia.com>
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

# GTFS Importer
class ImportPTTempus(DataDirManager):
    """Public transportation GTFS data loader class."""
    # SQL files to execute before loading GTFS data
    PRE_SQL = ["import_pt_tempus_pre_load.sql" ]
    # List of text files to load: the second argument says if the file is mandatory or not
    IMPORT_CSVTXTFILES = [
                            ('agency', True),
                            ('calendar_dates', True),
                            ('fare_attributes', False),
                            ('fare_rules', False),
                            ('frequencies', False),
                            ('transfers', False),
                            ('routes', True),
                            ('stop_times', True),
                            ('trips', True)
                         ]
    IMPORT_DBFSHPFILES = [
                            ('stops', True), 
                            ('sections', True), 
                            ('shapes', False)
                         ]
    # SQL files to execute after loading GTFS data 
    POST_SQL = [ "import_pt_tempus.sql", "import_pt_post_load.sql" ]


