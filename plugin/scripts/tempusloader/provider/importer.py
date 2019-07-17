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

from tools import ShpLoader
from dbtools import PsqlLoader
from config import *


# Base class to import data from shape, DBF and text files
class DataImporter(object):
    """This class enables to load shapefile data into a PostGIS database."""
    # Shapefile names to load, without the extension and prefix. It will be the table name.
    DBFSHAPEFILES = []
    # Optional shapefiles
    CSVFILES = []
    # SQL files to execute before loading files
    PRELOADSQL = []
    # SQL files to execute after loading files
    POSTLOADSQL = []
    
    def __init__(\
                 self, \
                 path = "", \
                 prefix = "", \
                 dbstring = "", \
                 logfile = None, \
                 options = {'g':'geom', 'D':True, 'I':True, 'S':True}, \
                 sep = ',', \
                 encoding = 'UTF8', \
                 copymode = True, \
                 doclean = True, \
                 subs = {} \
                ):
        """Create a new data loader. Arguments are :
        path : a Zip file containing TXT or CSV data
        dbstring : the database connection string
        logfile : where to log SQL execution results (stdout by default)
        """
        self.path = path
        self.sqlfile = ""
        self.copymode = copymode
        self.doclean = doclean
        self.encoding = encoding
        self.sep = sep
        self.dbstring = dbstring
        self.logfile = logfile
        self.substitutions = subs
        self.shapefiles = []
        self.csvfiles = []
        
        if isinstance(self.path, list):
            for path in self.path:
                print "Importing path {}".format(path)
                self.prefix = self.get_prefix(path, prefix)
                self.get_shapefiles(path)
                self.get_csvfiles(path)
        else:
            self.prefix = self.get_prefix(self.path, prefix)
            self.get_shapefiles(path)
            self.get_csvfiles(path)
            pass
        self.sloader = ShpLoader(dbstring = dbstring, schema = IMPORTSCHEMA, logfile = self.logfile, options = options, doclean = doclean)
        self.ploader = PsqlLoader(dbstring=self.dbstring, logfile=self.logfile)
        
        
    def clean(self):
        """Remove previously generated SQL file."""
        if os.path.isfile(self.sqlfile):
            os.remove(self.sqlfile)
    
    def check_input(self):
        """Check if data input is ok : we have the required number of shapefiles and text files."""
        filelist = set([s for s,_ in self.csvfiles])
        for f, mandatory in DataImporter.CSVFILES:
            if mandatory and "%s.txt" % f not in filelist and "%s.csv" % f not in filelist:
                raise StandardError("Missing mandatory file: %s.txt or %s.csv" % f)
        filelist = set([s for s,_ in self.shapefiles])
        for f, mandatory in DataImporter.DBFSHAPEFILES:
            if mandatory and "%s.shp" % f not in filelist and "%s.dbf" % f not in filelist:
                raise StandardError("Missing mandatory file: %s.shp or %s.dbf" % f) 
    
    
    def load(self):
        ret = True
        try:
            self.check_input()
        except StandardError as e:
            sys.stderr.write("During import: %s\n" % e.message)
            return False

        ret = self.preload_sql()
        if ret:
            ret = self.load_data()
        else:
            sys.stderr.write("Error during preload_sql().\n")
        if ret:
            ret = self.postload_sql()
        else:
            sys.stderr.write("Error during load_data().\n")
        if ret:
            self.clean()
        else:
            sys.stderr.write("Error during postload_sql().\n")
        return ret

        
    def preload_sql(self):
        return self.load_sqlfiles(self.PRELOADSQL)

        
    def postload_sql(self):
        return self.load_sqlfiles(self.POSTLOADSQL)    
    
    
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
    
    
    def load_data(self):
        """Load all given shapefiles into the database."""
        ret = True
        created_tables = set()
        for i, s in enumerate(self.shapefiles):
            shp, rshp = s
            # if one shapefile failed, stop there
            if ret:
                self.sloader.set_shapefile(rshp)
                # the table name is the shapefile name without extension
                self.sloader.set_table(shp)
                if shp in created_tables:
                    self.sloader.options['mode'] = 'a'
                else:
                    self.sloader.options['mode'] = 'c'                    
                    created_tables.add(shp)
                ret = self.sloader.load()
        for i, s in enumerate(self.csvfiles):
            csv, rcsv = s
            # If one csvfile failed, stop here
            if ret:
                self.sqlfile = self.generate_sql(csv)
                ret = self.load_sqlfiles([self.sqlfile], substitute = False)
                if self.doclean:
                    self.clean()
        
        return ret
    
    
    def csv_cleaner( f ):
        for line in f:
            yield line.replace('\xef\xbb\xbf', '') 
    
    
    def generate_sql(self, csvfile):
        """Generate a SQL file from csv feed."""
        
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
        
        reader = csv.reader(csv_cleaner(csvfile), delimiter = self.sep, quotechar = '"')
        
        # Write SQL for each beginning of table
        tmpfile.write("-- Inserting values for table %s\n\n" % f)
        # first row is field names
        fieldnames = reader.next()
        if self.copymode:
            tmpfile.write('COPY "%s"."%s" (%s) FROM stdin;\n' % (IMPORTSCHEMA, f, ",".join(fieldnames)))
        # read the rows values
        # deduce value type by testing
        for row in reader:
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
                        (IMPORTSCHEMA, f, ",".join(fieldnames), ','.join(insert_row)))
        # Write SQL at end of processed table
        if self.copymode:
            tmpfile.write("\.\n")
        tmpfile.write("\n-- Processed table %s.\n\n" % f)

        tmpfile.write("COMMIT;\n")
        tmpfile.write("-- Processed all data \n\n")
        tmpfile.close()
        return sqlfile
    

    def set_dbparams(self, dbstring=""):
        self.dbstring = dbstring
        self.ploader.set_dbparams(dbstring)
        self.sloader.set_dbparams(dbstring)


    def get_prefix(self, path, prefix = ""):
        """Get prefix for shapefiles. If given prefix is empty, try to find it browsing the directory."""
        myprefix = ""
        if prefix:
            myprefix = prefix
        else:
            # prefix has not been given, try to deduce it from files
            if path:
                prefixes = []
                if not os.path.isdir(path):
                    print "{} is not a directory".format(path)
                    return ''
                for filename in os.listdir(path):
                    for shp in self.DBFSHAPEFILES:
                        # if we find the table name at the end of the file name (w/o ext), add prefix to the list
                        # only check dbf and shp
                        basename, ext = os.path.splitext(os.path.basename(filename))
                        if ext.lower() in ['.dbf', '.shp'] and basename[-len(shp):] == shp:
                            curprefix = basename[:-len(shp)]
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
        return myprefix
    
    
    def get_shapefiles(self, path):
        notfound = []

        baseDir = os.path.realpath(path)
        ls = os.listdir(baseDir)
        for shp, mandatory in self.DBFSHAPEFILES:
            if (mandatory == False):
                filenameShp = self.prefix + shp + ".shp"
                filenameDbf = self.prefix + shp + ".dbf"
                lsLower = [x.lower() for x in ls]
                if filenameShp in lsLower:
                    i = lsLower.index(filenameShp)
                    self.shapefiles.append((shp, os.path.join(baseDir, ls[i])))
                elif filenameDbf in lsLower:
                    i = lsLower.index(filenameDbf)
                    self.shapefiles.append((shp, os.path.join(baseDir, ls[i])))
            else:
                filenameShp = self.prefix + shp + ".shp"
                filenameDbf = self.prefix + shp + ".dbf"
                filenameShp = filenameShp.lower()
                filenameDbf = filenameDbf.lower()
                lsLower = [x.lower() for x in ls]
                if filenameShp in lsLower:
                    i = lsLower.index(filenameShp)
                    self.shapefiles.append((shp, os.path.join(baseDir, ls[i])))
                elif filenameDbf in lsLower:
                    i = lsLower.index(filenameDbf)
                    self.shapefiles.append((shp, os.path.join(baseDir, ls[i])))
                else:
                    notfound.append(filenameDbf)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                         "%s and %s not found\n" % (shp, filenameShp, filenameDbf))
                                     
        return notfound
        
    def get_csvfiles(self, path):
        notfound = []
        
        baseDir = os.path.realpath(path)
        ls = os.listdir(baseDir)
        for csv, mandatory in self.CSVFILES:
            if (mandatory == False):
                filenameCsv = self.prefix + csv + '.csv'
                filenameTxt = self.prefix + csv + '.txt'
                lsLower = [x.lower() for x in ls]
                if filenameTxt in lsLower:
                    i = lsLower.index(filenameTxt)
                    self.csvfiles.append((csv, os.path.join(baseDir, ls[i])))
                elif filenameCsv in lsLower:
                    i = lsLower.index(filenameCsv)
                    self.csvfiles.append((csv, os.path.join(baseDir, ls[i])))
                else:
                    notfound.append(filenameCsv)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                        "%s and %s not found" % (shp, filenameCsv, filenameTxt))
        
        return notfound
        
    
