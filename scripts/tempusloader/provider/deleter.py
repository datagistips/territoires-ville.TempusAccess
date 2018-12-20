#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2018-2019 Cerema (https://www.cerema.fr)
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
# Tempus data deleter

import os
import sys

from tools import ShpLoader
from dbtools import *
from config import *


# Base class for data importer
class DataDeleter(object):
    """
    This class enables deleting data from the Tempus PostgreSQL/PostGIS
    database. """
    # SQL files to execute to delete data
    SQL = []
    
    def __init__(self, dbstring="", logfile=None, subs = {}):
        self.dbstring = dbstring
        self.logfile = logfile
        self.ploader = PsqlLoader(dbstring=self.dbstring, logfile=self.logfile)
        self.substitutions = subs

    def run(self):
        ret = self.load_sqlfiles(self.SQL)
        if not ret:
            sys.stderr.write("Error during treatment.\n")
        return ret
        
    def load_sqlfiles(self, files, substitute = True):
        """Load some SQL files to the defined database.
        Stop if one was wrong."""
        ret = True
        is_template = substitute and len(self.substitutions) > 0
        for sqlfile in files:
            filename = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'sql', sqlfile)
            # Stop if one SQL execution was wrong
            if ret and os.path.isfile(filename):
                if is_template:
                    f = open(filename, 'r')
                    template = f.read()
                    self.ploader.set_from_template(template, self.substitutions)
                else:
                    self.ploader.set_sqlfile(filename)
                ret = self.ploader.load()
        return ret

    def set_dbparams(self, dbstring = ""):
        self.dbstring = dbstring
        self.ploader.set_dbparams(dbstring)
        

