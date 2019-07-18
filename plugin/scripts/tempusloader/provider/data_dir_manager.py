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
import zipfile
import tempfile
import csv
import subprocess

from tools import ShpLoader
from dbtools import PsqlLoader
from config import *

# Base class to import data from shape, DBF and text files
class DataDirManager(object):
    """This class enables to load data stored in an unzipped directory."""
    # SQL files to execute before importing/exporting files
    PRE_SQL = []
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    IMPORT_DBFSHPFILES = []
    # CSV files to load
    IMPORT_CSVTXTFILES = []
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    EXPORT_DBFSHPFILES = []
    # CSV files to load
    EXPORT_CSVTXTFILES = []
    # SQL files to execute after importing/exporting files
    POST_SQL = []
    
    def __init__(\
                    self, \
                    path = "", \
                    prefix = "", \
                    dbstring = "", \
                    logfile = None, \
                    options = {'g':'geom', 'D':True, 'I':True, 'S':True}, \
                    sep = ',', \
                    text_format = '.txt', \
                    encoding = 'UTF8', \
                    copymode = True, \
                    doclean = True, \
                    subs = {} \
                ):
        self.path = path
        self.prefix = prefix
        self.sqlfile = ""
        self.copymode = copymode
        self.doclean = doclean
        self.encoding = encoding
        self.sep = sep
        self.text_format = text_format
        self.dbstring = dbstring
        self.logfile = logfile
        self.substitutions = subs
        self.found_import_dbfshpfiles = []
        self.found_import_csvtxtfiles = []
        self.sloader = ShpLoader(dbstring = self.dbstring, schema = TEMPSCHEMA, logfile = self.logfile, options = options, doclean = doclean)
        self.ploader = PsqlLoader(dbstring = self.dbstring, logfile=self.logfile)
    
    def clean(self):
        """Remove previously generated SQL file."""
        if os.path.isfile(self.sqlfile):
            os.remove(self.sqlfile)
    
    def check_input(self):
        """ Update self.found_import_dbfshpfiles and self.found_import_csvtxtfiles"""
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            if isinstance(self.path, list):
                for path in self.path:
                    print "Path {}".format(path)
                    self.prefix = self.get_prefix(path, self.prefix)
                    self.get_dbfshpfiles(path)
                    self.get_csvtxtfiles(path)
            else:
                print "Path {}".format(self.path)
                self.prefix = self.get_prefix(self.path, self.prefix)
                self.get_dbfshpfiles(self.path)
                self.get_csvtxtfiles(self.path)
                pass
            """Check if we have the required files."""
            filelist = set([s for s,_ in self.found_import_csvtxtfiles])
            for f, mandatory in self.IMPORT_CSVTXTFILES:
                if mandatory and "%s.txt" % f not in filelist and "%s.csv" % f not in filelist:
                    raise StandardError("Missing mandatory file: %s.txt or %s.csv" % f)
            filelist = set([s for s,_ in self.found_import_dbfshpfiles])
            for f, mandatory in self.IMPORT_DBFSHPFILES:
                if mandatory and "%s.shp" % f not in filelist and "%s.dbf" % f not in filelist:
                    raise StandardError("Missing mandatory file: %s.shp or %s.dbf" % f) 
    
    def get_prefix(self, path, prefix = ""):
        """Get prefix for shapefiles. If given prefix is empty, try to find it browsing the directory."""
        myprefix = ""
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            if prefix:
                myprefix = prefix
            else:
                # prefix has not been given, try to deduce it from files
                prefixes = []
                if os.path.isdir(path):
                    for filename in os.listdir(os.path.realpath(path)):
                        for tablename, mandatory in self.IMPORT_DBFSHPFILES:
                            # if we find the table name at the end of the file name (w/o ext), add prefix to the list
                            # only check dbf and shp
                            basename, ext = os.path.splitext(os.path.basename(filename))
                            if ext.lower() in ['.dbf', '.shp'] and basename[-len(tablename):] == tablename:
                                curprefix = basename[:-len(tablename)]
                                # only consider prefixes with "_"
                                if '_' in curprefix and curprefix not in prefixes:
                                    prefixes.append(curprefix)
                        for tablename, mandatory in self.IMPORT_CSVTXTFILES:
                            # if we find the table name at the end of the file name (w/o ext), add prefix to the list
                            # only check csv and txt
                            basename, ext = os.path.splitext(os.path.basename(filename))
                            if ext.lower() in ['.csv', '.txt'] and basename[-len(tablename):] == tablename:
                                curprefix = basename[:-len(tablename)]
                                # only consider prefixes with "_"
                                if '_' in curprefix and curprefix not in prefixes:
                                    prefixes.append(curprefix)                
                    # if only one prefix found, use it !
                    if len(prefixes) > 1:
                        sys.stderr.write("Cannot determine prefix, multiple found : %s \n" % ",".join(prefixes))
                    elif len(prefixes) == 1:
                        return prefixes[0]
                    else:
                        return ''
                else:
                    raise StandardError("%s is not a directory" % path)
        return myprefix
    
    def get_dbfshpfiles(self, path):
        notfound = []
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            ls = os.listdir(os.path.realpath(path))
            for tablename, mandatory in self.IMPORT_DBFSHPFILES:
                filenameShp = (self.prefix + tablename + ".shp").lower()
                filenameDbf = (self.prefix + tablename + ".dbf").lower()
                lsLower = [x.lower() for x in ls]
                if filenameShp in lsLower:
                    i = lsLower.index(filenameShp)
                    self.found_import_dbfshpfiles.append((tablename, os.path.join(os.path.realpath(path), ls[i])))
                elif filenameDbf in lsLower:
                    i = lsLower.index(filenameDbf)
                    self.found_import_dbfshpfiles.append((tablename, os.path.join(os.path.realpath(path), ls[i])))
                elif mandatory == True:
                    notfound.append(tablename)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                         "%s and %s not found\n" % (tablename, filenameShp, filenameDbf))
        return notfound
    
    def get_csvtxtfiles(self, path):
        notfound = []
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            ls = os.listdir(os.path.realpath(path))
            for tablename, mandatory in self.IMPORT_CSVTXTFILES:
                filenameCsv = (self.prefix + tablename + ".csv").lower()
                filenameTxt = (self.prefix + tablename + ".txt").lower()
                lsLower = [x.lower() for x in ls]
                if filenameCsv in lsLower:
                    i = lsLower.index(filenameCsv)
                    self.found_import_csvtxtfiles.append((tablename, os.path.join(os.path.realpath(path), ls[i])))
                elif filenameTxt in lsLower:
                    i = lsLower.index(filenameTxt)
                    self.found_import_csvtxtfiles.append((tablename, os.path.join(os.path.realpath(path), ls[i])))
                elif mandatory == True:
                    notfound.append(tablename)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                         "%s and %s not found\n" % (tablename, filenameCsv, filenameTxt))
        return notfound
    
    def run(self):
        ret = True
        try:
            self.check_input()
        except StandardError as e:
            sys.stderr.write("During import: %s\n" % e.message)
            return False
        
        ret = self.execute_sqlfiles(self.PRE_SQL)
        if ret:
            print "pre_sql() done.\n"
            ret = self.import_dbfshpfiles()
        else:
            sys.stderr.write("Error during pre_sql().\n")
        if ret:
            print "import_dbfshpfiles() done.\n"
            ret = self.import_csvtxtfiles()
        else:
            sys.stderr.write("Error during import_dbfshpfiles().\n")
        if ret:
            print "import_csvtxtfiles() done.\n"
            ret = self.export_dbfshpfiles()
        else:
            sys.stderr.write("Error during import_csvtxtfiles().\n")
        if ret:
            print "export_dbfshpfiles() done.\n"
            ret = self.export_csvtxtfiles()
        else:
            sys.stderr.write("Error during export_dbfshpfiles().\n")
        if ret:
            print "export_csvtxtfiles() done.\n"
            ret = self.execute_sqlfiles(self.POST_SQL)
        else:
            sys.stderr.write("Error during export_csvtxtfiles().\n")
        if ret:
            print "post_sql() done.\n"
            self.clean()
        else:
            sys.stderr.write("Error during post_sql().\n")
        return ret
    
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
    
    def import_dbfshpfiles(self):
        """Load all given shapefiles into the database."""
        ret = True
        created_tables = set()
        for line_number, file in enumerate(self.found_import_dbfshpfiles):
            tablename, filepath = file
            # if one shapefile failed, stop there
            if ret:
                self.sloader.set_shapefile(filepath)
                # the table name is the shapefile name without extension
                self.sloader.set_table(tablename)
                if tablename in created_tables:
                    self.sloader.options['mode'] = 'a'
                else:
                    self.sloader.options['mode'] = 'c'                    
                    created_tables.add(tablename)
                ret = self.sloader.load()
        return ret
        
         
    def import_csvtxtfiles(self):
        ret=True
        for line_number, file in enumerate(self.found_import_csvtxtfiles):
            tablename, filepath = file
            # If one csvfile failed, stop here
            if ret:
                self.sqlfile = self.generate_sql_from_csv(tablename, filepath)
                ret = self.execute_sqlfiles([self.sqlfile], substitute = False)
                if self.doclean:
                    self.clean() 
        return ret
    
    
    def export_dbfshpfiles(self):
        ret = True
        for f in self.EXPORT_DBFSHPFILES:
            filename = self.path+"/"+f+'.shp'             
            command = [ PGSQL2SHP, "-f", filename, "-h", self.dbparams['host'], "-u", self.dbparams['user'], "-p", self.dbparams['port'] ]
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
    
    
    def export_csvtxtfiles(self):
        ret = True        
        for f in self.EXPORT_CSVTXTFILES:
            filename = os.path.dirname(self.path)+"/"+f+'.txt'
            command = [PSQL, "-t", "-d", self.dbstring, "-c", "\copy (SELECT * FROM "+TEMPSCHEMA+"."+f+") TO '"+filename+"' CSV HEADER DELIMITER '"+ self.sep +"' ENCODING 'UTF-8'" ]
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
    
    
    def csv_cleaner( self, f ):
        for line in f:
            yield line.replace('\xef\xbb\xbf', '') 
    
    
    def generate_sql_from_csv(self, tablename, filepath):
        if self.logfile:
            out = open(self.logfile, "a")
        else:
            out = sys.stdout
        
        sqlfile = ""
        # create temp file for SQL output
        fd, sqlfile = tempfile.mkstemp()
        tmpfile = os.fdopen(fd, "w")
        # begin a transaction in SQL file
        tmpfile.write("SET CLIENT_ENCODING TO %s;\n" % self.encoding)
        tmpfile.write("SET STANDARD_CONFORMING_STRINGS TO ON;\n")
        tmpfile.write("BEGIN;\n")
        f = open(os.path.realpath(filepath), "r")
        reader = csv.reader(self.csv_cleaner(f), delimiter = self.sep, quotechar = '"')
        # Write SQL for each beginning of table
        tmpfile.write("-- Inserting values for table %s\n\n" % tablename)
        # first row is field names
        fieldnames = reader.next()
        print fieldnames
        if self.copymode:
            tmpfile.write('COPY "%s"."%s" (%s) FROM stdin;\n' % (TEMPSCHEMA, tablename, ",".join(fieldnames)))
        # read the rows values
        # deduce value type by testing
        for row in reader:
            print row
            insert_row = []
            for value in row:
                if value == '':
                    if self.copymode:
                        insert_row.append('\N')
                    else:
                        insert_row.append('NULL')
                elif not self.copymode and not is_numeric(value):
                    insert_row.append("'%s'" % value.replace("'", "''"))
                else:
                    insert_row.append(value)
            # write SQL statement
            if self.copymode:
                tmpfile.write("%s\n" % '\t'.join(insert_row))
            else:
                tmpfile.write("INSERT INTO %s.%s (%s) VALUES (%s);\n" %\
                        (TEMPSCHEMA, f, ",".join(fieldnames), ','.join(insert_row)))
        # Write SQL at end of processed table
        if self.copymode:
            tmpfile.write("\.\n")
        tmpfile.write("\n-- Processed table %s.\n\n" % tablename)

        tmpfile.write("COMMIT;\n")
        tmpfile.write("-- Processed all data \n\n")
        tmpfile.close()
        return sqlfile
    
