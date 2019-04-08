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

from config import *
from thread_tools import *

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_manage_db_dialog import Ui_Dialog


class manage_db_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)        
        
        self.caller = caller
        self.iface = self.caller.iface
        
        self.plugin_dir = self.caller.plugin_dir
        
        self.temp_db = QtSql.QSqlDatabase.addDatabase("QPSQL", connectionName="temp_db")
        
        self.ui.comboBoxDB.setModel(self.caller.modelDB)
                
        # Connexion des signaux et des slots
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.comboBoxDB.currentIndexChanged.connect(self._slotComboBoxDBIndexChanged) 
        self.ui.pushButtonExport.clicked.connect(self._slotPushButtonExportClicked)
        self.ui.pushButtonDelete.clicked.connect(self._slotPushButtonDeleteClicked)
        self.ui.pushButtonLoad.clicked.connect(self._slotPushButtonLoadClicked)
        self.ui.pushButtonImport.clicked.connect(self._slotPushButtonImportClicked)
        self.ui.pushButtonCreate.clicked.connect(self._slotPushButtonCreateClicked)
        self.ui.buttonBox.button(QDialogButtonBox.Close).clicked.connect(self._slotClose)
    
    
    def updateDBConnection(self):
        self.caller.db.setDatabaseName(self.ui.labelLoadedDB.text())        
        self.caller.db.open()
    
    
    def _slotPushButtonImportClicked(self):
        s="SELECT count(*) from pg_database\
            WHERE datname = 'tempusaccess_"+self.ui.lineEditNewDB.text()+"'";
        q=QtSql.QSqlQuery(unicode(s), self.caller.db)
        q.next()
        create = True
        
        if (int(q.value(0))>0):
            ret = QMessageBox.question(self, "TempusAccess", u"La base de données 'tempusaccess_"+self.ui.lineEditNewDB.text()+u"' existe déjà et va être réinitialisée : toutes les données présentes seront écrasées. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
            create = False
        else:
            ret = QMessageBox.Ok
        
        if (ret == QMessageBox.Ok):
            # Restart database server to be sure deleting "TempusAccess" database will be allowed (avoids still connected applications)
            nom_fichier = QFileDialog.getOpenFileName(caption = "Restaurer la base de données...", directory=self.caller.data_dir, filter = "Backup files (*.backup)")
            
            if (create == True):
                cmd = [ "createdb", "-h", self.caller.db.hostName(), "-U", self.caller.db.userName(), "-p", str(self.caller.db.port()), "tempusaccess_"+self.ui.lineEditNewDB.text() ]
                r = subprocess.call( cmd )
            
            self.caller.set_db_connection_dialog.refreshDBList()
            self.ui.comboBoxDB.setCurrentIndex(self.ui.comboBoxDB.findText(self.ui.lineEditNewDB.text()))
                        
            s="DROP SCHEMA IF EXISTS _tempus_import CASCADE;\
            DROP SCHEMA IF EXISTS _tempus_export CASCADE;\
            DROP SCHEMA IF EXISTS indic CASCADE;\
            DROP SCHEMA IF EXISTS tempus CASCADE;\
            DROP SCHEMA IF EXISTS tempus_access CASCADE;\
            DROP SCHEMA IF EXISTS tempus_gtfs CASCADE;\
            DROP FUNCTION IF EXISTS _drop_index(text, text, text);\
            DROP FUNCTION IF EXISTS notice(text, anyelement);"
            q=QtSql.QSqlQuery(self.temp_db)
            q.exec_(unicode(s))
            
            cmd = [PGRESTORE,  "-h", self.temp_db.hostName(), "-p", str(self.temp_db.port()), "-d", self.temp_db.databaseName(), "-U",  self.temp_db.userName(), "-w", "-O", "-x", "-v", nom_fichier]
            self.ui.lineEditCommand.setText(" ".join(cmd))
            
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            box.setModal(True)
            if (rc==0):
                self.caller.iface.mapCanvas().refresh()
                box.setText(u"L'import de la base s'est terminé avec succès. ")
                self._slotPushButtonLoadClicked()
            else:
                box.setText(u"L'import de la base a échoué ou a retourné des avertissements.\nPour en savoir plus, ouvrir la console Python de QGIS et relancer la commande.")
            box.exec_()    
        
        
    def _slotPushButtonCreateClicked(self):
        if (self.ui.lineEditNewDB.text() == ''):
            box = QMessageBox()
            box.setText(unicode(u"Spécifiez le nom de la base à créer."))
            box.exec_()
        else:
            s="SELECT count(*) from pg_database\
                WHERE datname = 'tempusaccess_"+self.ui.lineEditNewDB.text()+"'";
            q=QtSql.QSqlQuery(unicode(s), self.caller.db)
            q.next()
            create = True
            
            if (int(q.value(0))>0):
                ret = QMessageBox.question(self, "TempusAccess", u"La base de données 'tempusaccess_"+self.ui.lineEditNewDB.text()+u"' existe déjà et va être réinitialisée : toutes les données présentes seront écrasées. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
                create = False
            else:
                ret = QMessageBox.Ok
            
            if (ret == QMessageBox.Ok):            
                if (create == True):
                    cmd = [ "createdb", "-h", self.caller.db.hostName(), "-U", self.caller.db.userName(), "-p", str(self.caller.db.port()), "tempusaccess_"+self.ui.lineEditNewDB.text() ]
                    rc = execute_external_cmd( cmd )
                    
                self.caller.set_db_connection_dialog.refreshDBList()
                
                dbstring = "host="+self.caller.db.hostName()+" dbname=tempusaccess_"+self.ui.lineEditNewDB.text()+" port="+str(self.caller.db.port())
                cmd = ["python", TEMPUSLOADER, "--action", "reset", "--tempusaccess", "--path", self.plugin_dir + "/data/system.zip", "--sep", ";", "--encoding", "UTF8", "-d", dbstring]
                
                rc = execute_external_cmd( cmd )
                box = QMessageBox()
                box.setModal(True)
                if (rc==0):
                    self.iface.mapCanvas().refreshMap()
                    box.setText(u"La base a été créée. Vous pouvez maintenant y importer des données.")                    
                    self.ui.comboBoxDB.setCurrentIndex( self.ui.comboBoxDB.findText( self.ui.lineEditNewDB.text() ) )
                    self._slotPushButtonLoadClicked()
                else:
                    box.setText(u"Erreur pendant la création de la base.\nPour en savoir plus, ouvrir la console Python de QGIS et relancer la commande.")
                box.exec_()
             
                
    def _slotComboBoxDBIndexChanged(self):
        self.temp_db.setHostName(self.caller.db.hostName())
        self.temp_db.setUserName(self.caller.db.userName())
        self.temp_db.setPort(int(self.caller.db.port()))
        self.temp_db.setPassword(self.caller.db.password())
        self.temp_db.setDatabaseName("tempusaccess_"+str(self.ui.comboBoxDB.currentText()))
        self.temp_db.open()
        
        # Update size statistics
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('tempus_gtfs')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.temp_db)
        while (q.next()):
            self.ui.labelPTDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('tempus')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.temp_db)
        while (q.next()):
            self.ui.labelRouteDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('indic')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.temp_db)
        while (q.next()):
            self.ui.labelIndicDataSize.setText(str(q.value(1)) + " Mo")
        
        s="SELECT table_schema, sum(pg_total_relation_size(table_schema || '.' || table_name))/(1024*1024) As size\
           FROM information_schema.tables\
           WHERE table_schema IN ('tempus_access')\
           GROUP BY table_schema"
        q=QtSql.QSqlQuery(unicode(s), self.temp_db)
        while (q.next()):
            self.ui.labelAuxDataSize.setText(str(q.value(1)) + " Mo")
    
    
    def _slotPushButtonExportClicked(self):
        nom_fichier = QFileDialog.getSaveFileName(caption = "Enregistrer la base de données sous...", directory=self.caller.data_dir, filter = "Backup files (*.backup)")
        
        if nom_fichier:
            cmd = [PGDUMP, "--host", self.temp_db.hostName(), "--port", str(self.temp_db.port()), "--username", self.temp_db.userName(), "--no-password", "--format", "custom", "--encoding", "UTF8", "--no-privileges", "--verbose", "--file", nom_fichier, "-d", self.temp_db.databaseName()]
            self.ui.lineEditCommand.setText(" ".join(cmd))
            rc = execute_external_cmd( cmd )
            
            box = QMessageBox()
            box.setModal(True)
            if (rc==0):
                box.setText(u"La sauvegarde s'est terminée avec succès.")
            else:
                box.setText(u"La sauvegarde a échoué.")
            box.exec_()
    
    
    def _slotPushButtonDeleteClicked(self):
        s="select count(*) from pg_database\
            WHERE datname = 'tempusaccess_"+str(self.ui.comboBoxDB.currentText())+"'";
        q=QtSql.QSqlQuery(unicode(s), self.temp_db)
        q.next()
        
        if (int(q.value(0))>0):
            ret = QMessageBox.question(self, "TempusAccess", u"La base de données 'tempusaccess_"+str(self.ui.comboBoxDB.currentText())+u"' va être supprimée. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel, QMessageBox.Cancel)
        else:
            ret = QMessageBox.warning(self, "TempusAccess", u"La base de données 'tempusaccess_"+str(self.ui.comboBoxDB.currentText())+u"' n'existe pas.", QMessageBox.Cancel, QMessageBox.Cancel)
        
        if (ret == QMessageBox.Ok):
            self.ui.labelLoadedDB.setText('...')
            
            # Restart database server to be sure deleting "TempusAccess" database will be allowed (avoids still connected applications)
            cmd = [ "python", "-m", "pglite", "stop" ]
            r = subprocess.call( cmd )
            
            cmd = [ "python", "-m", "pglite", "start" ]
            r = subprocess.call( cmd )
            
            # Delete database
            cmd = [ "dropdb", "-h", self.caller.db.hostName(), "-U", self.caller.db.userName(), "-p", str(self.caller.db.port()), "tempusaccess_"+str(self.ui.comboBoxDB.currentText()) ]
            rc = execute_external_cmd( cmd )
            
            box = QMessageBox()
            if (rc==0):
                box.setText(u"La suppression s'est terminée avec succès.")
            else:
                box.setText(u"La suppression a échoué.")
            box.exec_()
            
            self.caller.set_db_connection_dialog.refreshDBList()
    
    
    def _slotPushButtonLoadClicked(self):
        self.ui.labelLoadedDB.setText("tempusaccess_"+self.ui.comboBoxDB.currentText())
        self.updateDBConnection()
        
        if self.caller.db.open():
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
            self.caller.node_zoning=self.caller.node_group.insertGroup(4, u"Zonages")
            self.caller.node_zoning.setExpanded(False)
        
            self.ui.pushButtonExport.setEnabled(True)
            self.ui.pushButtonDelete.setEnabled(True)
            self.ui.pushButtonLoad.setEnabled(True)
            self.caller.refreshRoadNetworks()
            self.caller.modelRoadNetworkFormat.setQuery("SELECT distinct data_format_name, data_type, data_format FROM tempus_access.formats WHERE data_type = 'road' ORDER BY data_format_name", self.caller.db)
            self.caller.refreshPTNetworks()
            self.caller.modelPTNetworkFormat.setQuery("SELECT distinct data_format_name, data_type, data_format FROM tempus_access.formats WHERE data_type = 'pt' ORDER BY data_format_name", self.caller.db)
            self.caller.refreshPOISources()
            self.caller.modelPOISourceFormat.setQuery("SELECT distinct data_format_name, data_type, data_format FROM tempus_access.formats WHERE data_type = 'poi' ORDER BY data_format_name", self.caller.db)
            self.caller.modelPOIType.setQuery("SELECT name, id FROM tempus.poi_type ORDER BY id", self.caller.db)
            self.caller.refreshZoningSources()
            self.caller.modelZoningSourceFormat.setQuery("SELECT distinct data_format_name, data_type, data_format FROM tempus_access.formats WHERE data_type = 'zoning' ORDER BY data_format_name", self.caller.db)
            if (self.caller.modelPTNetwork.rowCount()>0):
                self.caller.modelNodeType.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'node_type' ORDER BY mod_code", self.caller.db)
            elif (self.caller.modelRoadNetwork.rowCount()>1):
                self.caller.modelNodeType.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'node_type' AND needs_pt = False ORDER BY mod_code", self.caller.db) 
            
            if (self.caller.modelPTNetwork.rowCount()>0):
                self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type ORDER BY code", self.caller.db)
            elif (self.caller.modelRoadNetwork.rowCount()>1):
                self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type WHERE needs_pt = False ORDER BY code", self.caller.db)
            self.caller.modelPerType.setQuery("SELECT mod_lib, mod_code, mod_data FROM tempus_access.modalities WHERE var = 'per_type' ORDER BY mod_code", self.caller.db)
            self.caller.modelAgreg.setQuery("SELECT lib, code, func_name FROM tempus_access.agregates ORDER BY code", self.caller.db)
            self.caller.modelDayType.setQuery("SELECT mod_lib, mod_code, mod_data FROM tempus_access.modalities WHERE var = 'day_type' ORDER BY mod_code", self.caller.db)
            self.caller.modelCriterion.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'opt_crit' ORDER BY mod_code", self.caller.db)
            self.caller.modelRepMeth.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'rep_meth' ORDER BY mod_code", self.caller.db)
            self.caller.modelEncoding.setQuery("SELECT mod_lib, mod_code FROM tempus_access.modalities WHERE var = 'encoding' ORDER BY mod_code", self.caller.db)
            
            # Individual modes model
            s="SELECT name, id FROM tempus.transport_mode WHERE gtfs_feed_id IS NULL"
            self.caller.modelIModes.setQuery(unicode(s), self.caller.db)
            self.caller.dlg.ui.listViewIModes.selectAll()                                
                            
            # Already calculated queries model
            self.caller.manage_indicators_dialog.refreshReq()
            
            # Update the map window
            self.caller.loadLayers()
            
            # Set object type on "stop areas"
            self.caller._slotComboBoxObjTypeIndexChanged(0)
        else:
            box = QMessageBox()
            box.setModal(True)
            box.setText(u"La connexion à la base a échoué.")
            box.exec_()
    
    
    def _slotClose(self):
        self.hide()

    
        
    

    
    