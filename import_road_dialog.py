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
from Ui_import_road_dialog import Ui_Dialog

class import_road_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        self.iface = self.caller.iface 
        
        self.plugin_dir = self.caller.plugin_dir
        
        self.ui.comboBoxFormat.setModel(self.caller.modelRoadNetworkImportFormat)
        self.ui.comboBoxFormatVersion.setModel(self.caller.modelRoadNetworkFormatVersion)
        self.ui.comboBoxEncoding.setModel(self.caller.modelEncoding)
        
        # Connect signals and slots
        self._connectSlots()
        self.format = ''
        self.path_type = ''
        self.prefix = ''
        self.visum_modes = ''
        self.source_name = ''
        
        
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
        self.format = self.caller.modelRoadNetworkImportFormat.record(self.ui.comboBoxFormat.currentIndex()).value("data_format")
        self.caller.modelRoadNetworkFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE data_type = 'road_import' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)
    
    
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelRoadNetworkFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.ui.spinBoxSRID.setValue(self.caller.modelRoadNetworkFormatVersion.record(indexChosenLine).value("default_srid"))
            self.path_type = self.caller.modelRoadNetworkFormatVersion.record(indexChosenLine).value("path_type")
            if (self.format == "visum"):
                self.ui.lineEditVisumModes.setText('P,B,V,T')
                self.ui.lineEditVisumModes.setEnabled(True)
                self.ui.labelVisumModes1.setEnabled(True)
                self.ui.labelVisumModes2.setEnabled(True)
            else:
                self.ui.lineEditVisumModes.setEnabled(False)
                self.ui.labelVisumModes1.setEnabled(False)
                self.ui.labelVisumModes2.setEnabled(False)
                self.ui.lineEditVisumModes.setText('')
                if self.format=="osm":
                    self.ui.lineEditPrefix.setEnabled(False)
                else:
                    self.ui.lineEditPrefix.setEnabled(True)


    def _slotPushButtonChooseClicked(self):
        print self.path_type
        if (self.ui.lineEditSourceName.text() == ''):
            box = QMessageBox()
            box.setModal(True)
            box.setText(u"Certains paramètres obligatoires ne sont pas renseignés.")
            box.exec_()
        else:
            cheminComplet = ''
            if (self.path_type=="directory"):
                cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.last_dir)
            else:
                cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.last_dir, filter = "(*"+self.path_type+")")
                
            if cheminComplet != '':
                self.caller.last_dir = os.path.dirname(cheminComplet)
                dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
                self.srid = self.ui.spinBoxSRID.value()
                self.prefix = unicode(self.ui.lineEditPrefix.text())
                self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
                self.source_name = unicode(self.ui.lineEditSourceName.text())
                self.source_comment = unicode(self.ui.lineEditSourceComment.text())
                self.model_version = str(self.caller.modelRoadNetworkFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version"))
                self.visum_modes = unicode(self.ui.lineEditVisumModes.text())
                
                cmd = ["python", TEMPUSLOADER, "--action", "import", "--data-type", "road", "--data-format", self.format, "--source-name", self.source_name, "--source-comment", self.source_comment, "--path", cheminComplet, "--encoding", self.encoding, '--srid', str(self.srid), "-d", dbstring]
                if (self.prefix != ''):
                    cmd.append("--prefix")
                    cmd.append(self.prefix)
                if (str(self.model_version) != 'NULL'):
                    cmd.append('--model-version')
                    cmd.append(str(self.model_version))
                if (self.visum_modes != ''):
                    cmd.append('--visum-modes')
                    cmd.append(self.visum_modes)
                
                rc = execute_external_cmd( cmd )
                box = QMessageBox()
                box.setModal(True)
                if (rc==0):
                    box.setText(u"L'import de la source est terminé.")
                    
                    self.caller.refreshRoadNetworks()
                    if (self.caller.modelPTNetwork.rowCount()>0):
                        self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type ORDER BY code", self.caller.db)
                    else:
                        self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type WHERE needs_pt = False ORDER BY code", self.caller.db)

                    self.caller.manage_db_dialog._slotPushButtonLoadClicked()
                else:
                    box.setText(u"Erreur pendant l'import.\n Pour en savoir plus, ouvrir la console Python de QGIS et relancer la commande.")
                box.exec_()
        
        
    def _slotClose(self):
        self.hide()            
            