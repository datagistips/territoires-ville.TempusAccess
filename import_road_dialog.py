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

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_import_road_dialog import Ui_Dialog

class import_road_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        self.plugin_dir = self.caller.plugin_dir
        
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
        
    def _slotLineEditSourceNameTextChanged(self, text):
        if (self.ui.lineEditSourceName.text()!=""):
            self.ui.pushButtonChoose.setEnabled(True)
        else:
            self.ui.pushButtonChoose.setEnabled(False)
        
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelRoadFormat.record(self.ui.comboBoxFormat.currentIndex()).value("data_format")
        self.caller.modelRoadFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE data_type = 'road' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)

    
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelRoadFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.ui.spinBoxSRID.setValue(self.caller.modelRoadFormatVersion.record(indexChosenLine).value("default_srid"))
            self.path_type = self.caller.modelRoadFormatVersion.record(indexChosenLine).value("path_type")
            if (self.format == "road_visum"):
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
        cheminComplet = ''
        if (self.path_type=="directory"):
            cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir)
        else:
            cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.data_dir, filter = "(*"+self.path_type+")")
        dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
        self.srid = self.ui.spinBoxSRID.value()
        self.prefix = self.ui.lineEditPrefix.text()
        self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
        self.source_name = self.ui.lineEditSourceName.text()
        self.model_version = self.caller.modelRoadFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version")
        self.visum_modes = self.ui.lineEditVisumModes.text()
        prefix_string=''
        if (self.prefix != ""):
            prefix_string = "-p "+self.prefix 
        
        version_string=''
        if (str(self.model_version) != 'NULL'):
            version_string = '-m ' + str(self.model_version)
            
        visum_modes_string=''
        if (self.visum_modes != ''):
            visum_modes_string = '--visum-modes '+self.visum_modes
        
        cmd = ["python", TEMPUSLOADER, "--action", "import", "--data-type", "road", "--data-format", self.format, "--source-name", self.source_name, "--path", cheminComplet, "--encoding", self.encoding, '-S', str(self.srid), "-d", dbstring]
        r = subprocess.call( cmd )
        
        
        self.caller.iface.mapCanvas().refreshMap()
        
        box = QMessageBox()
        box.setText(u"L'import du réseau est terminé. " )
        box.exec_()
            
            
            