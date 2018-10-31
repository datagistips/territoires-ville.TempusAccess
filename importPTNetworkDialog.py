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
from Ui_importPTNetworkDialog import Ui_Dialog

class importPTNetworkDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        # Connect signals and slots
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.comboBoxFormat.currentIndexChanged.connect(self._slotComboBoxFormatCurrentIndexChanged)
        self.ui.pushButtonChoose1.clicked.connect(self._slotPushButtonChoose1Clicked)
        self.ui.pushButtonChoose2.clicked.connect(self._slotPushButtonChoose2Clicked)
        self.ui.pushButtonChoose3.clicked.connect(self._slotPushButtonChoose3Clicked)
        self.ui.pushButtonImport.clicked.connect(self._slotPushButtonImportClicked)
        self.ui.lineEditSourceName.textChanged.connect(self._slotLineEditSourceNameTextChanged)
    
    
    def _slotLineEditSourceNameTextChanged(self):
        if (self.ui.lineEditSourceName.text()==""): 
            self.ui.pushButtonImport.setEnabled(False)
        else: 
            self.ui.pushButtonImport.setEnabled(True)


    def _slotPushButtonImportClicked(self):
        pass
            
        
    def _slotPushButtonChoose1Clicked(self):
        pass
    
    
    def _slotPushButtonChoose2Clicked(self):
        pass
    
    
    def _slotPushButtonChoose3Clicked(self):
        pass
    
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        pass
        
    