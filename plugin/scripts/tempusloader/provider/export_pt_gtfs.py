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
# Tempus data exporter

import os
import sys

from data_zip_manager import DataZipManager

class ExportPTGTFS(DataZipManager):
    EXPORT_CSVTXTFILES=[ 'agency', 'calendar', 'calendar_dates', 'routes', 'trips', 'stops', 'stop_times', 'transfers', 'shapes' ]
    PRE_SQL=[ 'export_pt_gtfs.sql' ]
    