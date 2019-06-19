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

from importer import ZipImporter

# Fast GTFS Importer
class ImportPTGTFS(ZipImporter):
    """Public transportation GTFS data loader class."""
    # SQL files to execute before loading GTFS data
    PRELOADSQL = ["import_pt_gtfs_pre_load.sql" ]
    # List of text files to load: the second argument says if the file is mandatory or not
    DBFSHAPEFILES = []
    CSVFILES = [('agency', False),
                ('calendar', True),
                ('calendar_dates', True),
                ('fare_attributes', False),
                ('fare_rules', False),
                ('feed_info', False), 
                ('frequencies', False),
                ('transfers', False),
                ('routes', True),
                ('shapes', False),
                ('stop_times', True),
                ('stops', True),
                ('trips', True)]
    # SQL files to execute after loading GTFS data 
    POSTLOADSQL = [ "import_pt_gtfs.sql", "import_pt_post_load.sql" ]


class ImportPTGTFSTemp(ZipImporter):
    """Public transportation GTFS temporary data loader class. No cleaning after loading. """
    PRELOADSQL = ["import_pt_gtfs_pre_load.sql" ]
    # List of text files to load: the second argument says if the file is mandatory or not
    DBFSHAPEFILES = []
    CSVFILES = [('agency', False),
                ('calendar', True),
                ('calendar_dates', True),
                ('fare_attributes', False),
                ('fare_rules', False),
                ('feed_info', False), 
                ('frequencies', False),
                ('transfers', False),
                ('routes', True),
                ('shapes', False),
                ('stop_times', True),
                ('stops', True),
                ('trips', True)]
    POSTLOADSQL = [ "import_pt_gtfs.sql" ]

