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
from Ui_import_areas_dialog import Ui_Dialog

class import_areas_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui = Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        self.plugin_dir = self.caller.plugin_dir        
        
        self.ui.comboBoxFormat.setModel(self.caller.modelAreaFormat)
        self.ui.comboBoxFormatVersion.setModel(self.caller.modelAreaFormatVersion)
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
        
		
    def _slotLineEditSourceNameTextChanged(self):
        if (self.ui.lineEditSourceName.text()!=""):
            self.ui.pushButtonChoose.setEnabled(True)
        else:
            self.ui.pushButtonChoose.setEnabled(False)
    
    
    def _slotComboBoxFormatCurrentIndexChanged(self):
        self.format = self.caller.modelAreaFormat.record(self.ui.comboBoxFormat.currentIndex()).value("data_format")
        self.caller.modelAreaFormatVersion.setQuery("SELECT model_version, default_srid, default_encoding, path_type FROM tempus_access.formats WHERE data_type = 'area' AND data_format = '"+str(self.format)+"' ORDER BY model_version DESC", self.caller.db)

        
    def _slotComboBoxFormatVersionCurrentIndexChanged(self):
        if (indexChosenLine>=0):
            self.ui.spinBoxSRID.setValue(self.caller.modelAreaFormatVersion.record(indexChosenLine).value("default_srid"))
            self.ui.comboBoxEncoding.setCurrentIndex(self.ui.comboBoxEncoding.findText(self.caller.modelAreaFormatVersion.record(indexChosenLine).value("default_encoding")))
            self.path_type = self.caller.modelAreaormatVersion.record(indexChosenLine).value("path_type")
    
    
    
    def _slotPushButtonChooseClicked(self):
        cheminComplet = ''
        if (self.path_type=="directory"):
            cheminComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir, caption="Choisir un dossier contenant la source à charger")
        else:
            cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier "+self.path_type, directory=self.caller.data_dir, filter = "(*"+self.path_type+")")
        dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
        self.srid = self.ui.spinBoxSRID.value()
        self.encoding = self.caller.modelEncoding.record(self.ui.comboBoxEncoding.currentIndex()).value("mod_lib")
        self.prefix = self.ui.lineEditPrefix.text()
        self.source_name = self.ui.lineEditSourceName.text()
        self.model_version = self.caller.modelAreaFormatVersion.record(self.ui.comboBoxFormatVersion.currentIndex()).value("model_version")
        self.filter = self.ui.lineEditFilter.text()
        
        cmd=["python", TEMPUSLOADER, "--action", "import", "--data-type", "area", "--data-format", self.format, "--source-name", self.source_name, "--path", cheminComplet, "--encoding", self.encoding, '--srid', str(self.srid), '--prefix', self.prefix, '--filter', self.filter, '--dbstring', dbstring]
        self.ui.lineEditCommand.setText(" ".join(cmd))
        r = subprocess.call( cmd )
        
        self.caller.iface.mapCanvas().refreshMap()
        
        box = QMessageBox()
        if r==0:
            box.setText(u"L'import de la source est terminé. " )
        else:
            box.setText(u"Erreur pendant l'import. ")
        box.exec_()
        