# -*- coding: utf-8 -*-
"""
/***************************************************************************
 PluginTempusAccess
                                 A QGIS plugin
 Analyse de l'offre de transport en commun
                              -------------------
        begin                : 2016-10-22
        git sha              : $Format:%H$
        copyright            : (C) 2016 by Cerema
        email                : Aurelie.bousquet@cerema.fr, Patrick.Palmier@cerema.fr, helene.ly@cerema.fr
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
# import the PyQt and QGIS libraries
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from PyQt4.Qt import *
from PyQt4 import QtSql
from qgis.core import *
from qgis.utils import iface


# Initialize Qt resources from file resources.py
import subprocess
import resources
import sys
import string
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_DBConnectionDialog import Ui_Dialog


class DBConnectionDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)        
        
        self.caller = caller
        self.iface = self.caller.iface
        
        self.ui.lineEdit_login.setText(os.getenv("USERNAME"))
        self.modelDB = QtSql.QSqlQueryModel()
        self.plugin_dir = self.caller.plugin_dir
                
        # Connexion des signaux et des slots
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.pushButtonImportDB.clicked.connect(self._slotPushButtonImportDBClicked)
        self.ui.pushButtonBackupDB.clicked.connect(self._slotPushButtonBackupDBClicked)
        self.ui.pushButtonInitDB.clicked.connect(self._slotPushButtonInitDBClicked)
        self.ui.pushButtonDelete.clicked.connect(self._slotPushButtonDeleteClicked)
        self.ui.pushButtonUseDB.clicked.connect(self._slotPushButtonUseDBClicked)
        self.ui.pushButtonCancel.clicked.connect(self._slotCancel)
        self.ui.comboBoxDB.currentIndexChanged.connect(self._slotComboBoxDBIndexChanged)
    
    
    def refreshDBList(self):
        s="select substring(datname from 14 for length(datname)) as datname from pg_database\
            WHERE datname like 'tempusaccess_%'\
            ORDER BY 1";            
        self.modelDB.setQuery(s, self.caller.db)
    
    
    def firstDBConnection(self):
        self.caller.host = str(self.ui.lineEdit_host.text())
        self.caller.login = str(self.ui.lineEdit_login.text())
        self.caller.port = str(self.ui.lineEdit_port.text())
        self.caller.pwd = str(self.ui.lineEdit_pwd.text())
        self.caller.base = "postgres"
        
        self.caller.db.setHostName(self.caller.host)
        self.caller.db.setUserName(self.caller.login)
        self.caller.db.setPort(int(self.caller.port))
        self.caller.db.setPassword(self.caller.pwd)
        self.caller.db.setDatabaseName(self.caller.base)
        
        self.caller.db.open()  
    
    
    def updateDBConnection(self):        
        self.DBName = str(self.ui.comboBoxDB.currentText())
        
        self.caller.host = str(self.ui.lineEdit_host.text())
        self.caller.login = str(self.ui.lineEdit_login.text())
        self.caller.port = str(self.ui.lineEdit_port.text())
        self.caller.pwd = str(self.ui.lineEdit_pwd.text())
        self.caller.base = "tempusaccess_"+self.DBName
        
        self.caller.db.setHostName(self.caller.host)
        self.caller.db.setUserName(self.caller.login)
        self.caller.db.setPort(int(self.caller.port))
        self.caller.db.setPassword(self.caller.pwd)
        self.caller.db.setDatabaseName(self.caller.base)
        
        self.caller.db.open()
    
       
    def _slotCancel(self):
        self.hide()
        
    
    def _slotPushButtonImportDBClicked(self):
        ret = QMessageBox.question(self, "TempusAccess", u"La base de données va être réinitialisée. Toutes les données présentes seront écrasées et remplacées par le fichier choisi. \n Confirmez-vous vouloir faire cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)

        if (ret == QMessageBox.Ok):
            # Restart database server to be sure deleting "TempusAccess" database will be allowed (avoids still connected applications)
            nom_fichier = QFileDialog.getOpenFileName(caption = "Restaurer la base de données...", directory=self.caller.data_dir, filter = "Backup files (*.backup)")
            
            self.updateDBConnection()
            
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                
                cmd = [ "pglite", "stop" ]
                r = subprocess.call( cmd, shell=True )
            
                cmd = [ "pglite", "start" ]
                r = subprocess.call( cmd, shell=True )
                
                # Delete database "TempusAccess" (if exists) and (re)create
                cmd = [ "dropdb", "-h", self.caller.host, "-p", self.caller.port, self.caller.base]
                r = subprocess.call( cmd, shell=True )
                
                cmd = [ "createdb", "-h", self.ui.lineEdit_host.text(), "-p", self.ui.lineEdit_port.text(), self.caller.base]
                r = subprocess.call( cmd, shell=True )
                
                cmd = [self.plugin_dir+"/exe/runtime/pg_restore.exe",  "-h", self.ui.lineEdit_host.text(), "-p", self.ui.lineEdit_port.text(), "-d", self.caller.base, "-U", os.getenv("USERNAME"), "-w", "-O", "-x", "-v", nom_fichier]
                r = subprocess.call( cmd, shell=True )
            
            self._slotPushButtonUseDBClicked()
            self.caller.DBConnectionDialog.hide()
    
            box = QMessageBox()
            box.setText(u"L'import de la base est terminé. " )
            box.exec_()
    
    
    def _slotPushButtonBackupDBClicked(self):
        nom_fichier = QFileDialog.getSaveFileName(caption = "Enregistrer la base de données sous...", directory=self.caller.data_dir, filter = "Backup files (*.backup)")
        with open(self.plugin_dir+"/log.txt", "a") as log_file:
            cmd = [self.plugin_dir+"/exe/runtime/pg_dump.exe", "--host", self.ui.lineEdit_host.text(), "--port", self.ui.lineEdit_port.text(), "--username", os.getenv("USERNAME"), "--no-password", "--format", "custom", "--encoding", "UTF8", "--no-privileges", "--verbose", "--file", nom_fichier, "-d", self.caller.base]
            r = subprocess.call( cmd, shell=True )
    
    
    def _slotPushButtonUseDBClicked(self):
        root = QgsProject.instance().layerTreeRoot()
        
        # Remove old layers
        self.caller.node_group = root.findGroup("Analyse de l'offre de transport collectif")
        root.removeChildNode(self.caller.node_group)
        
        # Create new layers groups to display in the legend interface
        self.caller.node_group = root.insertGroup(0, "Analyse de l'offre de transport collectif")
        self.caller.node_group.setExpanded(True)
        self.caller.node_indicators=self.caller.node_group.insertGroup(0, u"Indicateurs calculés")
        self.caller.node_indicators.setExpanded(False)
        self.caller.node_pt_offer=self.caller.node_group.insertGroup(1, u"Offre de transport collectif")
        self.caller.node_pt_offer.setExpanded(False)
        self.caller.node_road_offer=self.caller.node_group.insertGroup(2, u"Offre routière")
        self.caller.node_road_offer.setExpanded(False)
        self.caller.node_vacances=self.caller.node_group.insertGroup(3, u"Vacances scolaires et jours fériés")
        self.caller.node_vacances.setExpanded(False)
        self.caller.node_admin=self.caller.node_group.insertGroup(4, u"Zonages")
        self.caller.node_admin.setExpanded(False)
        
        # Program database connection
        self.updateDBConnection()
        
        if (self.caller.db.open() == False):
            self.ui.pushButtonImportDB.setEnabled(False)
            self.ui.pushButtonBackupDB.setEnabled(False)
            box = QMessageBox()
            box.setText(u"La connexion à la base de données a échoué :" + unicode(self.caller.db.lastError().text()))
            box.exec_()
        
        else: # if connection succeeds
            self.ui.pushButtonImportDB.setEnabled(True)
            self.ui.pushButtonBackupDB.setEnabled(True)
            
            self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type ORDER BY code", self.caller.db)
            self.caller.modelPerType.setQuery("SELECT mod_lib, mod_code, mod_data FROM tempus_access.modalities WHERE var = 'per_type' ORDER BY mod_code", self.caller.db)
            self.caller.modelAgreg.setQuery("SELECT lib, code, func_name FROM tempus_access.agregates ORDER BY code", self.caller.db)
            self.caller.modelDayType.setQuery("SELECT mod_lib, mod_code, mod_data FROM tempus_access.modalities WHERE var = 'day_type' ORDER BY mod_code", self.caller.db)
            self.caller.modelCriterion.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'opt_crit' ORDER BY mod_code", self.caller.db)
            self.caller.modelRepMeth.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'rep_meth' ORDER BY mod_code", self.caller.db)
            self.caller.modelRoadEncoding.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'encoding' ORDER BY mod_code", self.caller.db)
            self.caller.modelPOIEncoding.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'encoding' ORDER BY mod_code", self.caller.db)
            self.caller.modelRoadFormat.setQuery("SELECT distinct format_name, format_short_name, format_id FROM tempus_access.formats WHERE format_type = 'road' ORDER BY format_id", self.caller.db)
            self.caller.modelPTFormat.setQuery("SELECT distinct format_name, format_short_name, format_id FROM tempus_access.formats WHERE format_type = 'pt' ORDER BY format_id", self.caller.db)
            self.caller.modelPOIFormat.setQuery("SELECT distinct format_name, format_short_name, format_id FROM tempus_access.formats WHERE format_type = 'poi' ORDER BY format_id", self.caller.db)
            self.caller.modelNodeType.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'node_type' ORDER BY mod_code", self.caller.db)
            
            # Individual modes model
            s="SELECT name, id FROM tempus.transport_mode WHERE gtfs_feed_id IS NULL"
            self.caller.modelIModes.setQuery(unicode(s), self.caller.db)
            self.caller.dlg.ui.listViewIModes.selectAll()            
                                
            self.caller.modelAreaType.setQuery("(SELECT lib, code FROM tempus_access.areas_param UNION SELECT '', -1) ORDER BY 2", self.caller.db)
            self.caller.refreshGTFSFeeds()
                            
            # Already calculated queries model
            self.caller.refreshReq()
            
            # Update the map window
            self.caller.loadLayers()
                        
            # Set object type on "stop areas"
            self.caller._slotComboBoxObjTypeIndexChanged(0)
            
            # Close current window
            self.hide()
    
    
    def _slotComboBoxDBIndexChanged(self):
        self.updateDBConnection()
                
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('tempus_gtfs')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        while (q.next()):
            self.ui.labelPTDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('tempus')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        while (q.next()):
            self.ui.labelRouteDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('indic')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        while (q.next()):
            self.ui.labelIndicDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('sncf', 'rte500', 'admin')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        while (q.next()):
            self.ui.labelAuxDataSize.setText(str(q.value(1)) + " Mo")
    
    
    def _slotPushButtonInitDBClicked(self):
        self.firstDBConnection()
        DBName = self.ui.comboBoxDB.currentText()
        
        s="SELECT count(*) from pg_database\
            WHERE datname = 'tempusaccess_"+DBName+"'";
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        q.next()
        
        if (int(q.value(0))>0):
            ret = QMessageBox.question(self, "TempusAccess", u"La base de données 'tempusaccess_"+DBName+u"' existe déjà et va être réinitialisée : toutes les données présentes seront écrasées. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
        else:
            ret = QMessageBox.Ok
        
        if (ret == QMessageBox.Ok):
            self.updateDBConnection()  
            
            self.prog = QProgressDialog(self)
            self.prog.setCancelButton(None)
            self.prog.setMinimum(0)
            self.prog.setMaximum(100)
            self.prog.setAutoClose(True)
            self.prog.setWindowTitle(u"En cours...")
            self.prog.show()
            
            self.prog.setValue(5)
            
            root = QgsProject.instance().layerTreeRoot()
            node_group=root.findGroup("Analyse de l'offre de transport collectif")
            root.removeChildNode(node_group)
            
            # Restart database server to be sure deleting "TempusAccess" database will be allowed (avoids still connected applications)
            cmd = [ "python", "-m", "pglite", "stop" ]
            r = subprocess.call( cmd, shell=True )
        
            cmd = [ "python", "-m", "pglite", "start" ]
            r = subprocess.call( cmd, shell=True )
            
            self.prog.setValue(15)
            
            # Delete database (if exists) and (re)create
            cmd = [ "dropdb", "-h", self.caller.host, "-p", self.caller.port, self.caller.base ]
            r = subprocess.call( cmd, shell=True )
        
            cmd = [ "createdb", "-h", self.caller.host, "-p", self.caller.port, self.caller.base ]
            r = subprocess.call( cmd, shell=True )
            
            self.firstDBConnection()
            self.refreshDBList()
            self.ui.comboBoxDB.setCurrentIndex(self.ui.comboBoxDB.findText(DBName))
            self.updateDBConnection()
            
            self.prog.setValue(25)
            
            
            if (self.caller.db.open() == False): # This should never be the case
                self.ui.pushButtonImportDB.setEnabled(False)
                self.ui.pushButtonBackupDB.setEnabled(False)
                box = QMessageBox()
                box.setText(u"La connexion à la base de données a échoué :" + unicode(self.caller.db.lastError().text()))
                box.exec_()
                
            else: 
                # Create data schema "tempus" and "tempus_gtfs"
                dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
                cmd = ["python", self.caller.load_tempus_path, "-t", "osm", "-d", dbstring, "-R"]
                r = subprocess.call( cmd, shell=True )
                
                self.prog.setValue(50)
                
                # Add to data schema "tempus" et "tempus_gtfs" application specific elements, mainly in tempus_access schema
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/init_bdd.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_pt_stop_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_pt_section_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_pt_trip_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_pt_route_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_pt_agency_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
            
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_path_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
            
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_path_details_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_paths_tree_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_comb_paths_trees_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.sql_dir + "/function_create_isosurfaces_indicator_layer.sql"]
                r = subprocess.call( cmd, shell=True )
                
                self.prog.setValue(60)
                
                # Import holidays definition file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.holidays FROM "+self.caller.data_dir + "/others/holidays.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
            
                # Import modalities definition file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.modalities FROM "+self.caller.data_dir + "/system/modalities.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
            
                # Import formats definition file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.formats FROM "+self.caller.data_dir + "/system/formats.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
                
                # Import agregates definition file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.agregates FROM "+self.caller.data_dir + "/system/agregates.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
            
                # Import areas definition file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.areas_param FROM "+self.caller.data_dir + "/areas/areas_param.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
            
                # Import object types file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.obj_type FROM "+self.caller.data_dir + "/system/obj_type.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
            
                # Import indicators file
                cmd=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.indicators FROM "+self.caller.data_dir + "/system/indicators.csv CSV HEADER DELIMITER ';'"]
                r = subprocess.call( cmd, shell=True )
                
                self.prog.setValue(70)
                
                s="SELECT lib, code, file_name, id_field, name_field, from_srid FROM tempus_access.areas_param\
                ORDER BY 2"
                q=QtSql.QSqlQuery(self.caller.db)
                q.exec_(unicode(s))
                
                while q.next():
                    cmd=["ogr2ogr.exe", "-f", "PostgreSQL", "PG:dbname="+self.caller.base+" host="+self.caller.host+" port="+self.caller.port, self.caller.data_dir + "/areas/" + q.value(2), "-overwrite", "-lco", "GEOMETRY_NAME=geom", "-s_srs", "EPSG:"+str(q.value(5)), "-t_srs", "EPSG:4326", "-nln", "tempus_access.area_type"+str(q.value(1)), "-nlt", "PROMOTE_TO_MULTI"]
                    r = subprocess.call( cmd, shell=True )
                    # Uniformisation of field names and index creation
                    t="ALTER TABLE tempus_access.area_type"+str(q.value(1))+" RENAME COLUMN "+str(q.value(4))+" TO lib; \
                    ALTER TABLE tempus_access.area_type"+str(q.value(1))+" RENAME COLUMN "+str(q.value(3))+" TO char_id; \
                    CREATE INDEX IF NOT EXISTS area_type"+str(q.value(1))+"_lib_idx ON tempus_access.area_type"+str(q.value(1))+" USING gist (lib gist_trgm_ops); \
                    CREATE INDEX IF NOT EXISTS area_type"+str(q.value(1))+"_char_id_idx ON tempus_access.area_type"+str(q.value(1))+" USING btree (char_id);"
                    r=QtSql.QSqlQuery(self.caller.db)
                    r.exec_(unicode(t)) 
                
                #self.caller.modelAreaType.setQuery(unicode(s), self.caller.db)
            
                self.prog.setValue(100)
            
                box = QMessageBox()
                box.setText(u"La base a été initialisée. Vous pouvez maintenant y importer des données. " )
                box.exec_()
        
        
    def _slotPushButtonDeleteClicked(self):
        self.DBName = self.ui.comboBoxDB.currentText()
        self.firstDBConnection()
        
        s="select count(*) from pg_database\
            WHERE datname = 'tempusaccess_"+self.DBName+"'";
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        q.next()
        
        if (int(q.value(0))>0):
            ret = QMessageBox.question(self, "TempusAccess", u"La base de données 'tempusaccess_"+self.DBName+u"' va être supprimée. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
            self.caller.db.close()
        else:
            ret = QMessageBox.warning(self, "TempusAccess", u"La base de données 'tempusaccess_"+self.DBName+u"' n'existe pas.", QMessageBox.Cancel, QMessageBox.Cancel)
        
        if (ret == QMessageBox.Ok):         
            # Restart database server to be sure deleting "TempusAccess" database will be allowed (avoids still connected applications)
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                
                root = QgsProject.instance().layerTreeRoot()
                self.caller.node_group = root.findGroup("Analyse de l'offre de transport collectif")
                root.removeChildNode(self.caller.node_group)
                
                cmd = [ "pglite", "stop" ]
                r = subprocess.call( cmd, shell=True )
            
                cmd = [ "pglite", "start" ]
                r = subprocess.call( cmd, shell=True )
            
                # Delete database
                cmd = [ "dropdb", "-h", self.caller.host, "-p", self.caller.port, "tempusaccess_"+self.DBName ]
                r = subprocess.call( cmd, shell=True )
            
            self.firstDBConnection()
            self.refreshDBList()
            self.updateDBConnection()
    
    

    
    