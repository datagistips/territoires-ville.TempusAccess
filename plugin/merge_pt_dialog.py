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
from Ui_merge_pt_dialog import Ui_Dialog

class merge_pt_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        self.caller = caller
        self.db = caller.db
        self.iface = caller.iface
                
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.pushButtonMerge.clicked.connect(self._slotPushButtonMergeClicked)
        self.ui.pushButtonChooseTransfersFile.clicked.connect(self._slotPushButtonChooseTransfersFileClicked)
        self.ui.lineEditMergedPTNetwork.textChanged.connect(self._slotLineEditMergedPTNetworkTextChanged)
    
    
    def _slotPushButtonChooseTransfersFileClicked(self):
        self.data_dir = None
        cheminComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier de correspondance : stops_transfers.txt", directory=self.caller.last_dir, filter = "(stops_transfers.txt)")
        self.caller.last_dir = os.path.dirname(cheminComplet)
        self.data_dir = self.caller.last_dir
        self.ui.labelTransfersFile.setText(os.path.basename(cheminComplet))
    
    
    def _slotLineEditMergedPTNetworkTextChanged(self):
        if (self.ui.lineEditMergedPTNetwork.text() != ''):
            self.ui.pushButtonMerge.setEnabled(True)
        else:
            self.ui.pushButtonMerge.setEnabled(False)
        
    
    def _slotPushButtonMergeClicked(self):
        self.PTNetworks = []
        for item in self.ui.listViewPTNetworks.selectionModel().selectedRows():
            self.PTNetworks.append(self.caller.modelPTNetwork.record(item.row()).value("id"))

        if (self.ui.lineEditMergedPTNetwork.text()!="") and (len(self.PTNetworks)>1):
            dbstring = "host="+self.caller.db.hostName()+" user="+self.caller.db.userName()+" dbname="+self.caller.db.databaseName()+" port="+str(self.caller.db.port())
            self.source_name = self.ui.lineEditMergedPTNetwork.text()
            path_option=''
            path_value = ''
            if (self.data_dir != None):
                path_option = '--path'
                path_value = self.data_dir
            str_options = str(self.ui.checkBoxStops.isChecked())+","+str(self.ui.checkBoxAgencies.isChecked())+","+str(self.ui.checkBoxServices.isChecked())+","+str(self.ui.checkBoxRoutes.isChecked())+","+str(self.ui.checkBoxTrips.isChecked())+","+str(self.ui.checkBoxFares.isChecked())+","+str(self.ui.checkBoxShapes.isChecked())
            cmd=["python", TEMPUSLOADER, "--action", "merge", "--data-type", "pt", "--source-name", self.source_name, path_option, path_value, "--dbstring", dbstring, "--source-list", str(self.PTNetworks)[1:len(str(self.PTNetworks))-1], "--pt-merge-options", str_options]
            
            rc = execute_external_cmd( cmd )
            box = QMessageBox()
            if (rc==0):
                box.setText(u"La fusion des sources est terminée.")
                
                self.caller.refreshPTNetworks()                
                self.caller.manage_db_dialog._slotPushButtonLoadClicked()
            else:
                box.setText(u"Erreur pendant la fusion.\n Pour en savoir plus, relancer en ligne de commande la commande figurant dans la console Python.")
            box.exec_()

        else:
            box = QMessageBox()
            box.setText(u"Au moins deux réseaux doivent être sélectionnés et un alias doit être défini pour le réseau fusionné. ")
            box.exec_()
        
        