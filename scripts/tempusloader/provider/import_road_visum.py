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

from data_dir_manager import DataDirManager
import os

# Module to load Visum data
class ImportRoadVisum(DataDirManager):
    """This class enables to load Visum-generated shapefiles data into a PostGIS
database.
    """
    # Shapefile names to load, without the extension and prefix
    IMPORT_DBFSHPFILES = [('node', True), ('link', True), ('mov', False)]
    # SQL files to execute before loading shapefiles
    PRE_SQL = ['import_road_pre_load.sql']
    # SQL files to execute after loading shapefiles 
    POST_SQL = ['import_road_visum.sql', 'import_road_post_load.sql']
    SPEEDPROFILES = [] # Examples: 'hsnp','hspr' (cf tomtom.py)
    EXPECTED_NODE_ATTRIBUTES = ["NO", "CONTROLTYPE"]
    EXPECTED_EDGE_ATTRIBUTES = ["NO", "FROMNODENO", "TONODENO", "TSYSSET",
                                "LENGTH", "NOMROUTE", "NUMLANES", "V0PRT",
                                "VCUR_PRTSYS(V)", "TOLL_PRTSYS(V)", "R_NO",
                                "R_FROMNODENO", "R_TONODENO", "R_TSYSSET",
                                "R_LENGTH", "R_NOMROUTE", "R_NUMLANES",
                                "R_V0PRT", "R_VCUR_PRTSYS(V)",
                                "R_TOLL_PRTSYS(V)"]
    EXPECTED_MOV_ATTRIBUTES = ["NUMNOEUDO", "NUMNOEUDO", "NUMVIANOEUD", "NUMNOEUDD", "T0TI"]

    def __init__(self, path = "", prefix = "", dbstring = "", logfile = None, options = {'g':'geom', 'D':True, 'I':True, 'S':True}, doclean = True, subs = {}, visum_modes=""):
        # Handle visum-specific transportation modes
        subs['pedestrian'] = visum_modes[0]
        subs['bike'] = visum_modes[1]
        subs['car'] = visum_modes[2]
        subs['taxi'] = visum_modes[3]
        # Add as many argument to Shp importer as they are columns to import
        for s in path:
            for shp, mandatory in self.DBFSHAPEFILES:
                shp_column_names = self.get_long_name(s, prefix, shp)
                self.check_columns(shp_column_names, shp)
                for colname in shp_column_names:
                    shp_longname, shp_shortname = colname.split(";")
                    subs[shp + "_" + shp_longname] = shp_shortname.lower()
        super(ImportRoadVisum, self).__init__(path=path, prefix=prefix, dbstring=dbstring, logfile=logfile, options=options, doclean=doclean, subs=subs)

    def get_long_name(self, path, prefix, shp_name):
        """Get the Visum attribute long names, as by default only short names are
        stored in the shapefiles and sent; return a list of column names under
        the format "<long_name>;<short_name>"

        """
        column_file_name = os.path.join(path, prefix + shp_name + '.CTF')
        with open(column_file_name, 'rb') as input_file:
            column_names = input_file.read().split("\r\n")
        return column_names[1:-1]

    def check_columns(self, column_names, shp):
        """
        """
        if shp == "node":
            attribute_list = self.EXPECTED_NODE_ATTRIBUTES
        elif shp == "link":
            attribute_list = self.EXPECTED_EDGE_ATTRIBUTES
        elif shp == "mov":
            attribute_list = self.EXPECTED_MOV_ATTRIBUTES
        else:
            raise Exception(("Unknown shapefile name "
                             "('node', 'link' or 'mov' expected)"))
        long_names = [n.split(";")[0] for n in column_names]
        for col in attribute_list:
            cur_long_name = col.split(";")[0]
            if cur_long_name not in long_names:
                raise Exception(("Column {} is not in the column list "
                                 "for {} table.").format(cur_long_name, shp))
