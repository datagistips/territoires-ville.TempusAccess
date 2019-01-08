#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2012-2017 Oslandia <infos@oslandia.com>
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

import re
import sys
import os
import zipfile
import tempfile
import csv
import sys
import logging
from logging import StreamHandler
from gtfslib.dao import Dao
from dbtools import PsqlLoader
from importer import ShpImporter
from tools import is_numeric
from importer import DataImporter
from config import *

def parse_db_string(param):
    """
    Parse the parameter string as a PostgreSQL db connection string or an URI
    And return a pair of strings with both representations (db_string, db_uri)
    """
    if param.startswith("postgresql://"):
        # from uri to connection string
        from urlparse import urlparse
        p = urlparse(param)
        db_string = [('host', p.hostname),
                     ('port', str(p.port)),
                     ('username', p.username),
                     ('password', p.password),
                     ('dbname', p.path)]
        return (" ".join([k + "=" + v for k,v in db_string]), param)
    else:
        db_params = dict([(k,v.strip("'")) for k,v in re.findall(r"(\S+) *= *('.*?'|\S+)", param)])
        db_host = db_params.get("host") or ""
        db_port = ""
        if db_params.get("port"):
            db_port = db_port + ":" + db_params["port"]
        db_name = db_params.get("dbname") or ""
        host_port = db_host + db_port
        s = ''
        if db_params.get("username"):
            s = db_params["username"]
            if db_params.get("password"):
                s = s + ':' + db_params['password']
            s = s + "@"
        db_uri = "postgresql://" + s + host_port + "/" + db_name
        return (param, db_uri)
        

# Fast GTFS Importer
class ImportPTGTFS(DataImporter):
    """Public transportation GTFS data loader class."""
    # SQL files to execute before loading GTFS data
    PRELOADSQL = ["import_pt_pre_load.sql" ]
    # List of text files to load: the second argument says if the file is mandatory or not
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

    
class ImportPTGTFSTemp(DataImporter):
    """Public transportation GTFS temporary data loader class. No cleaning after loading. """
    PRELOADSQL = ["import_pt_pre_load.sql" ]
    # List of text files to load: the second argument says if the file is mandatory or not
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


