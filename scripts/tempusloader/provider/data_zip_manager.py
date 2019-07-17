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
from data_dir_manager import *
    
# Base class for zipped data
class DataZipManager(DataDirManager):
    def check_input(self):
        """ Update self.found_import_dbfshpfiles and self.found_import_csvtxtfiles"""
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            if isinstance(self.path, list):
                for path in self.path:
                    if zipfile.is_zipfile(path):
                        print "Path {}".format(path)
                        self.prefix = self.get_prefix(path, self.prefix)                    
                        self.get_dbfshpfiles(path)
                        self.get_csvtxtfiles(path)
                    else:
                        raise StandardError("Not a zip file!")           
            else:
                print "Path {}".format(self.path)
                if zipfile.is_zipfile(self.path):
                    self.prefix = self.get_prefix(self.path, self.prefix)
                    self.get_dbfshpfiles(self.path)
                    self.get_csvtxtfiles(self.path)
                    pass
                else:
                    raise StandardError("Not a zip file!")
            """Check if we have the required files."""
            filelist = set([s for s,_ in self.found_import_csvtxtfiles])
            for f, mandatory in self.IMPORT_CSVTXTFILES:
                if mandatory and "%s.txt" % f not in filelist and "%s.csv" % f not in filelist:
                    raise StandardError("Missing mandatory file: %s.txt or %s.csv" % (f, f))
            filelist = set([s for s,_ in self.found_import_dbfshpfiles])
            for f, mandatory in self.IMPORT_DBFSHPFILES:
                if mandatory and "%s.shp" % f not in filelist and "%s.dbf" % f not in filelist:
                    raise StandardError("Missing mandatory file: %s.shp or %s.dbf" % (f, f)) 
    
    def get_prefix(self, path, prefix = ""):
        """Get prefix for shapefiles. If given prefix is empty, try to find it browsing the directory."""
        myprefix = ""
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            if prefix:
                myprefix = prefix
            else:
                # prefix has not been given, try to deduce it from files
                prefixes = []
                if zipfile.is_zipfile(os.path.realpath(path)):
                    with zipfile.ZipFile(os.path.realpath(path)) as zipf:
                        for file in zipf.namelist():
                            filename = os.path.basename(file)
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
                    raise StandardError("%s is not a zip" % path)
        return myprefix
    
    def get_dbfshpfiles(self, path):
        notfound = [] 
        with zipfile.ZipFile(os.path.realpath(path)) as zipf:
            ls = zipf.namelist()
            lsLower = [ x.lower() for x in ls ]
            for tablename, mandatory in self.IMPORT_DBFSHPFILES:
                filenameShp = (self.prefix + tablename + ".shp").lower()
                filenameDbf = (self.prefix + tablename + ".dbf").lower()
                if filenameShp in lsLower:
                    i = lsLower.index(filenameShp)
                    self.found_import_dbfshpfiles.append((filenameShp, os.path.realpath(path)))
                elif filenameDbf in lsLower:
                    i = lsLower.index(filenameDbf)
                    self.found_import_dbfshpfiles.append((filenameDbf, os.path.realpath(path)))
                elif mandatory == True:
                    notfound.append(tablename)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                         "%s and %s not found\n" % (tablename, filenameShp, filenameDbf))
        return notfound
    
    def get_csvtxtfiles(self, path):
        notfound = []
        with zipfile.ZipFile(os.path.realpath(path)) as zipf:
            ls = zipf.namelist()
            lsLower = [ x.lower() for x in ls ]
            for tablename, mandatory in self.IMPORT_CSVTXTFILES:
                filenameCsv = (self.prefix + tablename + ".csv").lower()
                filenameTxt = (self.prefix + tablename + ".txt").lower()
                if filenameCsv in lsLower:
                    i = lsLower.index(filenameCsv)
                    self.found_import_csvtxtfiles.append((filenameCsv, os.path.realpath(path)))
                elif filenameTxt in lsLower:
                    i = lsLower.index(filenameTxt)
                    self.found_import_csvtxtfiles.append((filenameTxt, os.path.realpath(path)))
                elif mandatory == True:
                    notfound.append(tablename)
                    sys.stderr.write("Warning: file for table %s not found.\n"\
                                         "%s and %s not found\n" % (tablename, filenameCsv, filenameTxt))
        return notfound
    
    def import_dbfshpfiles(self):
        """Load all given shapefiles into the database."""
        ret = True
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            created_tables = set()
            if zipfile.is_zipfile(os.path.realpath(self.path)):
                with zipfile.ZipFile(os.path.realpath(self.path)) as zipf:
                    gFiles = {}
                    for tablename, mandatory in self.IMPORT_DBFSHPFILES:
                        gFiles[tablename] = (mandatory, '')
                    for zfile in zipf.namelist():
                        bn = (os.path.basename( zfile )).lower()
                        for tablename, mandatory in self.IMPORT_DBFSHPFILES:
                            if (tablename.lower() + '.dbf' == bn or tablename.lower() + '.shp' == bn):
                                mandatory, p = gFiles[tablename]
                                gFiles[tablename] = ( mandatory, zfile )
                    
                    for tablename, v in gFiles.iteritems():
                        mandatory, filepath = v
                        if mandatory and filepath == '':
                            raise ValueError, "Missing file in archive : %s" % filepath
                    
                    created_tables = set()
                    for tablename, v in gFiles.iteritems():
                        mandatory, filepath = v
                        if ret:
                            if filepath == '':
                                # File is absent from the archive
                                continue
                            out.write( "== Loading %s\n" % filepath )
                            
                            self.sloader.set_shapefile(zipf.open( filepath ))
                            # the table name is the shapefile name without extension
                            tablename = os.path.basename(os.path.splitext(filepath)[0])
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
        if (self.IMPORT_CSVTXTFILES != [] or self.IMPORT_DBFSHPFILES != []):
            if zipfile.is_zipfile(os.path.realpath(self.path)):
                self.sqlfile = self.generate_sql_from_zipped_csv()
                ret = self.execute_sqlfiles([self.sqlfile], substitute = False)
                if self.doclean:
                    self.clean() 
        return ret
        
    def zip_exported_files(self):
        """ All exported files are zipped"""
        ret=True
        files = []
        print self.text_format
        for f in self.EXPORT_CSVTXTFILES:
            files.append(f+self.text_format)
        for f in self.EXPORT_DBFSHPFILES:
            files.append(f+".shp")
            files.append(f+".dbf")
            files.append(f+".prj")
            files.append(f+".cpg")
            files.append(f+".shx")
        if files!=[] and os.path.isdir(self.path) == False:
            ret = self.zip_files(files)
        return ret
    
    def zip_files(self, files):
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
    
    def run(self):
        r = super(DataZipManager, self).run()
        self.zip_exported_files()
        return r
    
    def csv_cleaner( self, f ):
        for line in f:
            yield line.replace('\xef\xbb\xbf', '') 
    
    def generate_sql_from_zipped_csv(self):
        """Generate a SQL file from a txt or csv feed located in a zip."""        
        if self.logfile:
            out = open(self.logfile, "a")
        else:
            out = sys.stdout
        sqlfile = ""
        # create temp file for SQL output
        if zipfile.is_zipfile(self.path):
            fd, sqlfile = tempfile.mkstemp()
            tmpfile = os.fdopen(fd, "w")
            # begin a transaction in SQL file
            tmpfile.write("SET CLIENT_ENCODING TO %s;\n" % self.encoding)
            tmpfile.write("SET STANDARD_CONFORMING_STRINGS TO ON;\n")
            tmpfile.write("BEGIN;\n")
        
            # open zip file
            with zipfile.ZipFile(self.path) as zipf:
                gFiles = {}
                for tablename, mandatory in self.IMPORT_CSVTXTFILES:
                    gFiles[tablename] = (mandatory, '')
                
                for filename in zipf.namelist():
                    bn = os.path.basename( filename )
                    for tablename, mandatory in self.IMPORT_CSVTXTFILES:
                        if (tablename + '.txt' == bn or tablename + '.csv' == bn):
                            m, p = gFiles[tablename]
                            gFiles[tablename] = ( m, filename )                
                for tablename, v in gFiles.iteritems():
                    mandatory, filename = v
                    if mandatory and filename == '':
                        raise ValueError, "Missing file in archive : %s" % filename
                
                for tablename, v in gFiles.iteritems():
                    mandatory, filename = v
                    if filename == '':
                        # File is absent from the archive
                        continue
                    out.write( "== Loading %s\n" % filename )
                    reader = csv.reader(self.csv_cleaner(zipf.open( filename )),delimiter = self.sep,quotechar = '"')
                    # Write SQL for each beginning of table
                    tmpfile.write("-- Inserting values for table %s\n\n" % tablename)
                    # first row is field names
                    fieldnames = reader.next()
                    if self.copymode:
                        tmpfile.write('COPY "%s"."%s" (%s) FROM stdin;\n' % (TEMPSCHEMA, tablename, ",".join(fieldnames)))
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
                                    (TEMPSCHEMA, tablename, ",".join(fieldnames), ','.join(insert_row)))
                    # Write SQL at end of processed table
                    if self.copymode:
                        tmpfile.write("\.\n")
                    tmpfile.write("\n-- Processed table %s.\n\n" % tablename)

            tmpfile.write("COMMIT;\n")
            tmpfile.write("-- Processed all data \n\n")
            tmpfile.close()
        return sqlfile
        
        