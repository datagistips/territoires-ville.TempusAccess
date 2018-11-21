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
from Ui_import_pt_dialog import Ui_Dialog

class import_pt_dialog(QDialog): 

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
        dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
        self.format = self.caller.modelPTFormat.record(self.ui.comboBoxFormat.currentIndex()).value("format_short_name")
        self.source_name = self.ui.lineEditSourceName.text()
        
        if (self.format == "pt_gtfs"):
            cmd=["python", self.caller.load_tempus_path, '-t', self.format, '--pt-network', self.source_name, '-s', self.cheminComplet1, '-d', dbstring]
        elif (self.format == "pt_sncf"):
            cmd=["python", self.caller.load_tempus_path, '-t', self.format, '--pt-network', self.source_name, '-s', self.cheminComplet1, self.cheminComplet2, '-d', dbstring]
        r = subprocess.call( cmd )
            
        self.caller.iface.mapCanvas().refreshMap() 
        
        box = QMessageBox()
        box.setText(u"L'import du réseau est terminé. " )
        box.exec_()
        
        
    def _slotPushButtonChoose1Clicked(self):
        self.cheminComplet1 = QFileDialog.getOpenFileName(caption = "Choisir un fichier .zip", directory=self.caller.data_dir, filter = "(*.zip)")
        self.ui.labelFile1.setText(os.path.basename(self.cheminComplet1))
        
        
    def _slotPushButtonChoose2Clicked(self):
        self.cheminComplet2 = QFileDialog.getOpenFileName(caption = "Choisir un fichier .zip", directory=self.caller.data_dir, filter = "(*.zip)")
        self.ui.labelFile2.setText(os.path.basename(self.cheminComplet2))
        
        
    def _slotPushButtonChoose3Clicked(self):
        cheminComplet = QFileDialog.getExistingDirectory(caption = "Choisir le répertoire Route500", options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir)
    
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelRoadFormat.record(indexChosenLine).value("format_short_name")
        if (self.format == 'pt_gtfs'):
            self.ui.pushButtonChoose2.setEnabled(False)
            self.ui.pushButtonChoose3.setEnabled(False)
            self.ui.labelChoose1.setText('Choisir le fichier .zip')
            self.ui.labelChoose2.setText('')
            self.ui.labelChoose3.setText('')
        elif (self.format == 'pt_sncf'):
            self.ui.pushButtonChoose2.setEnabled(True)
            self.ui.pushButtonChoose3.setEnabled(True)
            self.ui.labelChoose1.setText('Choisir le GTFS TER (.zip)')
            self.ui.labelChoose2.setText('Choisir le GTFS Intercités (.zip)')
            self.ui.labelChoose3.setText('Choisir le répertoire contenant le réseau ferré Route500')
            
        
        
    