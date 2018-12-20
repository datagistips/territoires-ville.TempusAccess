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
from PyQt4 import Qt, QtSql
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from qgis.core import *
from qgis.gui import *

# Initialize Qt resources from file resources.py
import resources
import sys
import string
import os
import subprocess

from config import *
from thread_tools import execute_external_cmd


sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_export_delete_pt_dialog import Ui_Dialog

class export_delete_pt_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        self.caller = caller
        self.db = caller.db
        self.iface = caller.iface
                
        self.ui.comboBoxSourceName.setModel(self.caller.modelPTNetwork)
        
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.pushButtonDelete.clicked.connect(self._slotPushButtonDeleteClicked)
        self.ui.pushButtonExport.clicked.connect(self._slotExportClicked)
        self.ui.buttonBox.button(QDialogButtonBox.Close).clicked.connect(self._slotClose)
    
    
    def _slotPushButtonDeleteClicked(self):
        ret = QMessageBox.question(self, "TempusAccess", u"La source de données sélectionnée va être supprimée. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)

        if (ret == QMessageBox.Ok): 
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.source_name = self.caller.modelPTNetwork.record(self.ui.comboBoxSourceName.currentIndex()).value("feed_id")
        
            uri=QgsDataSourceURI()
            uri.setConnection(self.caller.db.hostName(), str(self.caller.db.port()), self.caller.db.databaseName(), self.caller.db.userName(), self.caller.db.password())
            
            for layer in QgsMapLayerRegistry.instance().mapLayers().values():
                if (layer.name()==self.caller.modelPTNetwork.record(self.ui.comboBoxSourceName.currentIndex()).value("feed_id")):
                    QgsMapLayerRegistry.instance().removeMapLayer(layer.id())
            self.caller.node_pt_offer.setExpanded(True) 
            
            cmd=["python", TEMPUSLOADER, "--action", "delete", "--data-type", "pt", "--source-name", self.source_name, '--dbstring', dbstring]
            
            self.ui.lineEditCommand.setText(" ".join(cmd))
            
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            if (rc==0):
                self.caller.iface.mapCanvas().refreshMap()

                box.setText(u"Source supprimée avec succès" )
                
                self.caller.refreshPTNetworks()
                
            else:
                box.setText(u"Erreur pendant l'import. \nPour en savoir plus ouvrir la console Python de QGIS et relancer la commande. ")
            box.exec_()
        
        
    def _slotExportClicked(self):
        # Open a window to choose path to the GTFS source file 
        NomFichierComplet=''
        NomFichierComplet = QFileDialog.getSaveFileName(caption = "Enregistrer sous...", directory=self.caller.data_dir, filter = "Zip files (*.zip)")
        
        if (NomFichierComplet!=''):
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.source_name = self.caller.modelPTNetwork.record(self.ui.comboBoxSourceName.currentIndex()).value("name")
            
            cmd=["python", TEMPUSLOADER, "--action", "export", "--data-type", "pt", "--source-name", self.source_name, '--dbstring', dbstring, '--path', NomFichierComplet]
            
            self.ui.lineEditCommand.setText(" ".join(cmd))
            
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            if (rc==0):
                box.setText(u"Source exportée avec succès" )                
            else:
                box.setText(u"Erreur pendant l'export. \nPour en savoir plus, ouvrir la console Python de QGIS et relancer la commande. ")
            box.exec_()

            
    def _slotClose(self):
        self.hide()
        
        