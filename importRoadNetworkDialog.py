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

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_importRoadNetworkDialog import Ui_Dialog

class importRoadNetworkDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        self.debug = caller.debug
        
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
        self.format = self.caller.modelRoadFormat.record(indexChosenLine).value("format_short_name")
        self.caller.modelRoadFormatVersion.setQuery("SELECT model_version, default_encoding, default_srid, path_type FROM tempus_access.formats WHERE format_id = "+str(self.caller.modelRoadFormat.record(indexChosenLine).value("format_id"))+" ORDER BY model_version DESC", self.caller.db)
        
    
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
                self.ui.lineEditVisumModes.setText('')
                self.ui.lineEditVisumModes.setEnabled(False)
                self.ui.labelVisumModes1.setEnabled(False)
                self.ui.labelVisumModes2.setEnabled(False)
    
    
    def _slotPushButtonChooseClicked(self):
        cheminComplet = ''
        if (self.path_type=="directory"):
            cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir)
        else:
            cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.data_dir, filter = "(*"+self.path_type+")")
        dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
        self.srid = self.ui.spinBoxSRID.value()
        self.prefix = self.ui.lineEditPrefix.text()
        self.encoding = self.caller.modelRoadEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
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
        
        cmd=["python", self.caller.load_tempus_path, '-t', self.format, '--road-network', self.source_name, '-s', cheminComplet, '-d', dbstring, '-W', self.encoding, '-S', str(self.srid)]
        print cmd
        r = subprocess.call( cmd )
        
        from_proj = QgsCoordinateReferenceSystem()
        from_proj.createFromSrid(4326)
        to_proj = QgsCoordinateReferenceSystem()
        to_proj.createFromSrid(self.caller.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
        crd=QgsCoordinateTransform(from_proj, to_proj)
        
        self.caller.iface.mapCanvas().refreshMap() 
        
        # Zoom the map on one of the three road subnetworks (individual walking, cycling or driving)
        # for lyr in QgsMapLayerRegistry.instance().mapLayers().values():
            # if (lyr.name() == u"Réseau voiture"):
                # self.caller.iface.mapCanvas().setExtent(crd.transform(lyr.extent()))
                # break
        
           
        
            
            
            