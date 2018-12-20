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
from Ui_import_poi_dialog import Ui_Dialog

class import_poi_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        self.plugin_dir = self.caller.plugin_dir        
        
        self.ui.comboBoxFormat.setModel(self.caller.modelPOISourceFormat)
        self.ui.comboBoxFormatVersion.setModel(self.caller.modelPOISourceFormatVersion)
        self.ui.comboBoxEncoding.setModel(self.caller.modelEncoding)
        self.ui.comboBoxPOIType.setModel(self.caller.modelPOIType)
        
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
    
    
    def _slotLineEditSourceNameTextChanged(self, text):
        if (self.ui.lineEditSourceName.text()!=""):
            self.ui.pushButtonChoose.setEnabled(True)
        else:
            self.ui.pushButtonChoose.setEnabled(False)

    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelPOISourceFormat.record(self.ui.comboBoxFormat.currentIndex()).value("data_format")
        self.caller.modelPOISourceFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE data_type = 'poi' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)

    
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            self.ui.spinBoxSRID.setValue(self.caller.modelPOISourceFormatVersion.record(indexChosenLine).value("default_srid"))
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelPOISourceFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.path_type = self.caller.modelPOISourceFormatVersion.record(indexChosenLine).value("path_type")
            if (self.format == 'insee_bpe'):
                self.ui.lineEditSourceComment.setText('')
                self.ui.lineEditSourceComment.setEnabled(False)
                self.ui.lineEditIdField.setText("")
                self.ui.lineEditIdField.setEnabled(False)
                self.ui.lineEditNameField.setText("")
                self.ui.lineEditNameField.setEnabled(False)
                self.ui.lineEditPrefix.setText("")
                self.ui.lineEditPrefix.setEnabled(True)
            elif (self.format == 'tempus'):
                self.ui.lineEditSourceComment.setText('')
                self.ui.lineEditSourceComment.setEnabled(True)
                self.ui.lineEditIdField.setText("")
                self.ui.lineEditIdField.setEnabled(True)
                self.ui.lineEditNameField.setText("")
                self.ui.lineEditNameField.setEnabled(True)
                self.ui.lineEditPrefix.setText("")
                self.ui.lineEditPrefix.setEnabled(False)
    
    
    def _slotPushButtonChooseClicked(self):
        if (self.ui.lineEditSourceName.text() == '') or (self.ui.lineEditSourceComment.text() == '') or (self.ui.lineEditIdField.text() == '') or (self.ui.lineEditNameField.text() == ''):
            box = QMessageBox()
            box.setText(u"Certains paramètres obligatoires ne sont pas renseignés.")
            box.exec_()
        else:
            cheminComplet = ''
            if (self.path_type=="directory"):
                cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir)
            else:
                cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.data_dir, filter = "(*"+self.path_type+")")
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.srid = self.ui.spinBoxSRID.value()
            self.prefix = unicode(self.ui.lineEditPrefix.text())
            self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
            self.source_name = unicode(self.ui.lineEditSourceName.text())
            self.source_comment = unicode(self.ui.lineEditSourceComment.text())
            self.model_version = str(self.caller.modelPOISourceFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version"))
            self.filter = unicode(self.ui.lineEditFilter.text())
            self.poi_type = self.caller.modelPOIType.record(self.ui.comboBoxPOIType.currentIndex()).value("id")
            self.id_field = unicode(self.ui.lineEditIdField.text())
            self.name_field = unicode(self.ui.lineEditNameField.text())
            
            cmd=["python", TEMPUSLOADER, "--action", "import", "--data-type", "poi", '--poi-type', str(self.poi_type), "--data-format", self.format, "--source-name", self.source_name, "--source-comment", self.source_comment, "--id-field", self.id_field, "--name-field", self.name_field, "--path", cheminComplet, "--encoding", self.encoding, '--srid', str(self.srid), '--dbstring', dbstring]
            if (self.prefix != ""):
                cmd.append("--prefix")
                cmd.append(self.prefix)
            if (str(self.model_version) != 'NULL'):
                cmd.append('--model-version')
                cmd.append(str(self.model_version))
            if (self.filter != ''):
                cmd.append('--filter')
                cmd.append(self.filter)
            
            self.ui.lineEditCommand.setText(" ".join(cmd))        
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            if (rc==0):
                self.caller.iface.mapCanvas().refreshMap()

                box.setText(unicode("L'import de la source est terminé."))
                
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
                layersList = [ layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"POI et stationnements"))]
                self.caller.zoomToLayersList(layersList)
            else:
                box.setText(unicode("Erreur pendant l'import.\n Pour en savoir plus, ouvrir la console Python de QGIS et relancer la commande."))
            box.exec_()            
            

    def _slotClose(self):
        self.hide()
            