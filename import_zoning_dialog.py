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
from Ui_import_zoning_dialog import Ui_Dialog

class import_zoning_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        self.iface = self.caller.iface
        
        self.plugin_dir = self.caller.plugin_dir        
        
        self.ui.comboBoxFormat.setModel(self.caller.modelZoningSourceFormat)
        self.ui.comboBoxFormatVersion.setModel(self.caller.modelZoningSourceFormatVersion)
        self.ui.comboBoxEncoding.setModel(self.caller.modelEncoding)
        
        # Connect signals and slots
        self._connectSlots()
        self.format = ''
        self.format_compl = ''
        
        
    def _connectSlots(self):
        self.ui.comboBoxFormat.currentIndexChanged.connect(self._slotComboBoxFormatCurrentIndexChanged)
        self.ui.pushButtonChoose.clicked.connect(self._slotPushButtonChooseClicked)
        self.ui.comboBoxFormatVersion.currentIndexChanged.connect(self._slotComboBoxFormatVersionCurrentIndexChanged)
        self.ui.lineEditSourceName.textChanged.connect(self._slotLineEditSourceNameTextChanged)
        self.ui.buttonBox.button(QDialogButtonBox.Close).clicked.connect(self._slotClose)
        
		
    def _slotLineEditSourceNameTextChanged(self):
        if (self.ui.lineEditSourceName.text()!=""):
            self.ui.pushButtonChoose.setEnabled(True)
        else:
            self.ui.pushButtonChoose.setEnabled(False)
    
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelZoningSourceFormat.record(self.ui.comboBoxFormat.currentIndex()).value("data_format")
        self.caller.modelZoningSourceFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE data_type = 'zoning' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)
        
        
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            self.ui.spinBoxSRID.setValue(self.caller.modelZoningSourceFormatVersion.record(indexChosenLine).value("default_srid"))
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelZoningSourceFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.path_type = self.caller.modelZoningSourceFormatVersion.record(indexChosenLine).value("path_type")
            if (self.format == 'ign_adminexpress'):
                self.ui.lineEditSourceComment.setText('')
                self.ui.lineEditSourceComment.setEnabled(False)
                self.ui.labelSourceComment.setEnabled(False)
                self.ui.lineEditIdField.setText("")
                self.ui.lineEditIdField.setEnabled(False)
                self.ui.labelIdField.setEnabled(False)
                self.ui.lineEditNameField.setText("")
                self.ui.lineEditNameField.setEnabled(False)
                self.ui.labelNameField.setEnabled(False)
                self.ui.lineEditPrefix.setText("")
                self.ui.lineEditPrefix.setEnabled(True)
                self.ui.labelPrefix.setEnabled(True)
                self.ui.lineEditFilter.setText("")
                self.ui.lineEditFilter.setEnabled(False)
                self.ui.labelFilter.setEnabled(False)
            elif (self.format == 'tempus'):
                self.ui.lineEditSourceComment.setText('')
                self.ui.lineEditSourceComment.setEnabled(True)
                self.ui.labelSourceComment.setEnabled(True)
                self.ui.lineEditIdField.setText("")
                self.ui.lineEditIdField.setEnabled(True)
                self.ui.labelIdField.setEnabled(True)
                self.ui.lineEditNameField.setText("")
                self.ui.lineEditNameField.setEnabled(True)
                self.ui.labelNameField.setEnabled(True)
                self.ui.lineEditPrefix.setText("")
                self.ui.lineEditPrefix.setEnabled(False)
                self.ui.labelPrefix.setEnabled(False)
                self.ui.lineEditFilter.setText("")
                self.ui.lineEditFilter.setEnabled(True)
                self.ui.labelFilter.setEnabled(True)
            
            
    def _slotPushButtonChooseClicked(self):
        if (self.ui.lineEditSourceName.text() == '') or (self.format == 'tempus' and ((self.ui.lineEditSourceComment.text() == '') or (self.ui.lineEditIdField.text() == '') or (self.ui.lineEditNameField.text() == ''))):
            box = QMessageBox()
            box.setText(unicode("Certains paramètres obligatoires ne sont pas renseignés."))
            box.exec_()
        else:
            cheminComplet = ''
            if (self.path_type=="directory"):
                cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir, caption="Choisir un dossier contenant la source à charger")
            else:
                cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.data_dir, filter = "(*"+self.path_type+")")
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.srid = self.ui.spinBoxSRID.value()
            self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
            self.source_name = unicode(self.ui.lineEditSourceName.text())
            self.prefix = unicode(self.ui.lineEditPrefix.text())
            self.model_version = str(self.caller.modelZoningSourceFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version"))
            self.filter = unicode(self.ui.lineEditFilter.text())
            self.id_field = unicode(self.ui.lineEditIdField.text())
            self.name_field = unicode(self.ui.lineEditNameField.text())
            
            cmd=["python", TEMPUSLOADER, "--action", "import", "--data-type", "zoning", "--data-format", self.format, "--source-name", self.source_name, "--path", cheminComplet, "--encoding", self.encoding, '--srid', str(self.srid), '--dbstring', dbstring]
            if (self.prefix != ""):
                cmd.append("--prefix")
                cmd.append(self.prefix)
            if (self.model_version != 'NULL'):
                cmd.append('--model-version')
                cmd.append(self.model_version)
            if (self.filter != ''):
                cmd.append('--filter')
                cmd.append(self.filter)
            if (self.ui.lineEditSourceComment.text()!=''):
                cmd.append("--source-comment")
                cmd.append(self.ui.lineEditSourceComment.text())
            if (self.format == "tempus"):
                cmd.append("--id-field")
                cmd.append(self.id_field)
                cmd.append("--name-field")
                cmd.append(self.name_field)
            
            self.ui.lineEditCommand.setText(" ".join(cmd))
                        
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            box.setModal(True)
            if (rc==0):
                self.caller.iface.mapCanvas().refreshMap()

                box.setText(u"L'import de la source est terminé.")
                
                self.caller.refreshZoningSources()
                
                self.caller.node_zoning.removeAllChildren()
                
                uri=QgsDataSourceURI()
                uri.setConnection(self.caller.db.hostName(), str(self.caller.db.port()), self.caller.db.databaseName(), self.caller.db.userName(), self.caller.db.password())
                
                for i in range(0,self.caller.modelZoningSource.rowCount()):
                    if (self.caller.modelZoningSource.record(i).value("id")!=-1):
                        uri.setDataSource("zoning", self.caller.modelZoningSource.record(i).value("name"), "geom", "")
                        layer = QgsVectorLayer(uri.uri(), self.caller.modelZoningSource.record(i).value("comment"), "postgres")
                        if (layer.isValid()):
                            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
                            node_layer = QgsLayerTreeLayer(layer)
                            self.caller.node_zoning.insertChildNode(i, node_layer)
                            self.iface.legendInterface().setLayerVisible(layer, False)
                self.caller.node_zoning.setExpanded(True)
                
                # Zoom to the loaded zoning data
                if (self.format == 'tempus'):
                    layersList = [ layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if (layer.name() == self.ui.lineEditSourceComment.text()) ]
                elif (self.format == 'ign_adminexpress'):
                    layersList = [ layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name() == "Communes") or (layer.name() == u"Départements") or (layer.name() == u"Régions")) ]
                self.caller.zoomToLayersList(layersList, True)
                
            else:
                box.setText(u"Erreur pendant l'import.\n Pour en savoir plus, ouvrir la console Python de QGIS et relancer la commande.")
            box.exec_()
        
            
            
    def _slotClose(self):
        self.hide()
                
        