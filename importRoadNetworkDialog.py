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
        self.format_compl = ''
        
        
    def _connectSlots(self):
        self.ui.comboBoxRoadFormat.currentIndexChanged.connect(self._slotComboBoxRoadFormatCurrentIndexChanged)
        self.ui.pushButtonImportRoadNetwork.clicked.connect(self._slotPushButtonRoadNetworkClicked)
        
    
    def _slotComboBoxRoadFormatCurrentIndexChanged(self):
        if (self.ui.comboBoxRoadFormat.currentText()=="Visum"):
            self.format = 'visum'
        elif (self.ui.comboBoxRoadFormat.currentText()=="Route500"):
            self.format = 'route500'
        elif (self.ui.comboBoxRoadFormat.currentText()=="OSM"):
            self.format = 'osm'
        elif (self.ui.comboBoxRoadFormat.currentText()=="Navteq - Navstreets"):
            self.format = 'navteq'
        elif (self.ui.comboBoxRoadFormat.currentText()=="TomTom"):
            self.format = 'tomtom'
        
    
    def _slotPushButtonRoadNetworkClicked(self):
        nomDossierComplet = QFileDialog.getExistingDirectory(options=QFileDialog.ShowDirsOnly, directory=self.caller.data_dir)
        dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
        srid = self.ui.lineEditSRID.text()
        
        if (self.format=='visum'):
            cmd2=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-c", "\copy tempus_access.road_network_turning_mov FROM '"+nomDossierComplet+"\\road_network_turning_mov.csv' CSV HEADER DELIMITER ';'"]
            cmd3=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.plugin_dir + "/sql/visum_import_turning_penalty.sql"]
            cmd1=["python", "C:\\OSGeo4W64\\apps\\Python27\\lib\\site-packages\\tempusloader-1.2.2-py2.7.egg\\tempusloader\\load_tempus.py", '-t', self.format, '-s', nomDossierComplet, '-d', dbstring, '-p', 'road_network_', '--visum-modes', 'P,B,V,T', '-W', 'LATIN1']
            cmd4=["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.plugin_dir + "/sql/update_road_network.sql"]

            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(str(cmd1))
                r = subprocess.call( cmd1, stdout = log_file )
                log_file.write("\n    Import road network in the "+self.format+" format...\n\n")
                log_file.write(str(cmd2))
                r = subprocess.call( cmd2, stdout = log_file )
                log_file.write(str(cmd3))
                r = subprocess.call( cmd3, stdout = log_file )
                log_file.write("\n    Import Visum turning movements file...\n\n")
                log_file.write(str(cmd4))
                r = subprocess.call( cmd4, stdout = log_file )               
                log_file.write("\n    Update road network...\n\n")

        else:
            cmd = ["python", "C:\\OSGeo4W64\\apps\\Python27\\lib\\site-packages\\tempusloader-1.2.2-py2.7.egg\\tempusloader\\load_tempus.py", '-t', self.format, '-s', nomDossierComplet, '-d', dbstring, '-S', srid, '-W', 'LATIN1']
            with open(self.plugin_dir+"/log.txt", "a") as log_file: 
                log_file.write(str(cmd))
                r = subprocess.call( cmd, stdout=log_file )
                log_file.write("\n    Import road network in the "+self.format+" format...\n\n")
            
            
            