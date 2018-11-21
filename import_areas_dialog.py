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
        
        self.debug = caller.debug
        
        self.plugin_dir = self.caller.plugin_dir
        
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
        pass
    
    
    
    def _slotPushButtonChooseClicked(self):
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
            
            t="ALTER TABLE tempus_access.area_type"+str(areaID)+" RENAME COLUMN "+self.ui.lineEditAreasID.text()+" TO lib; \
            ALTER TABLE tempus_access.area_type"+str(areaID)+" RENAME COLUMN "+self.ui.lineEditAreasLib.text()+" TO char_id; \
            CREATE INDEX IF NOT EXISTS area_type"+str(areaID)+"_lib_idx ON tempus_access.area_type"+str(areaID)+" USING gist (lib gist_trgm_ops); \
            CREATE INDEX IF NOT EXISTS area_type"+str(areaID)+"_char_id_idx ON tempus_access.area_type"+str(areaID)+" USING btree (char_id);\
            INSERT INTO tempus_access.areas_param(code, lib, file_name, id_field, name_field, from_srid)\
            VALUES ((SELECT max(code)+1 FROM tempus_access.areas_param), '"+self.ui.lineEditAreasName.text()+"', '"+QFileInfo(NomFichierComplet).fileName()+"','"+\
                       self.ui.lineEditAreasID.text()+"', '"+self.ui.lineEditAreasLib.text()+"', "+self.ui.lineEditSRID.text()+");  \
            ALTER TABLE tempus_access.area_type"+str(areaID)+" DROP COLUMN ogc_fid"
            q=QtSql.QSqlQuery(self.caller.db)
            q.exec_(unicode(t)) 

            s="SELECT lib, code, file_name, id_field, name_field, from_srid FROM tempus_access.areas_param WHERE code = "+str(areaID)+"\
            ORDER BY 2"
            q=QtSql.QSqlQuery(self.caller.db)
            q.exec_(unicode(s))
            
            self.caller.modelAreaType.setQuery(unicode(s), self.caller.db)

            uri=QgsDataSourceURI()
            uri.setConnection(self.caller.host, self.caller.port, self.caller.base, self.caller.login, self.caller.pwd)
            
            for i in range(0,self.caller.modelAreaType.rowCount()):
                if (self.caller.modelAreaType.record(i).value("code")==areaID):
                    uri.setDataSource("tempus_access", "area_type"+str(areaID), "geom", "")
                    layer = QgsVectorLayer(uri.uri(), self.caller.modelAreaType.record(i).value("lib"), "postgres")
                    if (layer.isValid()):
                        QgsMapLayerRegistry.instance().addMapLayer(layer, False)
                        node_layer = QgsLayerTreeLayer(layer)
                        self.caller.node_admin.insertChildNode(i, node_layer)
                        self.caller.iface.legendInterface().setLayerVisible(layer, False)
            
            
            
            box = QMessageBox()
            box.setText(u"L'import du fichier de zonage est terminé. " )
            box.exec_()
                
            