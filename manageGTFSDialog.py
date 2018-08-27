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
from Ui_manageGTFSDialog import Ui_Dialog

class manageGTFSDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        self.caller = caller
        self.db = caller.db
        self.iface = caller.iface
                
        self.ui.comboBoxGTFSFeeds.setModel(self.caller.modelGTFSFeeds)
        
        self._connectSlots()
    
    
    def _connectSlots(self):
        self.ui.pushButtonDeleteGTFSFeed.clicked.connect(self._slotPushButtonDeleteGTFSFeedClicked)
        self.ui.pushButtonExportGTFSFeed.clicked.connect(self._slotExportGTFSFeedClicked)
    
    
    def _slotPushButtonDeleteGTFSFeedClicked(self):
        ret = QMessageBox.question(self, "TempusAccess", u"La source de données GTFS sélectionnée va être supprimée. \n Confirmez-vous vouloir faire cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)

        if (ret == QMessageBox.Ok): 
            s="UPDATE tempus_gtfs.stops\
                SET artificial_road_section=false;\
                DELETE FROM tempus_gtfs.transfers\
                WHERE feed_id = '"+self.ui.comboBoxGTFSFeeds.currentText()+"';"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
            
            dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
            cmd = ["python", "C:\\OSGeo4W64\\apps\\Python27\\lib\\site-packages\\tempusloader-1.2.2-py2.7.egg\\tempusloader\\load_tempus.py", '-d', dbstring, '--pt-delete', '--pt-network', self.ui.comboBoxGTFSFeeds.currentText()]
            r = subprocess.call( cmd, shell=True )
            
            s="REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode;\
               REFRESH MATERIALIZED VIEW tempus_access.sections_by_mode;\
               REFRESH MATERIALIZED VIEW tempus_access.trips_by_mode;"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
            
            # Refresh list of GTFS data sources
            self.caller.refreshPTData()
            self.caller.refreshGTFSFeeds()
    
    def _slotExportGTFSFeedClicked(self):
        # Open a window to choose path to the GTFS source file 
        NomFichierComplet = QFileDialog.getSaveFileName(caption = "Choisir un nom de fichier", directory=self.caller.data_dir, filter = "Zip files (*.zip)")
        
        self.caller.exportGTFS(NomFichierComplet, "tempus_gtfs", self.ui.comboBoxGTFSFeeds.currentText())

        
        