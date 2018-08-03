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
from Ui_importGTFSDialog import Ui_Dialog

class importGTFSDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        # Connect signals and slots
        self._connectSlots()
        
        
    def _connectSlots(self):
        self.ui.lineEditPrefixeGTFS.textChanged.connect(self._slotLineEditPrefixeGTFSTextChanged)
        self.ui.pushButtonImportGTFSFeed.clicked.connect(self._slotBoutonImportGTFSFeedClicked)
        
    def _slotLineEditPrefixeGTFSTextChanged(self):
        if (self.ui.lineEditPrefixeGTFS.text()==""): 
            self.ui.pushButtonImportGTFSFeed.setEnabled(False)
        else: 
            self.ui.pushButtonImportGTFSFeed.setEnabled(True)
        
        
    def _slotBoutonImportGTFSFeedClicked(self):
        # Open a window to choose path to the GTFS source file 
        NomFichierComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier au format GTFS", directory=self.caller.data_dir, filter = "Zip files (*.zip)")
        
        if NomFichierComplet:
            # import the chosen GTFS source in the current schema, with "Tempus" library
            fid = self.ui.lineEditPrefixeGTFS.text().replace("-", "_")
            dbstring = "host="+self.caller.host+" dbname="+self.caller.base+" port="+self.caller.port
            
            # Test if there is already a road network (not only artificial road sections)
            
            cmd = ["python", "C:\\OSGeo4W64\\apps\\Python27\\lib\\site-packages\\tempusloader-1.2.2-py2.7.egg\\tempusloader\\load_tempus.py", '-t', 'gtfs', '-s', NomFichierComplet, '-S', '4326', '-d', dbstring, '--pt-network', fid]
            with open(self.caller.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(str(cmd))
                log_file.write("\n    Insert GTFS Data\n\n")
                r = subprocess.call( cmd, stdout= log_file )
            
            road_network = False
            s="SELECT * FROM tempus.road_section WHERE id NOT IN (SELECT road_section_id from tempus_gtfs.stops)"
            q=QtSql.QSqlQuery(self.caller.db)
            q.exec_(unicode(s))
            
            if q.size()>0:
                road_network = True
            if road_network==False:
                cmd = ["psql", "-h", self.caller.host, "-p", self.caller.port, "-d", self.caller.base, "-f", self.caller.plugin_dir + "/sql/gtfs_post_insert_no_road_network.sql"] 
                r = subprocess.call( cmd )
            
            self.caller.refreshPTData()
            self.caller.refreshGTFSFeeds()
            
            box = QMessageBox()
            box.setText(u"L'import du fichier GTFS est terminé. " )
            box.exec_()
            
            
            