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

from data_dir_manager import DataDirManager
        
class ImportPTSNCF(DataDirManager):
    """Public transportation GTFS data loader class."""
    # SQL files to execute before loading GTFS data
    PRE_SQL = [ "import_pt_preload.sql" ]
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    IMPORT_DBFSHPFILES = [\
                            ('ref_stops', True), \
                            ('appariement_ign_arrets_fer', True), \
                            ('urban_pt_transfers', True), \
                            ('noeud_ferre', True), \
                            ('troncon_voie_ferree', True)\
                         ]
    # SQL files to execute after loading GTFS data 
    POST_SQL = ['merge_pt_sncf.sql', 'import_pt_tempus.sql', 'import_pt_postload.sql']



