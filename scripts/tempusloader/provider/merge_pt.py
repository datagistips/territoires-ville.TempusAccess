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

from manager import DataManager

class MergePT(DataManager):
    """This class enables to delete PT data from Tempus PostGIS database"""
    # SQL files to execute to delete data
    SQL = ['import_pt_tempus_pre_load.sql', 'merge_pt.sql', 'import_pt_tempus.sql', 'import_pt_post_load.sql']
    
    def __init__(self, dbstring="", logfile=None, subs = {}, pt_merge_options=""):
        # Handle merge specific options
        subs['stops'] = pt_merge_options[0]
        subs['agencies'] = pt_merge_options[1]
        subs['services'] = pt_merge_options[2]
        subs['routes'] = pt_merge_options[3]
        subs['trips'] = pt_merge_options[4]
        subs['fares'] = pt_merge_options[5]
        subs['shapes'] = pt_merge_options[6]
        
        super(MergePT, self).__init__(dbstring=dbstring, logfile=logfile, subs = subs)
        
        
        