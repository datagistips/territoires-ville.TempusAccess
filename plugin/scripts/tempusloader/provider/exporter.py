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
import subprocess
import zipfile

#from tools import ShpLoader
from dbtools import *
from config import *


# Base class for data importer
class DataExporter(object):
    """
    This class enables exporting data from the Tempus PostgreSQL/PostGIS
    database. """
    
    SHAPEFILES=[]
    TXTFILES=[]
    PREEXPORT_SQL=[]
    POSTEXPORT_SQL=[]
    ZIPFILE=""
    
    def __init__(self, dbstring = "", path="", logfile="", subs = {}):
        self.path=path[0]
        self.dbstring = dbstring
        self.logfile = logfile
        self.ploader = PsqlLoader(dbstring=self.dbstring, logfile=self.logfile)
        self.dbparams = extract_dbparams(dbstring)
        self.substitutions = subs
    
    
    def run(self):
        ret = self.execute_sqlfiles(self.PREEXPORT_SQL)
        if not ret:
            sys.stderr.write("Error during pre_export_sql().\n")
            sys.exit(1)
        ret = self.export_txtfiles(self.TXTFILES)
        if not ret:
            sys.stderr.write("Error during csv_import().\n")
            sys.exit(1)
        ret = self.export_shapefiles(self.SHAPEFILES)
        if not ret:
            sys.stderr.write("Error during shapefiles_import_sql().\n")
            sys.exit(1)
        ret = self.execute_sqlfiles(self.POSTEXPORT_SQL)
        if not ret:
            sys.stderr.write("Error during post_export_sql().\n")
            sys.exit(1)
        files = []
        for f in self.TXTFILES:
            files.append(f+".txt")
        for f in self.SHAPEFILES:
            files.append(f+".shp")
            files.append(f+".dbf")
            files.append(f+".prj")
            files.append(f+".cpg")
            files.append(f+".shx")
        
        ret = self.zip_files(files, os.path.basename(self.path))
        if not ret:
            sys.stderr.write("Error during zip_files().\n")
            sys.exit(1)
        
    def execute_sqlfiles(self, files, substitute = True):
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
        
    def export_shapefiles(self, tables):
        ret = True
        
        for f in tables:
            filename = self.path+"/"+f+'.shp'
            
            command = [PGSQL2SHP, "-f", filename, "-h", self.dbparams['host'], "-u", self.dbparams['user'], "-p", self.dbparams['port']]
            if 'password' in self.dbparams.keys():
                command.append("-P %s" % self.dbparams['password'])
            command.append(self.dbparams['dbname'])
            command.append("tempus.road_%s" % f)
                        
            if self.logfile:
                outerr = open(self.logfile, "a")
            else:
                outerr = sys.stderr

            outerr.write("\n======= PGSQL2SHP %s\n" % f)
                        
            rescode = -1
            try:
                rescode = subprocess.call(command, stderr = outerr) 
            except OSError as (errno, strerror):
                sys.stderr.write("Error calling %s (%s) : %s \n" % (" ".join(command), errno, strerror))
            if rescode != 0: ret = False
            if self.logfile:
                outerr.close()
        
        return ret

    def export_txtfiles(self, tables):
        ret = True
        
        for f in tables:
            filename = os.path.dirname(self.path)+"/"+f+'.txt'
            
            command = [PSQL, "-t", "-d", self.dbstring, "-c", "\copy (SELECT * FROM _tempus_export."+f+") TO '"+filename+"' CSV HEADER DELIMITER ',' ENCODING 'UTF-8'" ]
            
            if self.logfile:
                outerr = open(self.logfile, "a")
            else:
                outerr = sys.stderr

            outerr.write("\n======= PSQL export CSV file %s\n" % f)
                        
            rescode = -1
            try:
                rescode = subprocess.call(command, stderr = outerr) 
            except OSError as (errno, strerror):
                sys.stderr.write("Error calling %s (%s) : %s \n" % (" ".join(command), errno, strerror))
            if rescode != 0: ret = False
            if self.logfile:
                outerr.close()
        
        return ret
        
    
    def zip_files(self, files, zipfile_name):
        ret = True
                
        zip=zipfile.ZipFile(self.path,'w',zipfile.ZIP_DEFLATED)
        
        for file in files:
            if self.logfile:
                outerr = open(self.logfile, "a")
            else:
                outerr = sys.stderr
            outerr.write("\n======= Zip exported file %s\n" % file)
            
            zip.write(os.path.dirname(self.path)+"/"+file, file)
            os.remove(os.path.dirname(self.path)+"/"+file)
        
        zip.close()
        
        return ret
        
