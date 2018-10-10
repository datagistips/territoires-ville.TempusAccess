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
from Ui_importAreasDialog import Ui_Dialog

class importAreasDialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        
        self.caller = caller
        
        # Connect signals and slots
        self._connectSlots()
        
        
    def _connectSlots(self):
        self.ui.lineEditSRID.textChanged.connect(self._slotLineEditTextChanged)
        self.ui.lineEditAreasName.textChanged.connect(self._slotLineEditTextChanged)
        self.ui.lineEditAreasID.textChanged.connect(self._slotLineEditTextChanged)
        self.ui.lineEditAreasLib.textChanged.connect(self._slotLineEditTextChanged)
        self.ui.pushButtonImportAreas.clicked.connect(self._slotBoutonImportAreasClicked)
        
		
    def _slotLineEditTextChanged(self):
        if ((self.ui.lineEditSRID.text()=="") or (self.ui.lineEditAreasName.text()=="") or (self.ui.lineEditAreasID.text()=="") or (self.ui.lineEditAreasLib.text()=="")): 
			self.ui.pushButtonImportAreas.setEnabled(False)
        else: 
            self.ui.pushButtonImportAreas.setEnabled(True)
        
        
    def _slotBoutonImportAreasClicked(self):
        # Open a window to choose path to the GTFS source file 
        NomFichierComplet = QFileDialog.getOpenFileName(caption = "Choisir un fichier shape", directory=self.caller.data_dir, filter = "Shape files (*.shp)")
        
        if NomFichierComplet:
            s="SELECT max(code)+1 FROM tempus_access.areas_param"
            q=QtSql.QSqlQuery(self.caller.db)
            q.exec_(unicode(s))
            q.next()
            areaID = q.value(0)
            # import the chosen GTFS source in the current schema, with "Tempus" library
            cmd=["ogr2ogr", "-f", "PostgreSQL", "PG:dbname="+self.caller.base+" host="+self.caller.host+" port="+self.caller.port, NomFichierComplet,  "-overwrite", "-lco", "GEOMETRY_NAME=geom", "-s_srs", "EPSG:"+self.ui.lineEditSRID.text(), "-t_srs", "EPSG:4326", "-nln", "tempus_access.area_type"+str(areaID), "-nlt", "PROMOTE_TO_MULTI"]
            r = subprocess.call( cmd ) 
            
            if (self.ui.lineEditAreasID.text()!="char_id"):
                s="ALTER TABLE tempus_access.area_type"+str(areaID)+" RENAME COLUMN "+self.ui.lineEditAreasID.text()+" TO char_id;"
                q=QtSql.QSqlQuery(self.caller.db)
                q.exec_(unicode(s))
            if (self.ui.lineEditAreasLib.text()!="lib"):
                s="ALTER TABLE tempus_access.area_type"+str(areaID)+" RENAME COLUMN "+self.ui.lineEditAreasLib.text()+" TO lib;"
                q=QtSql.QSqlQuery(self.caller.db)
                q.exec_(unicode(s))
            s="INSERT INTO tempus_access.areas_param(code, lib, file_name, id_field, name_field, from_srid)\
               VALUES ((SELECT max(code)+1 FROM tempus_access.areas_param), '"+self.ui.lineEditAreasName.text()+"', '"+QFileInfo(NomFichierComplet).fileName()+"','"+\
                       self.ui.lineEditAreasID.text()+"', '"+self.ui.lineEditAreasLib.text()+"', "+self.ui.lineEditSRID.text()+");\
               ALTER TABLE tempus_access.area_type"+str(areaID)+" DROP COLUMN ogc_fid"
            q=QtSql.QSqlQuery(self.caller.db)
            q.exec_(unicode(s))            
            
            box = QMessageBox()
            box.setText(u"L'import du fichier de zonage est terminé. " )
            box.exec_()
                
            