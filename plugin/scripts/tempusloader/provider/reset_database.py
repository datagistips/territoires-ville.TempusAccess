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


from importer import DataImporter
from importer import ZipImporter

# Module to reset the tempus schema
class ResetTempus(DataImporter):
    """This class allows to reset the tempus and tempus_gtfs schemas of a database"""
    PRELOADSQL = [ 'reset_tempus_schemas.sql', 'create_function_import_pt_gtfs.sql', 'create_function_merge_pt.sql' ]
    CSVFILES = [ ]
    POSTLOADSQL = [ ]
    
class ResetTempusAccess(ZipImporter):
    """This class allows to reset the indic and tempus_access schemas of a database"""
    PRELOADSQL = [ 'reset_tempus_schema.sql', 'reset_tempus_gtfs_schema.sql', 'reset_tempusaccess_schemas.sql', \
                   'reset_tempusaccess_function_pt_stop.sql', 'reset_tempusaccess_function_pt_stop_area.sql', \
                   'reset_tempusaccess_function_pt_section.sql', \
                   'reset_tempusaccess_function_pt_trip.sql', 'reset_tempusaccess_function_pt_stops_route.sql', \
                   'reset_tempusaccess_function_pt_route.sql', 'reset_tempusaccess_function_pt_agency.sql', \
                   'reset_tempusaccess_function_path.sql', 'reset_tempusaccess_function_path_details.sql', \
                   'reset_tempusaccess_function_paths_tree.sql', 'reset_tempusaccess_function_comb_paths_trees.sql', \
                   'reset_tempusaccess_function_isosurfaces.sql', 'reset_pre_load.sql'
                 ]
    CSVFILES = [ ('modalities', True), ('agregates', True), ('formats', True), ('holidays', True), ('indicators', True), ('obj_type', True) ]
    POSTLOADSQL = [ 'reset_post_load.sql' ]
    
    
