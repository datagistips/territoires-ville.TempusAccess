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
from Ui_import_pt_dialog import Ui_Dialog

class import_pt_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        self.iface = self.caller.iface
        self.temp_data_dir = self.caller.data_dir        
        
        self.ui.comboBoxFormat.setModel(self.caller.modelPTNetworkFormat)
        self.ui.comboBoxFormatVersion.setModel(self.caller.modelPTNetworkFormatVersion)
        self.ui.comboBoxEncoding.setModel(self.caller.modelEncoding)
        
        # Connect signals and slots
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.comboBoxFormat.currentIndexChanged.connect(self._slotComboBoxFormatCurrentIndexChanged)
        self.ui.pushButtonChoose1.clicked.connect(self._slotPushButtonChoose1Clicked)
        self.ui.pushButtonChoose2.clicked.connect(self._slotPushButtonChoose2Clicked)
        self.ui.pushButtonChoose3.clicked.connect(self._slotPushButtonChoose3Clicked)
        self.ui.pushButtonImport.clicked.connect(self._slotPushButtonImportClicked)
        self.ui.lineEditSourceName.textChanged.connect(self._slotLineEditSourceNameTextChanged)
    
    
    def updatePushButtonImport(self):
        if (self.ui.labelFile1.text() != ''):
            self.ui.pushButtonImport.setEnabled(True)
        else:
            self.ui.pushButtonImport.setEnabled(False)
    
    
    def _slotLineEditSourceNameTextChanged(self):
        self.updatePushButtonImport()
    
    
    def _slotComboBoxFormatCurrentIndexChanged(self, indexChosenLine):
        self.format = self.caller.modelPTNetworkFormat.record(indexChosenLine).value("data_format")
        self.caller.modelPTNetworkFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding FROM tempus_access.formats WHERE data_type = 'pt' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)
        self._slotComboBoxFormatVersionCurrentIndexChanged(self.ui.comboBoxFormatVersion.currentIndex())
        
        
    def _slotComboBoxFormatVersionCurrentIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelPTNetworkFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.ui.spinBoxSRID.setValue(self.caller.modelPTNetworkFormatVersion.record(indexChosenLine).value("default_srid"))
            if (self.format == 'gtfs'):
                self.ui.pushButtonChoose2.setEnabled(False)
                self.ui.pushButtonChoose3.setEnabled(False)
                self.ui.labelChoose2.setEnabled(False)
                self.ui.labelChoose3.setEnabled(False)
                self.ui.labelChoose1.setText(u'Choisir le fichier .zip')
                self.ui.labelChoose2.setText('')
                self.ui.labelChoose3.setText('')
                self.ui.lineEditPrefix.setEnabled(False)
                self.ui.labelSRID.setEnabled(False)
                self.ui.spinBoxSRID.setEnabled(False)
                self.ui.labelEncoding.setEnabled(False)
                self.ui.comboBoxEncoding.setEnabled(False)
            elif (self.format == 'sncf'):
                self.ui.pushButtonChoose2.setEnabled(True)
                self.ui.pushButtonChoose3.setEnabled(True)
                self.ui.labelChoose2.setEnabled(True)
                self.ui.labelChoose3.setEnabled(True)
                self.ui.labelChoose1.setText(u'Choisir le GTFS TER (.zip)')
                self.ui.labelChoose2.setText(u'Choisir le GTFS Intercités (.zip)')
                self.ui.labelChoose3.setText(u'Choisir le répertoire contenant les données auxiliaires')
                self.ui.lineEditPrefix.setEnabled(True)
                self.ui.labelSRID.setEnabled(True)
                self.ui.spinBoxSRID.setEnabled(True)
                self.ui.labelEncoding.setEnabled(True)
                self.ui.comboBoxEncoding.setEnabled(True)
            self.ui.labelFile1.setText('')
            self.ui.labelFile2.setText('')
            self.ui.labelFile3.setText('')
            self.ui.pushButtonImport.setEnabled(False)
        
        
    def _slotPushButtonChoose1Clicked(self):
        self.cheminComplet1 = QFileDialog.getOpenFileName(caption = "Choisir un fichier .zip", directory=self.caller.last_dir, filter = "(*.zip)")
        self.caller.last_dir = os.path.dirname(self.cheminComplet1)
        self.ui.labelFile1.setText(os.path.basename(self.cheminComplet1))
        self.updatePushButtonImport()

        
    def _slotPushButtonChoose2Clicked(self):
        self.cheminComplet2 = QFileDialog.getOpenFileName(caption = "Choisir un fichier .zip", directory=self.caller.last_dir, filter = "(*.zip)")
        self.caller.last_dir = os.path.dirname(self.cheminComplet2)
        self.ui.labelFile2.setText(os.path.basename(self.cheminComplet2))
        self.updatePushButtonImport()
        
        
    def _slotPushButtonChoose3Clicked(self):
        self.cheminComplet3 = QFileDialog.getExistingDirectory(caption = "Choisir le répertoire Route500", options=QFileDialog.ShowDirsOnly, directory=self.caller.last_dir) 
        self.caller.last_dir = os.path.dirname(self.cheminComplet3)
        self.ui.labelFile3.setText(os.path.basename(self.cheminComplet3))
        self.temp_data_dir = self.cheminComplet3
        self.updatePushButtonImport()
        

    def _slotPushButtonImportClicked(self):        
        if (self.ui.lineEditSourceName.text() == '') or (self.format == "sncf" and (self.ui.labelFile1.text() == '' or self.ui.labelFile2.text() == '' or self.ui.labelFile3.text()=='')) or (self.format == "gtfs" and self.ui.labelFile1.text()==""):
            box = QMessageBox()
            box.setText(u"Certains paramètres obligatoires ne sont pas renseignés.")
            box.exec_()
        else:
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.srid = self.ui.spinBoxSRID.value()
            self.prefix = unicode(self.ui.lineEditPrefix.text())
            self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
            self.source_name = unicode(self.ui.lineEditSourceName.text())
            self.model_version = str(self.caller.modelPTNetworkFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version"))
            
            if (self.format == "gtfs"):
                cmd=["python", TEMPUSLOADER, "--action", "import", "--data-type", "pt", "--data-format", self.format, "--source-name", self.source_name, "--path", self.cheminComplet1, "--encoding", self.encoding, '--srid', str(self.srid), "--dbstring", dbstring]
            elif (self.format == "sncf"):
                cmd=["python", TEMPUSLOADER, "--action", "import", "--data-type", "pt", "--data-format", self.format, "--source-name", self.source_name, "--path", self.cheminComplet1, self.cheminComplet2, self.cheminComplet3, '--srid', str(self.srid), "--dbstring", dbstring]

            if (self.prefix != ""):
                cmd.append("--prefix")
                cmd.append(self.prefix)
            if (self.model_version != 'NULL'):
                cmd.append('--model-version')
                cmd.append(self.model_version)
                        
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            if (rc==0):
                box.setText(u"L'import de la source est terminé.")
                
                self.caller.refreshPTNetworks()
                self.caller.modelObjType.setQuery("SELECT lib, code, indic_list, def_name FROM tempus_access.obj_type ORDER BY code", self.caller.db)
                
                self.caller.manage_db_dialog._slotPushButtonLoadClicked()
            else:
                box.setText(u"Erreur pendant l'import.\n Pour en savoir plus, ouvrir la console Python de QGIS et relancer la commande.")
            box.exec_()
    
    
        
        