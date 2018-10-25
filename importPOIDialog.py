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
from Ui_importPOIDialog import Ui_Dialog

class importPOIDialog(QDialog): 

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
        self.format_compl = ''
    
    
    def _connectSlots(self):
        self.ui.comboBoxFormat.currentIndexChanged.connect(self._slotComboBoxFormatCurrentIndexChanged)
        self.ui.pushButtonChooseDir.clicked.connect(self._slotPushButtonChooseDirClicked)
        self.ui.comboBoxFormatVersion.currentIndexChanged.connect(self._slotComboBoxFormatVersionCurrentIndexChanged)
        
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelPOIFormat.record(self.ui.comboBoxFormat.currentIndex()).value("format_short_name")
        self.caller.modelPOIFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE format_short_name = '"+self.format+"' ORDER BY model_version DESC", self.caller.db)

    
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        self.model = self.caller.modelPOIFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version")
        self.ui.spinBoxSRID.setValue(int(self.caller.modelPOIFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("default_srid")))
        print self.caller.modelPOIFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("default_srid")
        self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelPOIFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("default_encoding")))
        
    
    def _slotPushButtonChooseDirClicked(self):
        pass
            
            
            