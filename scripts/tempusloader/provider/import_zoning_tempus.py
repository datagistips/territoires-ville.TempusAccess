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

# Module to load IGN areas data (AdminExpress, ...)
class ImportZoningTempus(ShpImporter):
    """This class enables to load IGN Route500 data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['zoning']
    # SQL files to execute before loading shapefiles
    PRELOADSQL = ['import_zoning_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POSTLOADSQL = ['import_zoning_tempus.sql','import_zoning_post_load.sql']
    
    def __init__(self, path = "", prefix="", dbstring = "", logfile = None, options = {'g':'geom', 'D':True, 'I':True, 'S':True}, doclean = True, subs = {}):
        ShpImporter.__init__(self, path, prefix, dbstring, logfile, options, doclean, subs)
        
    def check_input(self):
        """Check if input is ok : given shape file exists."""
        for fpath in self.path:
            if not os.path.isfile(fpath):
                raise StandardError("The given source file '{}' does not exist".format(fpath))

    def get_shapefiles(self, path):
        self.shapefiles = [('zoning', path)]
        return
    
    
    