# Base class for data importer
class ZipImporter(DataImporter):
    
    def __init__(self, \
                 path = "", \
                 prefix = "", \
                 dbstring = "", \
                 logfile = None, \
                 options = {'g':'geom', 'D':True, 'I':True, 'S':True}, \
                 sep = ',', \
                 encoding = 'UTF8', \
                 copymode = True, \
                 doclean = True, \
                 subs = {} \
                ):
        self.path = path
        self.sqlfile = ""
        self.copymode = copymode
        self.doclean = doclean
        self.encoding = encoding
        self.sep = sep
        self.dbstring = dbstring
        self.logfile = logfile
        self.substitutions = subs
        
        self.sloader = ShpLoader(dbstring = dbstring, schema = IMPORTSCHEMA, logfile = self.logfile, options = options, doclean = doclean)
        self.ploader = PsqlLoader(dbstring=self.dbstring, logfile=self.logfile)
        
    
    def check_input(self):
        """Check if data input is ok : we have the required number of shapefiles and text files."""
        if zipfile.is_zipfile(self.path):
            with zipfile.ZipFile(self.path) as zipf:
                filelist = [ os.path.basename(x) for x in zipf.namelist() ]
                for f, mandatory in DataImporter.CSVFILES:
                    if mandatory and "%s.txt" % f not in filelist and "%s.csv" % f not in filelist:
                        raise StandardError("Missing mandatory file: %s.txt or %s.csv" % f)
                for f, mandatory in DataImporter.DBFSHAPEFILES:
                    if mandatory and "%s.shp" % f not in filelist and "%s.dbf" % f not in filelist:
                        raise StandardError("Missing mandatory file: %s.shp or %s.dbf" % f) 
        else:
            raise StandardError("Not a zip file!")
    
    
    def generate_sql(self):
        """Generate a SQL file from zip feed."""
        if self.logfile:
            out = open(self.logfile, "a")
        else:
            out = sys.stdout
        
        sqlfile = ""
        if zipfile.is_zipfile(self.path):
            # create temp file for SQL output
            fd, sqlfile = tempfile.mkstemp()
            tmpfile = os.fdopen(fd, "w")
            # begin a transaction in SQL file
            tmpfile.write("SET CLIENT_ENCODING TO %s;\n" % self.encoding)
            tmpfile.write("SET STANDARD_CONFORMING_STRINGS TO ON;\n")
            tmpfile.write("BEGIN;\n")
            
            # open zip file
            with zipfile.ZipFile(self.path) as zipf:
                # map of text file => (mandatory, zip_path)
                gFiles = {}
                for f, mandatory in self.CSVFILES:
                    gFiles[f] = (mandatory, '')

                for zfile in zipf.namelist():
                    bn = os.path.basename( zfile )
                    for f, m in self.CSVFILES:
                        if (f + '.txt' == bn or f + '.csv' == bn):
                            mandatory, p = gFiles[f]
                            gFiles[f] = ( mandatory, zfile )

                for f, v in gFiles.iteritems():
                    mandatory, f = v
                    if mandatory and f == '':
                        raise ValueError, "Missing file in archive : %s" % f

                for f, v in gFiles.iteritems():
                    mandatory, zpath = v
                    if zpath == '':
                        # File is absent from the archive
                        continue

                    out.write( "== Loading %s\n" % zpath )

                    # get rid of Unicode BOM (U+FEFF)
                    def csv_cleaner( f ):
                        for line in f:
                            yield line.replace('\xef\xbb\xbf', '')

                    reader = csv.reader(csv_cleaner(zipf.open( zpath )),
                                        delimiter = self.sep,
                                        quotechar = '"')

                    # Write SQL for each beginning of table
                    tmpfile.write("-- Inserting values for table %s\n\n" % f)
                    # first row is field names
                    fieldnames = reader.next()
                    if self.copymode:
                        tmpfile.write('COPY "%s"."%s" (%s) FROM stdin;\n' % (IMPORTSCHEMA, f, ",".join(fieldnames)))
                    # read the rows values
                    # deduce value type by testing
                    for row in reader:
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
                                    (IMPORTSCHEMA, f, ",".join(fieldnames), ','.join(insert_row)))
                    # Write SQL at end of processed table
                    if self.copymode:
                        tmpfile.write("\.\n")
                    tmpfile.write("\n-- Processed table %s.\n\n" % f)

            tmpfile.write("COMMIT;\n")
            tmpfile.write("-- Processed all data \n\n")
            tmpfile.close()
        return sqlfile
        
        
    def load_data(self):
        """Generate SQL file and load text data to database."""
        ret = True
        self.sqlfile = self.generate_sql()
        ret = self.load_sqlfiles([self.sqlfile], substitute = False)        
        if self.doclean:
            self.clean()
        
        if ret and zipfile.is_zipfile(self.path):
            with zipfile.ZipFile(self.path) as zipf:
                gFiles = {}
                for f, mandatory in self.DBFSHAPEFILES:
                    gFiles[f] = (mandatory, '')
                for zfile in zipf.namelist():
                    bn = os.path.basename( zfile )
                    for f, m in self.DBFSHAPEFILES:
                        if (f + '.dbf' == bn or f + '.shp' == bn or f + '.DBF' == bn or f + '.SHP' == bn):
                            mandatory, p = gFiles[f]
                            gFiles[f] = ( mandatory, zfile )
                
                for f, v in gFiles.iteritems():
                    mandatory, f = v
                    if mandatory and f == '':
                        raise ValueError, "Missing file in archive : %s" % f
                
                created_tables = set()
                for f, v in gFiles.iteritems():
                    mandatory, zpath = v
                    if ret:
                        if zpath == '':
                            # File is absent from the archive
                            continue
                        out.write( "== Loading %s\n" % zpath )
                        
                        self.sloader.set_shapefile(zipf.open( zpath ))
                        # the table name is the shapefile name without extension
                        shp = os.path.basename(os.path.splitext("zpath")[0])
                        self.sloader.set_table(shp)
                        if shp in created_tables:
                            self.sloader.options['mode'] = 'a'
                        else:
                            self.sloader.options['mode'] = 'c'                    
                            created_tables.add(shp)
                        ret = self.sloader.load()
        return ret
    
    
    