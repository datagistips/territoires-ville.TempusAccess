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
        
class ImportPTSNCF(ShpImporter):
    """Public transportation GTFS data loader class."""
    # SQL files to execute before loading GTFS data
    PRELOADSQL = [ 'import_pt_sncf_pre_load.sql' ]
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    SHAPEFILES = ['ref_stops', 'appariement_ign_arrets_fer', 'urban_pt_transfers', 'noeud_ferre', 'troncon_voie_ferree']
    # SQL files to execute after loading GTFS data 
    POSTLOADSQL = ['import_pt_sncf.sql', 'import_pt_post_load.sql']



