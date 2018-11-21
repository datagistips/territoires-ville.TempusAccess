# -*- coding: utf-8 -*-
"""
/***************************************************************************
Tempus Access
                                 A QGIS plugin
 Analyse de l'offre de transport en commun
                              -------------------
        begin                : 2016-10-22
        git sha              : $Format:%H$
        copyright            : (C) 2016 by Cerema
        email                : aurelie.bousquet@cerema.fr, patrick.palmier@cerema.fr, helene.ly@cerema.fr
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

# import the PyQt and QGIS librairies
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from PyQt4.Qt import *
from PyQt4 import QtSql
from qgis.core import *
from qgis.gui import *
from qgis.utils import iface
import osgeo.ogr
# Initialize Qt resources from file resources.py
import resources
import config

# import the code for the dialogs
from TempusAccess_dock_widget import TempusAccess_dock_widget
from set_db_connection_dialog import set_db_connection_dialog
from manage_db_dialog import manage_db_dialog
from import_pt_dialog import import_pt_dialog
from export_delete_pt_dialog import export_delete_pt_dialog
from import_road_dialog import import_road_dialog
from export_delete_road_dialog import export_delete_road_dialog
from import_poi_dialog import import_poi_dialog
from export_delete_poi_dialog import export_delete_poi_dialog
from import_areas_dialog import import_areas_dialog
from export_delete_areas_dialog import export_delete_areas_dialog

import subprocess
import datetime
import os
import sys
import string
import csv

# Thread for general indicators building (no path calculation)
class genIndicThread(QThread):
    resultAvailable = pyqtSignal(bool, str)

    def __init__(self, query_str, db, debug, parent = None):
        super(genIndicThread, self).__init__(parent)
        
        self.query_str = query_str
        self.db = db
        self.plugin_dir = os.path.dirname(__file__)
        self.debug = debug
    
    
    def __del__(self):
        self.wait()


    def run(self): 
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(unicode(self.query_str.replace("  ", ""))+"\n")
        r=QtSql.QSqlQuery(self.db)
        done=r.exec_(self.query_str)
        self.resultAvailable.emit(done, self.query_str)
        
        
# Thread for paths and paths trees building
class pathIndicThread(QThread):
    resultAvailable = pyqtSignal(bool, str)
    
    def __init__(self, query_str, db, dbstring, road_node_from, road_node_to, road_nodes, time_start, time_end, time_ag, time_point, time_interval, all_services, days, tran_modes, path_tree, max_cost, walking_speed, cycling_speed, constraint_date_after, debug, parent = None):
        super(pathIndicThread, self).__init__(parent)
        
        self.query_str = query_str
        self.db = db
        self.dbstring=dbstring
        self.road_node_from = road_node_from
        self.road_node_to = road_node_to
        self.road_nodes = road_nodes
        self.time_start = time_start
        self.time_end = time_end
        self.time_point = time_point
        self.time_ag = time_ag
        self.time_interval = time_interval
        self.all_services = all_services
        self.tran_modes = tran_modes 
        self.days = days
        self.path_tree = path_tree
        self.max_cost = max_cost
        self.walking_speed = walking_speed
        self.cycling_speed = cycling_speed
        self.constraint_date_after = constraint_date_after
        self.debug = debug
        self.plugin_dir = os.path.dirname(__file__)
        
        
    def __del__(self):
        self.wait()
    
    
    def buildGraph(self):
        if (self.path_tree==True):
            s="DELETE FROM tempus_access.tempus_paths_tree_results; SELECT init_isochrone_plugin('"+self.dbstring+"');"
        else:
            s="DELETE FROM tempus_access.tempus_paths_results; SELECT init_multimodal_plugin('"+self.dbstring+"');"
        
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(s+"\n")
        
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
    
    
    def run(self):
        self.buildGraph()
        
        for d in self.days:
            if (self.time_point != "NULL"): # Simple time constraint
                if (self.path_tree==False): 
                    s = "SELECT tempus_access.shortest_path2(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+d + " " +self.time_point[1:len(self.time_point)-1]+"'::timestamp, "+str(self.constraint_date_after)+");"
                    if self.debug:
                        with open(self.plugin_dir+"/log.txt", "a") as log_file:
                            log_file.write("Simple path calculation with a time point constraint\n")
                            log_file.write(s+"\n")
                    q=QtSql.QSqlQuery(self.db)
                    q.exec_(unicode(s))
                elif (self.path_tree==True): 
                    if self.debug:
                        with open(self.plugin_dir+"/log.txt", "a") as log_file:
                            log_file.write("Isochron calculation for all source nodes with a time point constraint\n")

                    for node in self.road_nodes: # For each source node
                        s = "SELECT tempus_access.shortest_paths_tree(("+str(node)+"), ARRAY"+str(self.tran_modes)+", "+str(self.max_cost)+", "+str(self.walking_speed)+", "+str(self.cycling_speed)+", '"+d \
                            + " " +self.time_point[1:len(self.time_point)-1]+"'::timestamp, "+str(self.constraint_date_after)+");"
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write(s+"\n")
                        q=QtSql.QSqlQuery(self.db)
                        q.exec_(unicode(s))
            
            else: # Time period constraint
                if (self.all_services==True): # All possible services of the period - only fo simple paths 
                    if self.debug:
                        with open(self.plugin_dir+"/log.txt", "a") as log_file:
                            log_file.write("Simple path calculation with a time period constraint, all available services are searched\n")
                    current_timestamp=""
                    bound_timestamp=""
                    bound_time=""
                    if (self.constraint_date_after == True):
                        current_timestamp = d + " " +self.time_start[1:len(self.time_start)-1]
                        bound_timestamp = d + " " + self.time_end[1:len(self.time_end)-1]
                        bound_time = self.time_end
                    elif (self.constraint_date_after == False):
                        current_timestamp = d + " " +self.time_end[1:len(self.time_end)-1]
                        bound_timestamp = d + " " + self.time_start[1:len(self.time_start)-1]
                        bound_time = self.time_start
                
                    while (current_timestamp != bound_timestamp):
                        s = "SELECT tempus_access.shortest_path2(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");"
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write(s+"\n")
                        q=QtSql.QSqlQuery(self.db)
                        q.exec_(unicode(s))
                            
                        s1 = "SELECT next_pt_timestamp::character varying FROM tempus_access.next_pt_timestamp("+bound_time+"::time, '"+str(d)+"'::date, "+str(self.constraint_date_after)+")"
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write(s1+"\n")
                        q1=QtSql.QSqlQuery(self.db)
                        q1.exec_(unicode(s1))
                        while q1.next():
                            if (current_timestamp == str(q1.value(0))):
                                current_timestamp = bound_timestamp
                            else:
                                current_timestamp = str(q1.value(0))
                             
                
                elif (self.time_interval!="NULL"): # Search at a regular time interval
                    current_timestamp=""
                    bound_timestamp=""
                    bound_time=""
                    if (self.constraint_date_after == True):
                        current_timestamp = d + " " +self.time_start[1:len(self.time_start)-1]
                        bound_timestamp = d + " " + self.time_end[1:len(self.time_end)-1]
                        bound_time = self.time_end
                    elif (self.constraint_date_after == False):
                        current_timestamp = d + " " +self.time_end[1:len(self.time_end)-1]
                        bound_timestamp = d + " " + self.time_start[1:len(self.time_start)-1]
                        bound_time = self.time_start
                    
                    if (self.path_tree==False): # Simple path calculation
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write("Simple path calculation with time period constraint, a path is searched at a regular time interval\n")
                    elif (self.path_tree==True): 
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write("Isochron calculation for all source/target nodes, a paths tree is searched at a regular time interval\n")
                    
                    while (current_timestamp != bound_timestamp):
                        if (self.path_tree==False): 
                            s = "SELECT tempus_access.shortest_path(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");"
                            if self.debug:
                                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                    log_file.write(s+"\n")
                            q=QtSql.QSqlQuery(self.db)
                            q.exec_(unicode(s))
                            
                        elif (self.path_tree==True):
                            for node in self.road_nodes: # For each source/target node
                                s = "SELECT tempus_access.shortest_paths_tree("+str(node)+", ARRAY"+str(self.tran_modes)+", "+str(self.max_cost)+", "+str(self.walking_speed)+", "+str(self.cycling_speed)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");"
                                if self.debug:
                                    with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                        log_file.write(s+"\n")
                                q=QtSql.QSqlQuery(self.db)
                                q.exec_(unicode(s))
                        
                        s1 = "SELECT next_timestamp::character varying FROM tempus_access.next_timestamp('"+current_timestamp+"'::timestamp, "+str(self.time_interval)+", '"+bound_timestamp+"'::timestamp, "+str(self.constraint_date_after)+")"
                        if self.debug:
                            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                                log_file.write(s1+"\n")
                        q1=QtSql.QSqlQuery(self.db)
                        q1.exec_(unicode(s1))
                        while q1.next():
                            current_timestamp = str(q1.value(0))       
                        
        r=QtSql.QSqlQuery(self.db)
        done=r.exec_(self.query_str)
        
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(self.query_str+"\n")
        self.resultAvailable.emit(done, self.query_str)



class TempusAccess:

    def __init__(self, iface):        
        # Keep reference to QGIS interface
        self.iface = iface
        self.legend=self.iface.legendInterface()
        self.toolButton = QToolButton()
        self.toolButton.setMenu(QMenu())
        self.toolButton.setPopupMode(QToolButton.MenuButtonPopup)
        self.iface.addToolBarWidget(self.toolButton)    
    
    
    def initGui(self):
        # Start database server
        cmd = [ "python", "-m", "pglite", "init" ]
        r = subprocess.call( cmd )
        cmd = [ "python", "-m", "pglite", "start" ]
        r = subprocess.call( cmd )
        
        # Keep reference to paths to the plugin storage directory and to the default directory for data recording and loading
        self.plugin_dir = os.path.dirname(__file__)
        self.data_dir = self.plugin_dir + "/data"
        self.styles_dir = self.plugin_dir + "/styles"
        self.sql_dir = self.plugin_dir + "/sql"
        self.icon_dir = self.plugin_dir + "/icons"
        self.last_dir = self.plugin_dir
        
        self.debug = False # True when the box "Ecrire dans le log" is checked
                
        # Initialize locale (default code)
        locale = QSettings().value('locale/userLocale')[0:2]
        locale_path = os.path.join(self.plugin_dir,'i18n','TempusAccess_{}.qm'.format(locale))
        
        if os.path.exists(locale_path):
            self.translator = QTranslator()
            self.translator.load(locale_path)
        
            if qVersion() > '4.3.3':
                QCoreApplication.installTranslator(self.translator)
        
        # Create main dock widget and keep reference to the main dock widget and to the QGIS legend interface
        self.dlg = TempusAccess_dock_widget()
        self.db = QtSql.QSqlDatabase.addDatabase("QPSQL", connectionName="db")
        
        self.modelEncoding = QtSql.QSqlQueryModel()
        
        ## Database dialogs
        self.modelDB = QtSql.QSqlQueryModel()
        
        # Set connection
        self.set_db_connection_dialog = set_db_connection_dialog(self, self.iface)
        
        # Import and create
        self.manage_db_dialog=manage_db_dialog(self, self.iface)
        
        ## PT networks dialogs
        self.modelPTSources = QtSql.QSqlQueryModel()
        self.modelPTFormat = QtSql.QSqlQueryModel()
        self.modelPTFormatVersion = QtSql.QSqlQueryModel()
        self.PTSources = []
        
        # Import
        self.import_pt_dialog=import_pt_dialog(self, self.iface)
        self.import_pt_dialog.ui.comboBoxFormat.setModel(self.modelPTFormat)
        
        # Manage
        self.export_delete_pt_dialog=export_delete_pt_dialog(self, self.iface)

        ## Road networks dialogs
        self.modelRoadSources = QtSql.QSqlQueryModel()
        self.modelRoadFormat = QtSql.QSqlQueryModel()
        self.modelRoadFormatVersion = QtSql.QSqlQueryModel()
        
        # Import
        self.import_road_dialog=import_road_dialog(self, self.iface)
        self.import_road_dialog.ui.comboBoxFormat.setModel(self.modelRoadFormat)
        self.import_road_dialog.ui.comboBoxFormatVersion.setModel(self.modelRoadFormatVersion)
        self.import_road_dialog.ui.comboBoxEncoding.setModel(self.modelEncoding)
        
        # Manage
        self.export_delete_road_dialog=export_delete_road_dialog(self, self.iface)
        
        ## POI dialogs
        self.modelPOISources = QtSql.QSqlQueryModel()
        self.modelPOIType = QtSql.QSqlQueryModel()
        self.modelPOIFormat = QtSql.QSqlQueryModel()
        self.modelPOIFormatVersion = QtSql.QSqlQueryModel()
        
        
        # Import
        self.import_poi_dialog=import_poi_dialog(self, self.iface)
        self.import_poi_dialog.ui.comboBoxFormat.setModel(self.modelPOIFormat)
        self.import_poi_dialog.ui.comboBoxFormatVersion.setModel(self.modelPOIFormatVersion)
        self.import_poi_dialog.ui.comboBoxEncoding.setModel(self.modelEncoding)
        self.import_poi_dialog.ui.comboBoxPOIType.setModel(self.modelPOIType)
        
        # Manage
        self.export_delete_poi_dialog=export_delete_poi_dialog(self, self.iface)
        
        ## Areas dialogs
        self.modelAreaSources = QtSql.QSqlQueryModel()
        self.modelAreaFormat = QtSql.QSqlQueryModel()
        self.modelAreaFormatVersion = QtSql.QSqlQueryModel()
        
        # Import
        self.import_areas_dialog=import_areas_dialog(self, self.iface)
        self.import_areas_dialog.ui.comboBoxFormat.setModel(self.modelAreaFormat)
        self.import_areas_dialog.ui.comboBoxFormatVersion.setModel(self.modelAreaFormatVersion)
        self.import_areas_dialog.ui.comboBoxEncoding.setModel(self.modelEncoding)
        
        # Manage
        self.export_delete_areas_dialog=export_delete_areas_dialog(self, self.iface)
        
        
        # Main dock widget
        # 1st tab
        self.modelObjType = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxObjType.setModel(self.modelObjType)
        self.obj_def_name="stop_areas"
        
        self.modelIndic = QtSql.QSqlQueryModel()
        self.dlg.ui.listViewIndic.setModel(self.modelIndic)
        
        self.modelNode = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxOrig.setModel(self.modelNode)
        self.dlg.ui.comboBoxDest.setModel(self.modelNode)
        self.dlg.ui.comboBoxPathsTreeRootNode.setModel(self.modelNode)
        
        self.modelSelectedNodes = QtSql.QSqlQueryModel()
        self.dlg.ui.listViewNodes.setModel(self.modelSelectedNodes)
        
        self.modelAgreg = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxNodeAg.setModel(self.modelAgreg)
        
        self.modelNodeType = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxNodeType.setModel(self.modelNodeType)
        
        self.modelAreaType=QtSql.QSqlQueryModel()  
        self.dlg.ui.comboBoxAreaType.setModel(self.modelAreaType)

        self.modelArea=QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxArea.setModel(self.modelArea)
        
        # 2nd tab
        self.modelStop = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxForcStop.setModel(self.modelStop)
        
        self.modelRoute = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxForcRoute.setModel(self.modelRoute)

        self.modelAgencies = QtSql.QSqlQueryModel()
        self.dlg.ui.tableViewAgencies.setModel(self.modelAgencies)
        self.dlg.ui.tableViewAgencies.verticalHeader().setVisible(False)
                
        self.dlg.ui.listViewGTFSFeeds.setModel(self.modelPTSources)
        
        self.modelIModes = QtSql.QSqlQueryModel()
        self.dlg.ui.listViewIModes.setModel(self.modelIModes)

        self.modelPTModes = QtSql.QSqlQueryModel()
        self.dlg.ui.listViewPTModes.setModel(self.modelPTModes)

        # 3rd tab
        self.modelDayType = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxDayType.setModel(self.modelDayType)

        self.modelPerType = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxPerType.setModel(self.modelPerType)

        self.dlg.ui.comboBoxDayAg.setModel(self.modelAgreg)
        self.dlg.ui.comboBoxTimeAg.setModel(self.modelAgreg)
        
        # 4th tab
        self.modelCriterion = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxCriterion.setModel(self.modelCriterion)
        
        # 5th tab
        self.modelSizeIndic = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxSizeIndic.setModel(self.modelSizeIndic)
        
        self.modelColorIndic = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxColorIndic.setModel(self.modelColorIndic)
        
        self.modelDerivedRepIndic = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxDerivedRepIndic.setModel(self.modelDerivedRepIndic)
        
        self.modelReq = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxReq.setModel(self.modelReq)
        
        self.modelDerivedRep=QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxDerivedRep.setModel(self.modelDerivedRep)
        
        self.modelPathID = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxPathID.setModel(self.modelPathID)
        
        self.modelRepMeth = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxRepMeth.setModel(self.modelRepMeth)
        
            
        self.clickTool = QgsMapToolEmitPoint(self.iface.mapCanvas()) # Outil permettant l'émission d'un QgsPoint à chaque clic sur le canevas 
        self.toolPan = QgsMapToolPan(self.iface.mapCanvas()) # Outil "main" utilisé pour se déplacer dans la fenêtre
        self.iface.mapCanvas().setMapTool(self.toolPan)
        
        self.chooseOrig = False
        self.chooseDest = False
        self.chooseNode = False

        
        self.timer = QTimer()
        self.timer.setInterval(1000)
        self.time = QTime()
        
        # Connect signals and slots
        self._connectSlots()
        
        # Create actions that will start plugin configuration 
        self.action = QAction(QIcon(self.icon_dir + "/icon_main.png"), u"Lancer le plugin",self.iface.mainWindow())
        self.action_set_db_connection = QAction(QIcon(self.icon_dir + "/icon_db.png"), u"Définir la connexion à la base de données", self.iface.mainWindow())
        self.action_manage_db = QAction(QIcon(self.icon_dir + "/icon_db.png"), u"Gérer les bases de données", self.iface.mainWindow())
        self.action_import_road = QAction(QIcon(self.icon_dir + "/icon_road.png"), u"Importer un réseau routier", self.iface.mainWindow())
        self.action_export_delete_road = QAction(QIcon(self.icon_dir + "/icon_road.png"), u"Exporter ou supprimer un réseau routier", self.iface.mainWindow())
        self.action_import_pt = QAction(QIcon(self.icon_dir + "/icon_pt.png"), u"Importer une offre de transport en commun", self.iface.mainWindow())
        self.action_export_delete_pt = QAction(QIcon(self.icon_dir + "/icon_pt.png"), u"Exporter ou supprimer une offre de transport en commun", self.iface.mainWindow())
        self.action_import_poi = QAction(QIcon(self.icon_dir + "/icon_poi.png"), u"Importer des points d'intérêt", self.iface.mainWindow())
        self.action_export_delete_poi = QAction(QIcon(self.icon_dir + "/icon_poi.png"), u"Exporter ou supprimer des points d'intérêt", self.iface.mainWindow())
        self.action_import_areas = QAction(QIcon(self.icon_dir + "/icon_areas.png"), u"Importer un zonage", self.iface.mainWindow())
        self.action_export_delete_areas = QAction(QIcon(self.icon_dir + "/icon_areas.png"), u"Exporter ou supprimer un zonage", self.iface.mainWindow())
        
        self.action.setToolTip(u"Lancer le plugin")
        self.action_set_db_connection.setToolTip(u"Définir la connexion à la base de données")
        self.action_manage_db.setToolTip(u"Gérer les bases de données")
        self.action_import_road.setToolTip(u"Importer un réseau routier")
        self.action_export_delete_road.setToolTip(u"Exporter ou supprimer un réseau routier")
        self.action_import_pt.setToolTip(u"Importer une offre de transport en commun")
        self.action_export_delete_pt.setToolTip(u"Exporter ou supprimer une offre de transport en commun")
        self.action_import_poi.setToolTip(u"Importer des points d'intérêt")
        self.action_export_delete_poi.setToolTip(u"Exporter ou supprimer des points d'intérêt")
        self.action_import_areas.setToolTip(u"Importer un zonage")
        self.action_export_delete_areas.setToolTip(u"Exporter ou supprimer un zonage")
        
        # Connect the actions to the methods
        self.action.triggered.connect(self.load)
        self.action_set_db_connection.triggered.connect(self.set_db_connection)
        self.action_manage_db.triggered.connect(self.manage_db)
        self.action_import_road.triggered.connect(self.import_road)
        self.action_export_delete_road.triggered.connect(self.export_delete_road)
        self.action_import_pt.triggered.connect(self.import_pt)
        self.action_export_delete_pt.triggered.connect(self.export_delete_pt)
        self.action_import_poi.triggered.connect(self.import_poi)
        self.action_export_delete_poi.triggered.connect(self.export_delete_poi)
        self.action_import_areas.triggered.connect(self.import_areas)
        self.action_export_delete_areas.triggered.connect(self.export_delete_areas)
        
        # Add toolbar buttons and menu items
        self.iface.addPluginToMenu(u"&Tempus Access",self.action)
        self.iface.addPluginToMenu(u"&Tempus Access", self.action_set_db_connection)
        self.iface.addPluginToMenu(u"&Tempus Access", self.action_manage_db)
        self.iface.addPluginToMenu(u"&Tempus Access", self.action_import_road)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_export_delete_road)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_import_pt)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_export_delete_pt)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_import_poi)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_export_delete_poi)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_import_areas)
        self.iface.addPluginToMenu(u"&Tempus Access",self.action_export_delete_areas)
                
        m = self.toolButton.menu()
        m.addAction(self.action)
        m.addAction(self.action_set_db_connection)
        m.addAction(self.action_manage_db)
        m.addAction(self.action_import_road)
        m.addAction(self.action_export_delete_road)
        m.addAction(self.action_import_pt)
        m.addAction(self.action_export_delete_pt)
        m.addAction(self.action_import_poi)
        m.addAction(self.action_export_delete_poi)
        m.addAction(self.action_import_areas)
        m.addAction(self.action_export_delete_areas)
        
        self.toolButton.setDefaultAction(self.action)
        self.first = False
    
    
    def load(self):
        # Set on-the-fly projection
        self.iface.mapCanvas().mapRenderer().setProjectionsEnabled(True) # Enable on the fly reprojections
        self.iface.mapCanvas().mapRenderer().setDestinationCrs(QgsCoordinateReferenceSystem(2154, QgsCoordinateReferenceSystem.PostgisCrsId))
        
        # Prepare main dock widget
        self.dlg.ui.radioButtonDayType.setChecked(True)
        self.dlg.ui.radioButtonPreciseDate.setChecked(True)
        self.dlg.ui.radioButtonTimePeriod.setChecked(True)
        self.node_type=0
        self.iface.addDockWidget(Qt.RightDockWidgetArea, self.dlg)
        
        # Show DBConnectionDialog
        self.set_db_connection_dialog.show()
        
    
    def unload(self):
        root = QgsProject.instance().layerTreeRoot()
        node_group=root.findGroup("Analyse de l'offre de transport collectif")
        root.removeChildNode(node_group)
        
        # Remove the plugin menu items and icons
        self.iface.removePluginMenu(u"&Tempus Access", self.action_import_areas)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_export_delete_areas)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_import_poi)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_export_delete_poi)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_import_pt)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_export_delete_pt)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_import_road)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_export_delete_road)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_set_db_connection)
        self.iface.removePluginMenu(u"&Tempus Access", self.action_manage_db)
        self.iface.removePluginMenu(u"&Tempus Access", self.action)

        self.iface.removeToolBarIcon(self.action_import_areas)
        self.iface.removeToolBarIcon(self.action_export_delete_areas)
        self.iface.removeToolBarIcon(self.action_import_poi)
        self.iface.removeToolBarIcon(self.action_export_delete_poi)
        self.iface.removeToolBarIcon(self.action_import_pt)
        self.iface.removeToolBarIcon(self.action_export_delete_pt)
        self.iface.removeToolBarIcon(self.action_import_road)
        self.iface.removeToolBarIcon(self.action_export_delete_road)
        self.iface.removeToolBarIcon(self.action_set_db_connection)
        self.iface.removeToolBarIcon(self.action_manage_db)
        self.iface.removeToolBarIcon(self.action)
        del self.toolButton
        
        # Close dialogs which would stay opened
        self.dlg.hide()
        self.import_areas_dialog.hide()
        self.export_delete_areas_dialog.hide()
        self.import_poi_dialog.hide()
        self.export_delete_poi_dialog.hide()
        self.import_pt_dialog.hide()
        self.export_delete_pt_dialog.hide()
        self.import_road_dialog.hide()
        self.export_delete_road_dialog.hide() 
        self.set_db_connection_dialog.hide()
        self.manage_db_dialog.hide()
    
    
    def set_db_connection(self):
        self.set_db_connection_dialog.show()
    
    
    def manage_db(self):
        self.manage_db_dialog.show()
    
    
    def import_road(self):
        self.import_road_dialog.show()


    def export_delete_road(self):
        self.export_delete_road_dialog.show()
        
    
    def import_pt(self):
        self.import_pt_dialog.show()
        self.import_pt_dialog.ui.labelFile1.setText('...')
        self.import_pt_dialog.ui.labelFile2.setText('...')
        self.import_pt_dialog.ui.labelFile3.setText('...')
        self.import_pt_dialog.cheminFichierComplet1=""
        self.import_pt_dialog.cheminFichierComplet2=""
        self.import_pt_dialog.cheminFichierComplet2=""
    
    
    def export_delete_pt(self):
        self.export_delete_pt_dialog.show()
    
    
    def import_poi(self):
        self.import_poi_dialog.show()
    
    
    def export_delete_poi(self):
        self.export_delete_poi_dialog.show()
    
    
    def import_areas(self):
        self.import_areas_dialog.show()
        
    
    def export_delete_areas(self):
        self.export_delete_areas_dialog.show()
    

    def indicDisplay(self, layer_name, layer_style_path, col_id, col_geom, filter):
        if (layer_name!=''):
            
            uri=QgsDataSourceURI()
            uri.setConnection(self.db.hostName(), str(self.db.port()), self.db.databaseName(), self.db.userName(), self.db.password())
            uri.setDataSource("indic", layer_name, col_geom, "", col_id) 
            
            layer = QgsVectorLayer(uri.uri(), layer_name, "postgres")
            layer.setProviderEncoding(u'UTF-8')
            layer.dataProvider().setEncoding(u'UTF-8')
            
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_indicators.insertChildNode(0, node_layer)
            
            self.node_indicators.setExpanded(True)
            self.node_pt_offer.setExpanded(False)
            self.node_admin.setExpanded(False)
            self.node_vacances.setExpanded(False)
            
            layer.setSubsetString(filter)
            
            if (col_geom != None):
                if (layer_style_path != ''):
                    layer.loadNamedStyle(layer_style_path)
                    self.iface.legendInterface().setLayerVisible(layer, True)

                from_proj = QgsCoordinateReferenceSystem()
                from_proj.createFromSrid(4326)
                to_proj = QgsCoordinateReferenceSystem()
                to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
                crd=QgsCoordinateTransform(from_proj, to_proj)
            
                # Center map display on result layer
                for name, l in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
                    if (l.name()==layer_name): 
                        self.iface.mapCanvas().setExtent(crd.transform(l.extent()))
                
                self.iface.mapCanvas().refreshMap()


    def manageStoredQueries(self):
        self.manageStoredQueriesDialog.show()
    
    
    def refreshGTFSFeeds(self):    
        # Populate the listView containing GTFS data sources
        s="SELECT distinct feed_id, id FROM tempus_gtfs.feed_info"
        self.modelPTSources.setQuery(unicode(s), self.db)
        
        # Each update of the model must be accompanied by a new connexion of signal and slot on the listView selection
        self.dlg.ui.listViewGTFSFeeds.selectionModel().selectionChanged.connect(self._slotListViewGTFSFeedsSelectionChanged)
        
        sel = QItemSelection(self.modelPTSources.index(0,0), self.modelPTSources.index(0,1))
        self.dlg.ui.listViewGTFSFeeds.selectionModel().select(sel, QItemSelectionModel.ClearAndSelect)
    
    
    def refreshPTData(self):        
        s="REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode;\
           REFRESH MATERIALIZED VIEW tempus_access.sections_by_mode;\
           REFRESH MATERIALIZED VIEW tempus_access.trips_by_mode;\
           REFRESH MATERIALIZED VIEW tempus_access.transfers_geom"
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
    
    
    def refreshReq(self):
        self.modelReq.setQuery("(\
                                    SELECT layer_name, id, obj_type, indics, o_node, d_node, node_type, \
                                            o_nodes, d_nodes, nodes_ag, symb_size, symb_color, days, day_type, per_type, \
                                            per_start, per_end, day_ag, time_start, time_end, time_ag, time_point, \
                                            area_type, areas, route, stop, gtfs_feeds, agencies, \
                                            pt_modes, i_modes, walk_speed, cycl_speed, max_cost, \
                                            criterion, req\
                                    FROM tempus_access.indic_catalog\
                                    WHERE parent_layer IS NULL\
                                )\
                                UNION\
                                (\
                                    SELECT '', null, null, null, null, null, null, \
                                    null, null, null, null, null, null, null, null, \
                                    null, null, null, null, null, null, null, \
                                    null, null, null, null, null, null, \
                                    null, null, null, null, null, null, null \
                                )\
                                ORDER BY 1", \
                             self.db)
    
    
    def refreshDerivedRep(self):
        self.modelDerivedRep.setQuery("(\
                                    SELECT layer_name, id, obj_type, indics, classes_num, param, rep_meth\
                                    FROM tempus_access.indic_catalog\
                                    WHERE parent_layer ='"+self.dlg.ui.comboBoxReq.currentText()+"'\
                                )\
                                UNION\
                                (\
                                    SELECT '', null, null, null, null, null, null\
                                )\
                                ORDER BY 1", \
                             self.db)
    
    
    def updateReqIndicators(self):
        s="(\
                  SELECT lib, code, col_name FROM tempus_access.indicators \
                  WHERE map_size = TRUE AND col_name IN \
                  (\
                    SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.dlg.ui.comboBoxReq.currentText()+"')\
                  AND col_name IN \
                           (SELECT col_name FROM tempus_access.indicators \
                           WHERE ARRAY[code] <@ (SELECT indic_list::integer[] FROM tempus_access.obj_type WHERE def_name = '"+self.obj_def_name+"') \
                           )\
                  )\
                  UNION \
                  (\
                  SELECT '', -1, '' \
                  )\
                  ORDER BY 2"
        self.modelSizeIndic.setQuery(s, self.db)
            
        s="(\
               SELECT lib, code, col_name FROM tempus_access.indicators \
               WHERE map_color = TRUE AND col_name IN \
               (SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.dlg.ui.comboBoxReq.currentText()+"')\
               AND col_name IN \
                           (SELECT col_name FROM tempus_access.indicators \
                           WHERE ARRAY[code] <@ (SELECT indic_list::integer[] FROM tempus_access.obj_type WHERE def_name = '"+self.obj_def_name+"') \
                           )\
              )\
              UNION \
              (\
              SELECT '', -1, '' \
              )\
              ORDER BY 2"
        self.modelColorIndic.setQuery( s,self.db)
        
        
    def loadLayers(self):
        from_proj = QgsCoordinateReferenceSystem()
        from_proj.createFromSrid(4326)
        to_proj = QgsCoordinateReferenceSystem()
        to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
        crd=QgsCoordinateTransform(from_proj, to_proj)
        
        # # Adding data tables/views in the layer manager
        uri=QgsDataSourceURI()
        uri.setConnection(self.db.hostName(), str(self.db.port()), self.db.databaseName(), self.db.userName(), self.db.password())
        
        # Holidays table
        uri.setDataSource("tempus", "holidays", None, "") 
        layer = QgsVectorLayer(uri.uri(), "Vacances scolaires", "postgres")
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_vacances.insertChildNode(0, node_layer)
                
        # Bank holidays view
        uri.setDataSource("tempus", "view_french_bank_holiday", None, "", "date") 
        layer = QgsVectorLayer(uri.uri(), u"Jours fériés", "postgres")
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_vacances.insertChildNode(1, node_layer)
            
        # Areas
        for i in range(0,self.modelAreaType.rowCount()):
            if (self.modelAreaType.record(i).value("code")!=-1):
                uri.setDataSource("tempus_access", "area_type"+str(self.modelAreaType.record(i).value("code")), "geom", "")
                layer = QgsVectorLayer(uri.uri(), self.modelAreaType.record(i).value("lib"), "postgres")
                if (layer.isValid()):
                    QgsMapLayerRegistry.instance().addMapLayer(layer, False)
                    node_layer = QgsLayerTreeLayer(layer)
                    self.node_admin.insertChildNode(i, node_layer)
                    self.iface.legendInterface().setLayerVisible(layer, False)
                
        # Stops by mode (view)
        uri.setDataSource("tempus_gtfs", "stops_by_mode", "geom", "", "gid") 
        layer = QgsVectorLayer(uri.uri(), u"Arrêts par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/stops_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(0, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True) 
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+"::integer[])")
                
        # Sections by mode (view)
        uri.setDataSource("tempus_gtfs", "sections_by_mode", "geom", "", "gid")
        layer = QgsVectorLayer(uri.uri(), "Sections par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/sections_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(1, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+"::integer[])")
        
        # Trips by mode (view)
        uri.setDataSource("tempus_gtfs", "trips_by_mode", "geom_multi", "", "gid")
        layer = QgsVectorLayer(uri.uri(), u"Itinéraires de ligne par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/trips_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(2, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+"::integer[])")
        
        # Stops
        uri.setDataSource("tempus_gtfs", "stops", "geom", "", "id") 
        layer = QgsVectorLayer(uri.uri(), u"Arrêts", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/stops.qml')
        if (layer.isValid):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(3, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            # Center map on this layer
            if (layer.extent().isEmpty==False): 
                self.iface.mapCanvas().setExtent(crd.transform(layer.extent()))
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+"::integer[])")
        
        # Sections
        uri.setDataSource("tempus_gtfs", "sections", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), "Sections", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/sections.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(4, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("ARRAY[feed_id] <@ ARRAY"+str(self.PTSources)+"::integer[]")
        
        # Transfer arcs
        uri.setDataSource("tempus_access", "transfers_geom", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), "Arcs de transfert", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/sections.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(5, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+"::integer[])")

        # Car/Bicycle parks and user POIs
        uri.setDataSource("tempus", "poi", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"POI et stationnements", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/poi.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(0, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)

        # Road nodes
        uri.setDataSource("tempus", "road_node", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Noeuds routiers", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_node.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(1, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
        
        # Road sections
        uri.setDataSource("tempus", "road_section_pedestrians", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Réseau piéton", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_section_directions_road_types.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(2, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
        
        uri.setDataSource("tempus", "road_section_cyclists", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Réseau vélo", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_section_directions_road_types.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(3, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            
        uri.setDataSource("tempus", "road_section_cars", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Réseau voiture", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_section_directions_road_types.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(4, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)

        # Penalized road movements
        uri.setDataSource("tempus", "penalized_movements", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Mouvements pénalisé", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/penalized_movements.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(5, node_layer)
            self.iface.legendInterface().setLayerVisible(layer,False)
        
        # Expand or hide node groups
        self.node_group.setExpanded(True)
        self.node_indicators.setExpanded(False)
        self.node_vacances.setExpanded(False)
        self.node_pt_offer.setExpanded(False)
        self.node_admin.setExpanded(False)
        
        self.iface.mapCanvas().refreshMap()
    
    
    def daysFilter(self):
        self.day="NULL"
        self.day_type="NULL"
        self.per_type="NULL"
        self.per_start="NULL"
        self.per_end="NULL"
        
        # Day/day type choice processing
        if (self.dlg.ui.radioButtonPreciseDate.isChecked()):
            self.day = "'"+self.dlg.ui.calendarWidget.selectedDate().toString('yyyy-MM-dd')+"'"
            
        elif (self.dlg.ui.radioButtonDayType.isChecked()):
            self.day_type = self.modelDayType.record(self.dlg.ui.comboBoxDayType.currentIndex()).value("mod_code") 
            self.per_type = self.modelPerType.record(self.dlg.ui.comboBoxPerType.currentIndex()).value("mod_code") 
            self.per_start = "'"+self.dlg.ui.dateEditPerStart.date().toString('yyyy-MM-dd')+"'"
            self.per_end = "'"+self.dlg.ui.dateEditPerEnd.date().toString('yyyy-MM-dd')+"'"
               
        self.day_ag = self.modelAgreg.record(self.dlg.ui.comboBoxDayAg.currentIndex()).value("code")
    
    
    def timeFilter(self):
        self.time_start="NULL"
        self.time_end="NULL"
        self.time_point="NULL"
        self.time_interval="NULL"
        self.all_services=False
        self.time_ag=0
        
        if (self.dlg.ui.radioButtonTimePeriod.isChecked()):
            self.time_start="'"+str(self.dlg.ui.timeEditTimeStart.time().toString("hh:mm:ss"))+"'"
            self.time_end="'"+str(self.dlg.ui.timeEditTimeEnd.time().toString("hh:mm:ss"))+"'"
            if (self.dlg.ui.radioButtonAllServices.isChecked()):
                self.all_services=True
            elif (self.dlg.ui.radioButtonTimeInterval.isChecked()):
                self.time_interval=(self.dlg.ui.timeEditTimeInterval.time().hour()*3600 + self.dlg.ui.timeEditTimeInterval.time().minute()*60 + self.dlg.ui.timeEditTimeInterval.time().second())/60
            self.time_ag = self.modelAgreg.record(self.dlg.ui.comboBoxTimeAg.currentIndex()).value("code")

        elif (self.dlg.ui.radioButtonTimePoint.isChecked()):
            self.time_point = "'"+str(self.dlg.ui.timeEditTimePoint.time().toString("hh:mm:ss"))+"'"
        
  
    def buildQuery(self):
        self.daysFilter()
        self.timeFilter() 
        
         # Indicators
        self.indics=[]
        if (self.dlg.ui.listViewIndic.selectionModel().hasSelection()):
            for item in self.dlg.ui.listViewIndic.selectionModel().selectedRows():
                self.indics.append(self.modelIndic.record(item.row()).value("code"))
        else:
            box = QMessageBox()
            box.setText(u"Sélectionnez au moins un indicateur (onglet n°1)")
            box.exec_()
        
        # GTFS feeds
        self.PTSources = []
        if (self.dlg.ui.listViewGTFSFeeds.selectionModel().hasSelection()):
            for item in self.dlg.ui.listViewGTFSFeeds.selectionModel().selectedRows():
                self.PTSources.append(self.modelPTSources.record(item.row()).value("id"))
        else:
            box = QMessageBox()
            box.setText(u"Sélectionnez au moins une source de données GTFS (onglet n°2)")
            box.exec_()
        
        # Transport modes
        self.tran_modes=[]
        self.pt_modes=[]
        self.i_modes=[]
        self.route_types=[]
        if (self.dlg.ui.listViewPTModes.selectionModel().hasSelection()):
            # PT modes concatenation
            for item in self.dlg.ui.listViewPTModes.selectionModel().selectedRows():
                if (self.modelPTModes.record(item.row()).value("gtfs_feed_id") != None):
                    self.route_types.append(self.modelPTModes.record(item.row()).value("gtfs_route_type")) 
                    self.pt_modes.append(self.modelPTModes.record(item.row()).value("id"))
                    self.tran_modes.append(self.modelPTModes.record(item.row()).value("id"))
        if (self.dlg.ui.listViewIModes.selectionModel().hasSelection()):
            # Individual modes concatenation
            for item in self.dlg.ui.listViewIModes.selectionModel().selectedRows():
                self.i_modes.append(self.modelIModes.record(item.row()).value("id"))
                self.tran_modes.append(self.modelIModes.record(item.row()).value("id"))
                
        if ((self.dlg.ui.listViewPTModes.selectionModel().hasSelection()==False) and (self.dlg.ui.listViewIModes.selectionModel().hasSelection()==False)):
            box = QMessageBox()
            box.setText(u"Sélectionner au moins un mode de transport (onglet n°2)")
            box.exec_()
        
        # Area type
        if (self.modelAreaType.record(self.dlg.ui.comboBoxAreaType.currentIndex()).value("code")>=0):
            self.area_type = self.modelAreaType.record(self.dlg.ui.comboBoxAreaType.currentIndex()).value("code") 
        else:
            self.area_type = -1      
        
        # Area ID
        if (self.modelArea.record(self.dlg.ui.comboBoxArea.currentIndex()).value("char_id")>=0):
            self.areas = "ARRAY['"+self.modelArea.record(self.dlg.ui.comboBoxArea.currentIndex()).value("char_id")+"']"
        else:
            self.areas = "NULL"
        
        # Routes
        if (self.modelRoute.record(self.dlg.ui.comboBoxForcRoute.currentIndex()).value("id") >=0):
            self.route = str(self.modelRoute.record(self.dlg.ui.comboBoxForcRoute.currentIndex()).value("id"))
        else:
            self.route = "NULL"
        
        # Stops
        if (self.modelStop.record(self.dlg.ui.comboBoxForcStop.currentIndex()).value("id") >=0):
            self.stop = str(self.modelStop.record(self.dlg.ui.comboBoxForcStop.currentIndex()).value("id"))
        else:
            self.stop = "NULL"
        
        self.obj_def_name = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("def_name")
        self.obj_type = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("code")        
        
        self.query=""
        if ((self.obj_def_name == "stop_areas") or (self.obj_def_name == "stops") or (self.obj_def_name=="sections") or (self.obj_def_name=="trips") or (self.obj_def_name=="routes")):
            # Agencies
            self.agencies=[]
            if (self.dlg.ui.tableViewAgencies.selectionModel().hasSelection()):
                for item in self.dlg.ui.tableViewAgencies.selectionModel().selectedRows():
                    self.agencies.append(self.modelAgencies.record(item.row()).value("id"))
            if (self.agencies==[]):
                box = QMessageBox()
                box.setText(u"Sélectionnez au moins un transporteur (onglet n°2)")
                box.exec_()
            
            # Build stop indicators
            if (self.obj_def_name=="stop_areas"):
                self.query="SELECT tempus_access.create_pt_stop_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                            ARRAY"+str(self.PTSources)+",\
                                                                            ARRAY"+str(self.route_types)+",\
                                                                            ARRAY"+str(self.agencies)+",\
                                                                            1, \
                                                                            "+self.day+"::date,\
                                                                            "+str(self.day_type)+"::integer, \
                                                                            "+str(self.per_type)+"::integer, \
                                                                            "+self.per_start+"::date, \
                                                                            "+self.per_end+"::date, \
                                                                            "+str(self.day_ag)+",\
                                                                            "+self.time_start+"::time, \
                                                                            "+self.time_end+"::time, \
                                                                            "+str(self.area_type)+",\
                                                                            "+self.areas+",\
                                                                            "+self.route+");"
            
            elif (self.obj_def_name=="stops"):
                self.query="SELECT tempus_access.create_pt_stop_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                            ARRAY"+str(self.PTSources)+",\
                                                                            ARRAY"+str(self.route_types)+",\
                                                                            ARRAY"+str(self.agencies)+",\
                                                                            0, \
                                                                            "+self.day+"::date,\
                                                                            "+str(self.day_type)+"::integer, \
                                                                            "+str(self.per_type)+"::integer, \
                                                                            "+self.per_start+"::date, \
                                                                            "+self.per_end+"::date, \
                                                                            "+str(self.day_ag)+",\
                                                                            "+self.time_start+"::time, \
                                                                            "+self.time_end+"::time, \
                                                                            "+str(self.area_type)+",\
                                                                            "+self.areas+",\
                                                                            "+self.route+");"
            
            # Build sections indicators
            elif (self.obj_def_name=="sections"):
                self.query="SELECT tempus_access.create_pt_section_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                          ARRAY"+str(self.PTSources)+",\
                                                                          ARRAY"+str(self.route_types)+",\
                                                                          ARRAY"+str(self.agencies)+",\
                                                                          "+self.day+"::date,\
                                                                          "+str(self.day_type)+"::integer, \
                                                                          "+str(self.per_type)+"::integer, \
                                                                          "+self.per_start+"::date, \
                                                                          "+self.per_end+"::date, \
                                                                          "+str(self.day_ag)+",\
                                                                          "+self.time_start+"::time, \
                                                                          "+self.time_end+"::time, \
                                                                          "+str(self.time_ag)+",\
                                                                          "+str(self.area_type)+",\
                                                                          "+self.areas+",\
                                                                          "+self.route+",\
                                                                          "+self.stop+");"
            
            # Build trips indicators
            elif (self.obj_def_name=="trips"):
                self.query="SELECT tempus_access.create_pt_trip_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                       ARRAY"+str(self.PTSources)+",\
                                                                       ARRAY"+str(self.route_types)+",\
                                                                       ARRAY"+str(self.agencies)+",\
                                                                       "+self.day+"::date,\
                                                                       "+str(self.day_type)+"::integer, \
                                                                       "+str(self.per_type)+"::integer, \
                                                                       "+self.per_start+"::date, \
                                                                       "+self.per_end+"::date, \
                                                                       "+str(self.day_ag)+",\
                                                                       "+self.time_start+"::time, \
                                                                       "+self.time_end+"::time, \
                                                                       "+str(self.time_ag)+",\
                                                                       "+str(self.area_type)+",\
                                                                       "+self.areas+",\
                                                                       "+self.route+",\
                                                                       "+self.stop+");"
            
            # Build routes indicators
            elif (self.obj_def_name=="routes"):
                self.query="SELECT tempus_access.create_pt_route_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                       ARRAY"+str(self.PTSources)+",\
                                                                       ARRAY"+str(self.route_types)+",\
                                                                       ARRAY"+str(self.agencies)+",\
                                                                       "+self.day+"::date,\
                                                                       "+str(self.day_type)+"::integer, \
                                                                       "+str(self.per_type)+"::integer, \
                                                                       "+self.per_start+"::date, \
                                                                       "+self.per_end+"::date, \
                                                                       "+str(self.day_ag)+",\
                                                                       "+self.time_start+"::time, \
                                                                       "+self.time_end+"::time, \
                                                                       "+str(self.area_type)+",\
                                                                       "+self.areas+",\
                                                                       "+self.stop+");"
        
        # Build agencies indicators
        if (self.obj_def_name=="agencies"):
            self.query="SELECT tempus_access.create_pt_agency_indicator_layer(ARRAY"+str(self.indics)+",\
                                                                   ARRAY"+str(self.PTSources)+",\
                                                                   ARRAY"+str(self.route_types)+",\
                                                                   "+self.day+"::date,\
                                                                   "+str(self.day_type)+"::integer, \
                                                                   "+str(self.per_type)+"::integer, \
                                                                   "+self.per_start+"::date, \
                                                                   "+self.per_end+"::date, \
                                                                   "+str(self.day_ag)+",\
                                                                   "+self.time_start+"::time, \
                                                                   "+self.time_end+"::time, \
                                                                   "+str(self.area_type)+",\
                                                                   "+self.areas+",\
                                                                   "+self.stop+");" 
        
        # Build paths/paths trees/isochrons indicators
        elif ((self.obj_def_name=="paths") or (self.obj_def_name=="paths_details") or (self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")):
            self.days = []
            s1="SELECT unnest(days)::character varying FROM tempus_access.days("+self.day+"::date,"+str(self.day_type)+"::integer,"+str(self.per_type)+"::integer,"+self.per_start+"::date,"+self.per_end+"::date);"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(s1+"\n")
            q1=QtSql.QSqlQuery(self.db)
            q1.exec_(unicode(s1))
            while q1.next():
                self.days.append(q1.value(0))
            
            self.road_node_from = 0
            self.road_node_to = 0
            if (self.obj_def_name=="paths") or (self.obj_def_name=="paths_details"):            
                if (self.node_type==0): # PT stop area
                    self.road_node_from = "(SELECT tempus_access.road_node_from_stop_id("+str(self.from_node)+"))"
                    self.road_node_to = "(SELECT tempus_access.road_node_from_stop_id("+str(self.to_node)+"))"
                elif (self.node_type==1): # Road node
                    self.road_node_from = self.from_node
                    self.road_node_to = self.to_node
                
                s1="DELETE FROM tempus_access.tempus_paths_results;"
                if self.debug:
                    with open(self.plugin_dir+"/log.txt", "a") as log_file:
                        log_file.write(s1+"\n")
                q1=QtSql.QSqlQuery(self.db)
                q1.exec_(unicode(s1))
                
                self.max_cost=0
                self.walking_speed=0
                self.cycling_speed=0
                self.node_ag = self.modelAgreg.record(self.dlg.ui.comboBoxNodeAg.currentIndex()).value("code")
                
                if (self.obj_def_name == "paths"):
                    self.query="SELECT tempus_access.create_path_indicator_layer(ARRAY"+str(self.indics)+", \
                                                                       "+str(self.node_type)+", \
                                                                       "+str(self.from_node)+", \
                                                                       "+str(self.to_node)+", \
                                                                       ARRAY"+str(self.tran_modes)+", \
                                                                       "+self.day+"::date, \
                                                                       "+str(self.day_type)+"::integer, \
                                                                       "+str(self.per_type)+"::integer, \
                                                                       "+self.per_start+"::date, \
                                                                       "+self.per_end+"::date, \
                                                                       "+self.time_point+"::time, \
                                                                       "+self.time_start+"::time, \
                                                                       "+self.time_end+"::time, \
                                                                       "+str(self.time_interval)+"::integer, \
                                                                       "+str(self.all_services)+"::boolean, \
                                                                       "+str(self.constraint_date_after)+"::boolean);"
                elif (self.obj_def_name == "paths_details"):
                    self.query = "SELECT tempus_access.create_path_details_indicator_layer(ARRAY"+str(self.indics)+", \
                                                                       "+str(self.node_type)+", \
                                                                       "+str(self.from_node)+", \
                                                                       "+str(self.to_node)+", \
                                                                       ARRAY"+str(self.tran_modes)+", \
                                                                       "+self.day+"::date, \
                                                                       "+str(self.day_type)+"::integer, \
                                                                       "+str(self.per_type)+"::integer, \
                                                                       "+self.per_start+"::date, \
                                                                       "+self.per_end+"::date, \
                                                                       "+self.time_point+"::time, \
                                                                       "+self.time_start+"::time, \
                                                                       "+self.time_end+"::time, \
                                                                       "+str(self.time_interval)+"::integer, \
                                                                       "+str(self.all_services)+"::boolean, \
                                                                       "+str(self.constraint_date_after)+"::boolean);"
            
            self.road_nodes = []
            if (self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees"):
                if (self.node_type==0): # Node type = PT stop area
                    if (self.obj_def_name=="paths_tree"):
                        s="SELECT tempus_access.road_node_from_stop_id("+str(self.root_node)+")"
                        q=QtSql.QSqlQuery(self.db)
                        q.exec_(unicode(s))
                        q.next()
                        self.road_nodes.append(q.value(0))
                    elif (self.obj_def_name=="comb_paths_trees"):
                        for node in self.root_nodes:
                            s="SELECT tempus_access.road_node_from_stop_id("+str(node)+")"
                            q=QtSql.QSqlQuery(self.db)
                            q.exec_(unicode(s))
                            q.next()
                            self.road_nodes.append(q.value(0))
                
                elif (self.node_type==1): # Node type = Road node
                    if (self.obj_def_name=="paths_tree"):
                        self.road_nodes.append(self.root_node)
                    elif (self.obj_def_name=="comb_paths_trees"):
                        self.road_nodes = self.root_nodes
                
                self.max_cost=self.dlg.ui.spinBoxMaxCost.value()
                self.walking_speed=self.dlg.ui.doubleSpinBoxWalkingSpeed.value()
                self.cycling_speed=self.dlg.ui.doubleSpinBoxCyclingSpeed.value()
                
                # For isosurfaces computation
                self.indic = self.modelDerivedRepIndic.record(self.dlg.ui.comboBoxDerivedRepIndic.currentIndex()).value("code")
                self.rep_meth = self.modelRepMeth.record(self.dlg.ui.comboBoxRepMeth.currentIndex()).value("mod_code")
                self.classes_num=self.dlg.ui.spinBoxDerivedRepClasses.value()
                self.param=self.dlg.ui.doubleSpinBoxRepParam.value()                
                
                if (self.isosurfaces==False):
                    if (self.obj_def_name == "paths_tree"):
                        self.query="SELECT tempus_access.create_paths_tree_indicator_layer(ARRAY"+str(self.indics)+", \
                                                                           "+str(self.node_type)+", \
                                                                           "+str(self.root_node)+", \
                                                                           ARRAY"+str(self.tran_modes)+", \
                                                                           "+self.day+"::date, \
                                                                           "+self.time_point+"::time, \
                                                                           "+str(self.constraint_date_after)+"::boolean,\
                                                                           "+str(self.max_cost)+",\
                                                                           "+str(self.walking_speed)+",\
                                                                           "+str(self.cycling_speed)+");"
                                                                           
                    elif (self.obj_def_name == "comb_paths_trees"):
                        self.nodes_ag = self.modelAgreg.record(self.dlg.ui.comboBoxNodeAg.currentIndex()).value("code")
                        self.query="SELECT tempus_access.create_comb_paths_trees_indicator_layer(ARRAY"+str(self.indics)+", \
                                                                           "+str(self.node_type)+", \
                                                                           ARRAY"+str(self.root_nodes)+", \
                                                                           "+str(self.nodes_ag)+",\
                                                                           ARRAY"+str(self.tran_modes)+", \
                                                                           "+self.day+"::date, \
                                                                           "+str(self.day_type)+"::integer, \
                                                                           "+str(self.per_type)+"::integer, \
                                                                           "+self.per_start+"::date, \
                                                                           "+self.per_end+"::date, \
                                                                           "+str(self.day_ag)+",\
                                                                           "+self.time_point+"::time, \
                                                                           "+self.time_start+"::time, \
                                                                           "+self.time_end+"::time, \
                                                                           "+str(self.time_interval)+"::integer, \
                                                                           "+str(self.time_ag)+",\
                                                                           "+str(self.constraint_date_after)+"::boolean,\
                                                                           "+str(self.max_cost)+",\
                                                                           "+str(self.walking_speed)+",\
                                                                           "+str(self.cycling_speed)+");"
                                                                           
                elif (self.parent_layer!=""):
                    self.query="SELECT tempus_access.create_isosurfaces_indicator_layer("+str(self.indic)+"::integer,\
                                                                                        '"+self.parent_layer+"',\
                                                                                        "+str(self.classes_num)+"::integer, \
                                                                                        "+str(self.param)+"::double precision, \
                                                                                        "+str(self.rep_meth)+"::integer);"
        self.query=self.query.replace("  ", "")
        
        
    def _connectSlots(self):
        
        # General interface
        self.dlg.ui.pushButtonIndicCalculate.clicked.connect(self._slotPushButtonIndicCalculateClicked)
        self.dlg.ui.pushButtonReinitCalc.clicked.connect(self._slotPushButtonReinitCalcClicked)
        #self.dlg.ui.pushButtonStopQuery.clicked.connect(self._slotPushButtonStopQueryClicked)
        self.timer.timeout.connect(self._slotUpdateTimer) 
        self.dlg.ui.checkBoxVerbose.stateChanged.connect(self._slotCheckBoxVerboseStateChanged)
        
        # 1st tab
        self.dlg.ui.comboBoxObjType.currentIndexChanged.connect(self._slotComboBoxObjTypeIndexChanged)
        self.dlg.ui.comboBoxNodeType.currentIndexChanged.connect(self._slotComboBoxNodeTypeIndexChanged)
        self.clickTool.canvasClicked.connect(self._slotClickPoint)
        self.dlg.ui.comboBoxOrig.currentIndexChanged.connect(self._slotComboBoxOrigIndexChanged)
        self.dlg.ui.comboBoxDest.currentIndexChanged.connect(self._slotComboBoxDestIndexChanged)
        self.dlg.ui.comboBoxPathsTreeRootNode.currentIndexChanged.connect(self._slotComboBoxPathsTreeRootNodeIndexChanged)
        self.dlg.ui.pushButtonChooseOrigOnMap.clicked.connect(self._slotPushButtonChooseOrigOnMapClicked)
        self.dlg.ui.pushButtonChooseDestOnMap.clicked.connect(self._slotPushButtonChooseDestOnMapClicked)
        self.dlg.ui.pushButtonChoosePathsTreeRootOnMap.clicked.connect(self._slotPushButtonChoosePathsTreeRootOnMapClicked)
        self.dlg.ui.pushButtonChoosePathsTreesRootsOnMap.clicked.connect(self._slotPushButtonChoosePathsTreesRootsOnMapClicked)
        self.dlg.ui.pushButtonRemovePathsTreesRoots.clicked.connect(self._slotPushButtonRemovePathsTreesRootsClicked)
        self.dlg.ui.comboBoxAreaType.currentIndexChanged.connect(self._slotComboBoxAreaTypeIndexChanged)
        self.dlg.ui.comboBoxArea.currentIndexChanged.connect(self._slotComboBoxAreaIndexChanged)
        self.dlg.ui.pushButtonInvertOD.clicked.connect(self._slotPushButtonInvertODClicked)
        self.dlg.ui.comboBoxPathsTreeOD.currentIndexChanged.connect(self._slotComboBoxPathsTreeODIndexChanged)
        self.dlg.ui.comboBoxCombPathsTreesOD.currentIndexChanged.connect(self._slotComboBoxCombPathsTreesODIndexChanged)
        
        
        # 2nd tab
        self.dlg.ui.listViewGTFSFeeds.selectionModel().selectionChanged.connect(self._slotListViewGTFSFeedsSelectionChanged)
        
        
        # 3rd tab 
        self.dlg.ui.radioButtonPreciseDate.toggled.connect(self._slotRadioButtonPreciseDateToggled)
        self.dlg.ui.radioButtonDayType.toggled.connect(self._slotRadioButtonDayTypeToggled)
        self.dlg.ui.radioButtonTimePeriod.toggled.connect(self._slotRadioButtonTimePeriodToggled)
        self.dlg.ui.radioButtonTimePoint.toggled.connect(self._slotRadioButtonTimePointToggled)
        self.dlg.ui.comboBoxTimeConstraint.currentIndexChanged.connect(self._slotComboBoxTimeConstraintIndexChanged)
        self.dlg.ui.radioButtonTimeInterval.toggled.connect(self._slotRadioButtonTimeIntervalToggled)
        
        
        # 4th tab
        
        
        
        # 5th tab
        self.dlg.ui.pushButtonReqDelete.clicked.connect(self._slotPushButtonReqDeleteClicked)
        self.dlg.ui.pushButtonReqRename.clicked.connect(self._slotPushButtonReqRenameClicked)
        self.dlg.ui.pushButtonDerivedRepDelete.clicked.connect(self._slotPushButtonDerivedRepDeleteClicked)
        self.dlg.ui.pushButtonDerivedRepRename.clicked.connect(self._slotPushButtonDerivedRepRenameClicked)
        self.dlg.ui.pushButtonSaveComments.clicked.connect(self._slotPushButtonSaveCommentsClicked)
        self.dlg.ui.pushButtonDerivedRepGenerate.clicked.connect(self._slotPushButtonDerivedRepGenerateClicked)
        self.dlg.ui.comboBoxPathID.currentIndexChanged.connect(self._slotComboBoxPathIDIndexChanged)
        self.dlg.ui.pushButtonReqDisplay.clicked.connect(self._slotpushButtonReqDisplayClicked)
        self.dlg.ui.comboBoxSizeIndic.currentIndexChanged.connect(self._slotComboBoxSizeIndicIndexChanged)
        self.dlg.ui.comboBoxColorIndic.currentIndexChanged.connect(self._slotComboBoxColorIndicIndexChanged)
        self.dlg.ui.comboBoxDerivedRep.currentIndexChanged.connect(self._slotComboBoxDerivedRepIndexChanged)
        self.dlg.ui.comboBoxDerivedRepIndic.currentIndexChanged.connect(self._slotComboBoxDerivedRepIndicIndexChanged)
        self.dlg.ui.comboBoxReq.currentIndexChanged.connect(self._slotComboBoxReqIndexChanged)
    
    
    # Slots of the general interface
    
    def _slotPushButtonIndicCalculateClicked(self):
        self.isosurfaces=False
        self.buildQuery()
        
        self.done=False
        self.time.start()
        self.timer.start()
        
        if ((self.obj_def_name == "stop_areas") or (self.obj_def_name == "stops") or (self.obj_def_name=="sections") or (self.obj_def_name == "trips") or (self.obj_def_name == "routes") or (self.obj_def_name == "agencies")):
            self.gen_indic_thread = genIndicThread(self.query, \
                                                    self.db, \
                                                    self.debug \
                                                  )
            self.gen_indic_thread.finished.connect(self._slotDone)
            self.gen_indic_thread.resultAvailable.connect(self._slotResultAvailable)
            self.gen_indic_thread.start()
        
        elif ((self.obj_def_name == "paths") or (self.obj_def_name == "paths_details") or (self.obj_def_name == "paths_tree") or (self.obj_def_name == "comb_paths_trees")):
            path_tree=False
            if (self.obj_def_name == "paths_tree") or (self.obj_def_name == "comb_paths_trees"):
                path_tree=True
            
            dbstring="host="+self.db.hostName()+" dbname="+self.db.databaseName()+" port="+str(self.db.port())
            
            self.path_indic_thread = pathIndicThread(
                                                        self.query, \
                                                        self.db, \
                                                        dbstring, \
                                                        self.road_node_from, \
                                                        self.road_node_to, \
                                                        self.road_nodes, \
                                                        self.time_start, \
                                                        self.time_end, \
                                                        self.time_ag, \
                                                        self.time_point, \
                                                        self.time_interval, \
                                                        self.all_services, \
                                                        self.days, \
                                                        self.tran_modes, \
                                                        path_tree, \
                                                        self.max_cost, \
                                                        self.walking_speed, \
                                                        self.cycling_speed, \
                                                        self.constraint_date_after, \
                                                        self.debug\
                                                    )
                                                    
            self.path_indic_thread.finished.connect(self._slotDone)
            self.path_indic_thread.resultAvailable.connect(self._slotResultAvailable)
            self.path_indic_thread.start()

            
    def _slotResultAvailable(self, done, query_str): 
        if (done==True):
            s="UPDATE tempus_access.indic_catalog SET calc_time = "+str(self.time.elapsed()/1000)+" WHERE layer_name = '"+self.obj_def_name+"';"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(s+"\n")
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
            
            if (self.isosurfaces==False):
                t="SELECT count(*) FROM indic."+self.obj_def_name+" as count;"
            else:
                t="SELECT count(*) FROM indic.isosurfaces as count;"
            r=QtSql.QSqlQuery(unicode(t), self.db)
            r.next()
            
            if (r.value(0)>0): # has returned at least one row
                self.dlg.ui.Tabs.setCurrentIndex(3)
                if (self.isosurfaces==False):
                    self.refreshReq()
                    self.dlg.ui.comboBoxReq.setCurrentIndex(self.dlg.ui.comboBoxReq.findText(self.obj_def_name)) 
                    self.dlg.ui.Tabs.setCurrentIndex(4)
                else:
                    self.refreshDerivedRep()
                    self.dlg.ui.comboBoxDerivedRep.setCurrentIndex(self.dlg.ui.comboBoxDerivedRep.findText("isosurfaces"))
            
            else: # has not returned any row
                box = QMessageBox()
                box.setText(u"La requête a abouti mais n'a pas retourné de résultats. " )
                box.exec_()
        else:
            box = QMessageBox()
            if self.debug:
                box.setText(u"La requête a échoué. Rendez-vous dans le fichier 'log.txt' du plugin pour en savoir plus. ")
            else:
                box.setText(u"La requête a échoué. Cochez la case 'Ecrire dans le log', puis rendez-vous dans le fichier 'log.txt' du plugin pour en savoir plus. ")
            box.exec_()
            
            
    def _slotDone(self):
        self.timer.stop()
           
    
    def _slotPushButtonReinitCalcClicked(self):
        self.dlg.ui.comboBoxReq.setCurrentIndex(0)
        self._slotComboBoxObjTypeIndexChanged(self.dlg.ui.comboBoxObjType.currentIndex())
        self.node_indicators.setExpanded(False)
        
        self.dlg.ui.Tabs.setCurrentIndex(0)
        
        self.dlg.ui.labelElapsedTime.setText("")
            
        
    def _slotUpdateTimer(self):
        self.dlg.ui.labelElapsedTime.setText(u"Temps d'exécution : "+str(self.time.elapsed()/1000)+" secondes")
    
    
    def _slotCheckBoxVerboseStateChanged(self):
        if self.dlg.ui.checkBoxVerbose.isChecked():
            self.debug =True
        else:
            self.debug = False
    
    
    # Slots of the 1st tab
    
    def _slotComboBoxObjTypeIndexChanged(self, indexChosenLine):
        self.iface.mapCanvas().setMapTool(self.toolPan)
        self.obj_type = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("code")
        self.obj_def_name = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("def_name")

        self.modelIndic.setQuery("SELECT lib, code, col_name\
                                    FROM tempus_access.indicators\
                                    WHERE code IN \
                                    (\
                                        SELECT unnest(indic_list::integer[]) as code \
                                        FROM tempus_access.obj_type \
                                        WHERE code=" + str(self.obj_type) + "\
                                    )\
                                    ORDER BY 2", self.db
                                )
        
        layerList = [layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"Origines") or (layer.name()==u"Destinations"))]
        for lyr in layerList:
            QgsMapLayerRegistry.instance().removeMapLayer(lyr.id())
       
        if (self.obj_def_name=="stops" or self.obj_def_name=="stop_areas" or \
            self.obj_def_name=="sections" or self.obj_def_name=="trips" or \
            self.obj_def_name=="routes" or self.obj_def_name=="agencies"):
            # 1st tab
            self.dlg.ui.groupBoxPaths.setEnabled(False)
            self.dlg.ui.groupBoxPathsParameters.setEnabled(False)
            
            # 2nd tab
            self.dlg.ui.groupBoxGTFSFeeds.setEnabled(True)
            self.dlg.ui.groupBoxAgencies.setEnabled(True)
            self.dlg.ui.listViewPTModes.setEnabled(False)
            self.dlg.ui.listViewIModes.setEnabled(False)
            self.dlg.ui.listViewIModes.clearSelection()
            
            # 3rd tab
            self.dlg.ui.toolBoxDays.setEnabled(True)
            self.dlg.ui.radioButtonPreciseDate.setChecked(True)
            self.dlg.ui.radioButtonDayType.setEnabled(True)
            self.dlg.ui.toolBoxTime.setEnabled(True)
            self.dlg.ui.radioButtonTimePeriod.setEnabled(True)
            self.dlg.ui.radioButtonTimePeriod.setChecked(True)
            self.dlg.ui.radioButtonTimePoint.setEnabled(False)
            self.dlg.ui.radioButtonTimeInterval.setEnabled(False)
            self.dlg.ui.timeEditTimeInterval.setEnabled(False)
            self.dlg.ui.radioButtonAllServices.setEnabled(False)
            
            # 4th tab
            self.dlg.ui.toolBoxDisplay.setItemEnabled(1,False) # Isochron representations
        
            if (self.obj_def_name=="stops" or self.obj_def_name=="stop_areas"):
                # 1st tab
                self.dlg.ui.groupBoxPerimetre.setEnabled(True)
                # 2nd tab
                self.dlg.ui.groupBoxForcStop.setEnabled(False)
                self.dlg.ui.groupBoxForcRoute.setEnabled(True)
                
            
            elif (self.obj_def_name=="sections" or self.obj_def_name=="trips"):
                # 1st tab
                self.dlg.ui.groupBoxPerimetre.setEnabled(True)
                # 2nd tab
                self.dlg.ui.groupBoxForcStop.setEnabled(True)
                self.dlg.ui.groupBoxForcRoute.setEnabled(True)
            
            elif (self.obj_def_name=="routes"):
                # 1st tab
                self.dlg.ui.groupBoxPerimetre.setEnabled(True)
                # 2nd tab
                self.dlg.ui.groupBoxForcStop.setEnabled(True)
                self.dlg.ui.groupBoxForcRoute.setEnabled(False)
                           
            elif (self.obj_def_name=="agencies"):
                # 1st tab
                self.dlg.ui.groupBoxPerimetre.setEnabled(True)
                
                # 2nd tab
                self.dlg.ui.groupBoxAgencies.setEnabled(False)
                self.dlg.ui.groupBoxForcStop.setEnabled(True)
                self.dlg.ui.groupBoxForcRoute.setEnabled(False)
                    
        elif ((self.obj_def_name=="paths") or (self.obj_def_name=="paths_details") or \
             (self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")):
            # 1st tab
            self.dlg.ui.groupBoxPaths.setEnabled(True)
            self.dlg.ui.toolBoxPaths.setEnabled(True)
            self.dlg.ui.groupBoxPerimetre.setEnabled(False)
            
            # 2nd tab
            self.dlg.ui.groupBoxGTFSFeeds.setEnabled(True)
            self.dlg.ui.groupBoxAgencies.setEnabled(False)
            self.dlg.ui.listViewPTModes.setEnabled(True)
            self.dlg.ui.listViewIModes.setEnabled(True)
            self.dlg.ui.listViewIModes.selectAll()
            self.dlg.ui.groupBoxForcStop.setEnabled(False)
            self.dlg.ui.groupBoxForcRoute.setEnabled(False)
            
            # 3rd tab
            self.dlg.ui.radioButtonPreciseDate.setEnabled(True)
            self.dlg.ui.radioButtonPreciseDate.setChecked(True)
            self.dlg.ui.radioButtonTimePoint.setEnabled(True)
            self.dlg.ui.radioButtonTimePoint.setChecked(True)
            self._slotComboBoxTimeConstraintIndexChanged(self.dlg.ui.comboBoxTimeConstraint.currentIndex())
            
            # 4th tab
            self.dlg.ui.toolBoxDisplay.setItemEnabled(1,False) # Isochron representations
        
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details"):
                # 1st tab
                self.dlg.ui.toolBoxPaths.setCurrentIndex(0)
                self.dlg.ui.toolBoxPaths.setItemEnabled(0,True) # Paths
                self.dlg.ui.toolBoxPaths.setItemEnabled(1,False) # Paths tree
                self.dlg.ui.toolBoxPaths.setItemEnabled(2,False) # Combination of paths trees
                self.dlg.ui.groupBoxPathsParameters.setEnabled(False)
                
                # 3rd tab
                self.dlg.ui.radioButtonAllServices.setEnabled(True)
                self.dlg.ui.radioButtonTimePeriod.setEnabled(True)
                self.dlg.ui.radioButtonTimeInterval.setEnabled(True)
                self.dlg.ui.timeEditTimeInterval.setEnabled(True)
                self.dlg.ui.comboBoxTimeConstraint.setEnabled(True)
        
            elif (self.obj_def_name=="paths_tree"):

                self._slotComboBoxCombPathsTreesODIndexChanged(self.dlg.ui.comboBoxPathsTreeOD.currentIndex())
                
               # 1st tab
                self.dlg.ui.toolBoxPaths.setCurrentIndex(1)
                self.dlg.ui.toolBoxPaths.setItemEnabled(0,False) # Paths
                self.dlg.ui.toolBoxPaths.setItemEnabled(1,True) # Paths tree
                self.dlg.ui.toolBoxPaths.setItemEnabled(2,False) # Combination of paths trees
                self.dlg.ui.groupBoxPathsParameters.setEnabled(True)
                
                # 3rd tab
                self.dlg.ui.radioButtonTimePeriod.setEnabled(False)
                self.dlg.ui.radioButtonDayType.setEnabled(False)
                self.dlg.ui.comboBoxTimeConstraint.setEnabled(False)
                        
            elif (self.obj_def_name=="comb_paths_trees"):
                
                self._slotComboBoxCombPathsTreesODIndexChanged(self.dlg.ui.comboBoxCombPathsTreesOD.currentIndex())
                
                # 1st tab
                self.dlg.ui.toolBoxPaths.setCurrentIndex(2)
                self.dlg.ui.toolBoxPaths.setItemEnabled(0,False) # Paths
                self.dlg.ui.toolBoxPaths.setItemEnabled(1,False) # Paths tree
                self.dlg.ui.toolBoxPaths.setItemEnabled(2,True) # Combination of paths trees
                self.root_nodes = []
                self.dlg.ui.groupBoxPathsParameters.setEnabled(True)
                
                # 3rd tab
                self.dlg.ui.radioButtonTimePeriod.setEnabled(True)
                self.dlg.ui.radioButtonDayType.setEnabled(True)
                self.dlg.ui.radioButtonTimeInterval.setEnabled(True)
                self.dlg.ui.timeEditTimeInterval.setEnabled(True)
                self.dlg.ui.radioButtonAllServices.setEnabled(False)
                self.dlg.ui.radioButtonDayType.setEnabled(True)
                self.dlg.ui.comboBoxTimeConstraint.setEnabled(False)
                
            self.addODLayers()
            self.updateSelectedNodes()
            self.dlg.ui.listViewPTModes.selectAll()
        self.dlg.ui.listViewIndic.selectAll()
    
    
    def _slotComboBoxNodeTypeIndexChanged(self, indexChosenLine):
        s=""
        self.node_type = self.modelNodeType.record(indexChosenLine).value("mod_code")
        self.root_nodes=[]
        self.updateSelectedNodes()
        
        # Origine and destination layers are removed
        layerList = [layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"Origines") or (layer.name()==u"Destinations"))]
        for lyr in layerList:
            QgsMapLayerRegistry.instance().removeMapLayer(lyr.id())
        
        
        if (self.node_type==0): # Stops area
            s="SELECT stop_name || '-' || stop_id as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTSources) + ") ORDER BY 1"
            self.modelNode.setQuery(unicode(s), self.db)
            
        elif (self.node_type==1): # Road nodes
            s="SELECT id FROM tempus.road_node ORDER BY 1"
            self.modelNode.setQuery(unicode(s), self.db)
        
        self.addODLayers()
        self.updateSelectedNodes()
        
        # Corresponding time options are updated
        if (self.node_type==0) and ((self.obj_def_name=="paths") or (self.obj_def_name=="paths_details")):
            self.dlg.ui.radioButtonAllServices.setEnabled(True)
        else:
            self.dlg.ui.radioButtonAllServices.setEnabled(False)
            self.dlg.ui.radioButtonTimeInterval.setChecked(True)
        
        self.iface.mapCanvas().refreshMap()

    
    def _slotClickPoint(self, point, button): # 3rd argument gives the mouse button used for the clic 
        s=""
        i=0
        if (self.node_type==0): # Stop areas
            s="SELECT id as id, st_distance(st_transform(geom, 2154), st_setSRID(st_makepoint("+str(point.x())+", "+str(point.y())+"), 2154)) as dist \
               FROM tempus_gtfs.stops \
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+") \
               ORDER BY 2 \
               LIMIT 1"
            i=4
        elif (self.node_type==1): # Road nodes
            s="SELECT id, st_distance(st_transform(geom, 2154), st_setSRID(st_makepoint("+str(point.x())+", "+str(point.y())+"), 2154)) as dist \
               FROM tempus.road_node \
               ORDER BY 2 \
               LIMIT 1"
        
        q=QtSql.QSqlQuery(unicode(s), self.db)
        q.next()
        
        if (self.chooseOrig == True):
            self.dlg.ui.comboBoxOrig.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, q.value(0), 1)[0].row())
        elif (self.chooseDest == True):
            self.dlg.ui.comboBoxDest.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, q.value(0), 1)[0].row())
        elif (self.choosePathsTreeRoot == True):
            self.dlg.ui.comboBoxPathsTreeRootNode.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, q.value(0), 1)[0].row())
        elif (self.choosePathsTreesRoots == True):
            self.root_nodes.append(q.value(0))
        
        self.updateSelectedNodes()
    
    
    def addODLayers(self):
        uriOrigines=QgsDataSourceURI()
        uriOrigines.setConnection(self.db.hostName(), str(self.db.port()), self.db.databaseName(), self.db.userName(), self.db.password())
        uriDestinations=QgsDataSourceURI()
        uriDestinations.setConnection(self.db.hostName(), str(self.db.port()), self.db.databaseName(), self.db.userName(), self.db.password())
        
        subset_o = "id is null"
        subset_d = "id is null"  
        
        if (self.node_type==0): # Stops area
            uriOrigines.setDataSource("tempus_gtfs", "stops", "geom", subset_o, "id") 
            uriDestinations.setDataSource("tempus_gtfs", "stops", "geom", subset_d, "id")
        elif (self.node_type==1): # Road nodes
            uriOrigines.setDataSource("tempus", "road_node", "geom", subset_o, "id") 
            uriDestinations.setDataSource("tempus", "road_node", "geom", subset_d, "id")
        
        layer = QgsVectorLayer(uriOrigines.uri(), u"Origines", "postgres")
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_indicators.insertChildNode(0, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True) 
            layer.loadNamedStyle(self.styles_dir + '/origines.qml')
        layer = QgsVectorLayer(uriDestinations.uri(), u"Destinations", "postgres")
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_indicators.insertChildNode(1, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            layer.loadNamedStyle(self.styles_dir + '/destinations.qml')
    
       
    def updateSelectedNodes(self):
        s=""
        t=""
        subset_o="id is null"
        subset_d="id is null"
        if (self.obj_def_name=="paths") or (self.obj_def_name=="paths_details"):
            subset_o = "id = "+str(self.modelNode.record(self.dlg.ui.comboBoxOrig.currentIndex()).value("id"))
            subset_d = "id = "+str(self.modelNode.record(self.dlg.ui.comboBoxDest.currentIndex()).value("id"))
        elif (self.obj_def_name=="paths_tree"):
            if (self.dlg.ui.comboBoxPathsTreeOD.currentText()=="Origine"):
                subset_o = "id = "+str(self.modelNode.record(self.dlg.ui.comboBoxPathsTreeRootNode.currentIndex()).value("id"))
            if (self.dlg.ui.comboBoxPathsTreeOD.currentText()=="Destination"):
                subset_d = "id = "+str(self.modelNode.record(self.dlg.ui.comboBoxPathsTreeRootNode.currentIndex()).value("id"))
        elif (self.obj_def_name=="comb_paths_trees"):
            s="ARRAY[id]::bigint[] <@ ARRAY"+str(self.root_nodes)+"::bigint[]"
            if (self.dlg.ui.comboBoxCombPathsTreesOD.currentText()=="Origine(s)"):
                subset_o = s
            elif (self.dlg.ui.comboBoxCombPathsTreesOD.currentText()=="Destination(s)"):
                subset_d = s
            if (self.node_type==0): # Stop areas
                t="SELECT stop_name || '-' || stop_id as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops \
                   WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTSources) + ") AND ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"\
                   ORDER BY 1"
            elif (self.node_type==1): # Road nodes
                t="SELECT id FROM tempus.road_node WHERE ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"::bigint[]\
                   ORDER BY 1"
            self.modelSelectedNodes.setQuery(unicode(t), self.db)
            
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
            if (layer.name()=="Origines"):
                layer.setSubsetString(subset_o)
            elif (layer.name()=="Destinations"):
                layer.setSubsetString(subset_d)
    
    
    def _slotComboBoxOrigIndexChanged(self, indexChosenLine):
        self.from_node = self.modelNode.record(indexChosenLine).value("id")
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
            if (layer.name()=="Origines"):
                layer.setSubsetString("id = "+str(self.modelNode.record(indexChosenLine).value("id")))
    
    
    def _slotComboBoxDestIndexChanged(self, indexChosenLine):
        self.to_node = self.modelNode.record(indexChosenLine).value("id")
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems():        
            if (layer.name()=="Destinations"):
                layer.setSubsetString("id = "+str(self.modelNode.record(indexChosenLine).value("id")))
    
    
    def _slotComboBoxPathsTreeRootNodeIndexChanged(self, indexChosenLine):
        self.root_node = self.modelNode.record(indexChosenLine).value("id")
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
            if ((layer.name()=="Origines") and (self.dlg.ui.comboBoxPathsTreeOD.currentText()=="Origine")) or ((layer.name()=="Destinations") and (self.dlg.ui.comboBoxPathsTreeOD.currentText()=="Destination")):
                layer.setSubsetString("id = "+str(self.modelNode.record(indexChosenLine).value("id")))
    
    
    def _slotPushButtonChooseOrigOnMapClicked(self):
        self.iface.mapCanvas().setMapTool(self.clickTool)
        self.chooseOrig = True
        self.chooseDest = False
        self.choosePathsTreeRoot = False
        self.choosePathsTreesRoots = False
    
    
    def _slotPushButtonChooseDestOnMapClicked(self):
        self.iface.mapCanvas().setMapTool(self.clickTool)
        self.chooseOrig = False
        self.chooseDest = True
        self.choosePathsTreeRoot = False
        self.choosePathsTreesRoots = False
    
    
    def _slotPushButtonChoosePathsTreeRootOnMapClicked(self):
        self.iface.mapCanvas().setMapTool(self.clickTool)
        self.chooseOrig = False
        self.chooseDest = False
        self.choosePathsTreeRoot = True
        self.choosePathsTreesRoots = False
    
    
    def _slotPushButtonChoosePathsTreesRootsOnMapClicked(self):
        self.iface.mapCanvas().setMapTool(self.clickTool)
        self.chooseOrig = False
        self.chooseDest = False
        self.choosePathsTreeRoot = False
        self.choosePathsTreesRoots = True
    
    
    def _slotPushButtonRemovePathsTreesRootsClicked(self):
        for item in self.dlg.ui.listViewNodes.selectionModel().selectedRows():
            self.root_nodes.remove(self.modelSelectedNodes.record(item.row()).value("id"))
        
        if (self.modelNodeType.record(self.dlg.ui.comboBoxNodeType.currentIndex()).value("mod_code")==0): # Stop areas
            s="SELECT stop_name || '-' || stop_id as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops \
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTSources) + ") AND ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"\
               ORDER BY 1"
        elif (self.modelNodeType.record(self.dlg.ui.comboBoxNodeType.currentIndex()).value("mod_code")==1): # Road nodes
            s="SELECT id FROM tempus.road_node WHERE ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"\
               ORDER BY 1"
        self.modelSelectedNodes.setQuery(unicode(s), self.db)
        
        s="ARRAY[id] <@ ARRAY"+str(self.root_nodes)
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
            if (layer.name()=="Origines") and (self.dlg.ui.comboBoxCombPathsTreesOD.currentText()=="Origine(s)"):
                layer.setSubsetString(s)
            elif (layer.name()=="Destinations") and (self.dlg.ui.comboBoxCombPathsTreesOD.currentText()=="Destination(s)"):
                layer.setSubsetString(s)
        
        
    def _slotComboBoxPathsTreeODIndexChanged(self, indexChosenLine):
        if (indexChosenLine == 0): # Origin
            self.dlg.ui.comboBoxTimeConstraint.setCurrentIndex(self.dlg.ui.comboBoxTimeConstraint.findText(u"Sur l'heure de départ"))
        elif (indexChosenLine == 1): # Destination
            self.dlg.ui.comboBoxTimeConstraint.setCurrentIndex(self.dlg.ui.comboBoxTimeConstraint.findText(u"Sur l'heure d'arrivée"))
        
        self.updateSelectedNodes()
        
        
    def _slotComboBoxCombPathsTreesODIndexChanged(self, indexChosenLine):
        if (indexChosenLine == 0): # Origins
            self.dlg.ui.comboBoxTimeConstraint.setCurrentIndex(self.dlg.ui.comboBoxTimeConstraint.findText(u"Sur l'heure de départ"))
        elif (indexChosenLine == 1): # Destinations
            self.dlg.ui.comboBoxTimeConstraint.setCurrentIndex(self.dlg.ui.comboBoxTimeConstraint.findText(u"Sur l'heure d'arrivée"))
        
        self.root_nodes = []
        self.updateSelectedNodes()
        
        
    def _slotComboBoxAreaTypeIndexChanged(self, indexChosenLine):
        self.area_type = self.modelAreaType.record(self.dlg.ui.comboBoxAreaType.currentIndex()).value("code")
        
        if (indexChosenLine>0):
            s="SELECT lib, char_id FROM tempus_access.area_type"+str(self.modelAreaType.record(indexChosenLine).value("code"))+" \
                UNION \
                SELECT '', '-1' \
                ORDER BY 1"
        else:
            s="SELECT '' as lib, '-1' as char_id"
        self.modelArea.setQuery(unicode(s), self.db)
        
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems():
            for i in range(0,self.modelAreaType.rowCount()):
                if ((self.modelAreaType.record(i).value("code")==self.modelAreaType.record(self.dlg.ui.comboBoxAreaType.currentIndex()).value("code")) and (layer.name()==self.modelAreaType.record(i).value("lib"))):
                    self.iface.legendInterface().setLayerVisible(layer, True)
                elif (layer.name()==self.modelAreaType.record(i).value("lib")):
                    self.iface.legendInterface().setLayerVisible(layer, False)
    
    
    def _slotComboBoxAreaIndexChanged(self):
        from_proj = QgsCoordinateReferenceSystem()
        from_proj.createFromSrid(4326)
        to_proj = QgsCoordinateReferenceSystem()
        to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
        crd=QgsCoordinateTransform(from_proj, to_proj)
        
        self.area_id = self.modelArea.record(self.dlg.ui.comboBoxArea.currentIndex()).value("char_id")
        
        # Filtering map display on the area layer
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems():
            for i in range(0,self.modelAreaType.rowCount()):
                if ((self.modelAreaType.record(i).value("code")==self.modelAreaType.record(self.dlg.ui.comboBoxAreaType.currentIndex()).value("code")) and (layer.name()==self.modelAreaType.record(i).value("lib"))):
                    self.iface.legendInterface().setLayerVisible(layer, True)
                    if (self.area_id == "-1"):
                        layer.setSubsetString("")
                    elif (self.area_id != None):
                        layer.setSubsetString("char_id = '" + str(self.modelArea.record(self.dlg.ui.comboBoxArea.currentIndex()).value("char_id")) + "'")
                        self.iface.mapCanvas().setExtent(crd.transform(layer.extent()))

                elif (layer.name()==self.modelAreaType.record(i).value("lib")):
                    self.iface.legendInterface().setLayerVisible(layer, False)
                    layer.setSubsetString("")
        
        self.iface.mapCanvas().refreshMap()
    
    
    def _slotPushButtonInvertODClicked(self):
        index_orig=self.dlg.ui.comboBoxOrig.currentIndex()
        self.dlg.ui.comboBoxOrig.setCurrentIndex(self.dlg.ui.comboBoxDest.currentIndex())
        self.dlg.ui.comboBoxDest.setCurrentIndex(index_orig)
    
    
    # Slots of the 2nd tab
    
    def _slotListViewGTFSFeedsSelectionChanged(self, selected, deselected):
        self.PTSources = []
        for item in self.dlg.ui.listViewGTFSFeeds.selectionModel().selectedRows():
            self.PTSources.append(self.modelPTSources.record(item.row()).value("id"))
        
        # Update of the dialog widgets with the selected feeds
        
        if (len(self.PTSources)>0):
            # Agencies
            s="SELECT feed_id, agency_id, agency_name, id \
               FROM tempus_gtfs.agency \
               WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTSources) + ") ORDER BY feed_id, agency_id"
            self.modelAgencies.setQuery(unicode(s), self.db)
            self.dlg.ui.tableViewAgencies.selectAll()
            self.dlg.ui.tableViewAgencies.resizeRowsToContents()
            self.dlg.ui.tableViewAgencies.resizeColumnsToContents()
            self.dlg.ui.tableViewAgencies.setColumnHidden(3, True)
            
            # PT modes
            s="SELECT name, id, gtfs_feed_id, gtfs_route_type \
               FROM tempus.transport_mode \
               WHERE ARRAY[gtfs_feed_id]::integer[] <@ ARRAY" + str(self.PTSources) 
            self.modelPTModes.setQuery(unicode(s), self.db)
            self.dlg.ui.listViewPTModes.selectAll()
            
            # From and to nodes for paths
            self._slotComboBoxNodeTypeIndexChanged(self.dlg.ui.comboBoxNodeType.currentIndex())        
            
            # PT stops
            s="SELECT DISTINCT stop_name || '-' || stop_id as stop, id, feed_id, stop_id, stop_name \
               FROM tempus_gtfs.stops\
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTSources) + ")\
               UNION SELECT '', -1, '', '', ''\
               ORDER BY 1"
            self.modelStop.setQuery(unicode(s), self.db)
            
            # PT routes
            s="SELECT route_long_name as route_name, id, feed_id, route_id \
               FROM tempus_gtfs.routes \
               WHERE  feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTSources) + ")\
               UNION SELECT '', -1, null, null ORDER BY 1; "
            self.dlg.ui.comboBoxForcRoute.setModelColumn(0)
            self.modelRoute.setQuery(s, self.db)
            
            # PT sections
            s="SELECT DISTINCT id, stop_from, stop_to \
                 FROM tempus_gtfs.sections \
                 WHERE ARRAY[feed_id] <@ ARRAY" + str(self.PTSources) + "\
                 UNION SELECT -1, null, null ORDER BY 1;"
            
            # Calendar and date edition widgets : updated with the minimum and maximum dates in the selected data sources
            if (len(self.dlg.ui.listViewGTFSFeeds.selectionModel().selection().indexes())>0):
                s="SELECT min(date), max(date) \
                   FROM tempus_gtfs.calendar_dates \
                   WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTSources) + ")"
                q=QtSql.QSqlQuery(unicode(s), self.db)
                q.next()
                self.dlg.ui.calendarWidget.setDateRange(q.value(0), q.value(1))
                self.dlg.ui.calendarWidget.setSelectedDate(q.value(0))
                self.dlg.ui.dateEditPerStart.setDate(q.value(0))
                self.dlg.ui.dateEditPerEnd.setDate(q.value(1))
                   
            # Filter of map display on the selected feeds
            from_proj = QgsCoordinateReferenceSystem()
            from_proj.createFromSrid(4326)
            to_proj = QgsCoordinateReferenceSystem()
            to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
            crd=QgsCoordinateTransform(from_proj, to_proj)
            
            layerList = [lyr for lyr in QgsMapLayerRegistry.instance().mapLayers().values() if lyr.name() == u"Sections"]
            if layerList: 
                layerList[0].setSubsetString("ARRAY[feed_id] <@ ARRAY"+str(self.PTSources))
                if (layerList[0].extent().isEmpty()==False): 
                    self.iface.mapCanvas().setExtent(crd.transform(layerList[0].extent()))
            
            layerList = [layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"Itinéraires de ligne par mode") \
                                                                                                or (layer.name()==u"Arrêts") or (layer.name()==u"Arrêts par mode") \
                                                                                                or (layer.name()=="Sections par mode"))]
            for lyr in layerList:
                lyr.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTSources)+")")
            self.iface.mapCanvas().refreshMap()
    

    # Slot of the 3rd tab
    
    def _slotRadioButtonPreciseDateToggled(self):
        if (self.dlg.ui.radioButtonPreciseDate.isChecked()):
            self.dlg.ui.toolBoxDays.setCurrentIndex(0)
            self.dlg.ui.toolBoxDays.setItemEnabled(0,True)
            self.dlg.ui.toolBoxDays.setItemEnabled(1,False)
            self.dlg.ui.comboBoxDayAg.setCurrentIndex(0)
    
    
    def _slotRadioButtonDayTypeToggled(self):
        if (self.dlg.ui.radioButtonDayType.isChecked()):
            self.dlg.ui.toolBoxDays.setCurrentIndex(1)
            self.dlg.ui.toolBoxDays.setItemEnabled(0,False)
            self.dlg.ui.toolBoxDays.setItemEnabled(1,True)
            self.dlg.ui.comboBoxDayAg.setCurrentIndex(0)
    

    def _slotRadioButtonTimePointToggled(self):
        if (self.dlg.ui.radioButtonTimePoint.isChecked()):
            self.dlg.ui.toolBoxTime.setCurrentIndex(0)
            self.dlg.ui.toolBoxTime.setItemEnabled(0,True)
            self.dlg.ui.toolBoxTime.setItemEnabled(1,False)
    
    
    def _slotRadioButtonTimePeriodToggled(self):
        if (self.dlg.ui.radioButtonTimePeriod.isChecked()):
            self.dlg.ui.toolBoxTime.setCurrentIndex(1)
            self.dlg.ui.toolBoxTime.setItemEnabled(0,False)
            self.dlg.ui.toolBoxTime.setItemEnabled(1,True)
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details" or self.obj_def_name=="comb_paths_trees"):
                self.dlg.ui.radioButtonTimeInterval.setEnabled(True)
                self.dlg.ui.radioButtonTimeInterval.setChecked(True)
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details") and (self.node_type == 0):
                self.dlg.ui.radioButtonAllServices.setEnabled(True)
            else:
                self.dlg.ui.radioButtonAllServices.setEnabled(False)                
            self.dlg.ui.comboBoxTimeAg.setCurrentIndex(0)
    
    
    def _slotComboBoxTimeConstraintIndexChanged(self, indexChosenLine):
        if (indexChosenLine==0): # Sur l'heure de départ
            self.constraint_date_after=True
            self.dlg.ui.labelTimeConstraint.setText(u"Partir après")
            self.dlg.ui.labelFromTime.setText(u"Départ entre")
        elif (indexChosenLine==1): # Sur l'heure d'arrivée
            self.constraint_date_after=False
            self.dlg.ui.labelTimeConstraint.setText("Arriver avant")
            self.dlg.ui.labelFromTime.setText(u"Arrivée entre")
    
    
    def _slotRadioButtonTimeIntervalToggled(self):
        if (self.dlg.ui.radioButtonTimeInterval.isChecked()):
            self.dlg.ui.timeEditTimeInterval.setEnabled(True)
        else:
            self.dlg.ui.timeEditTimeInterval.setEnabled(False)
    
    
    
    # Slots of the 4th tab
    
    def _slotComboBoxReqIndexChanged(self, indexChosenLine):
        self.parent_layer=""
        if (indexChosenLine == 0):
            # General interface
            self.dlg.ui.pushButtonIndicCalculate.setEnabled(True)
            self.dlg.ui.pushButtonReinitCalc.setEnabled(True)
            self.comments = ""
            
            # 1st tab
            self.dlg.ui.groupBoxObjType.setEnabled(True)
            self.dlg.ui.groupBoxIndicators.setEnabled(True)
            self.dlg.ui.toolBoxPaths.setEnabled(False)
            self.dlg.ui.groupBoxPerimetre.setEnabled(True)
            self.updateSelectedNodes()
            
            # 2nd tab
            self.dlg.ui.groupBoxGTFSFeeds.setEnabled(True)
            self.dlg.ui.groupBoxAgencies.setEnabled(True)
            self.dlg.ui.groupBoxTransportModes.setEnabled(True)
            self.dlg.ui.groupBoxForcStop.setEnabled(True)
            self.dlg.ui.groupBoxForcRoute.setEnabled(True)
            
            # 3rd tab
            self.dlg.ui.toolBoxDays.setEnabled(True)
            self.dlg.ui.toolBoxTime.setEnabled(True)
            self.dlg.ui.radioButtonTimePoint.setEnabled(False)
            
            # 4th tab
            
            self.dlg.ui.groupBoxSize.setEnabled(False)
            self.dlg.ui.groupBoxColor.setEnabled(False)
            self.dlg.ui.toolBoxDisplay.setItemEnabled(1, False)
            self.dlg.ui.pushButtonReqDisplay.setEnabled(False)
            self.dlg.ui.pushButtonReqRename.setEnabled(False)
            self.dlg.ui.pushButtonReqDelete.setEnabled(False)
            self.dlg.ui.pushButtonSaveComments.setEnabled(False)
            self.dlg.ui.comboBoxPathID.setEnabled(False)
            
            self.dlg.ui.textEditComments.setPlainText("")  
                    
        elif (indexChosenLine > 0):
            # 1st tab
            #####
            # "obj_type" field
            self.dlg.ui.comboBoxObjType.setCurrentIndex(self.modelObjType.match(self.modelObjType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("obj_type"))[0].row())
            self.obj_def_name = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("def_name")
                        
            # Disables the groupBox since they should not be modified when an already calculated indicator is displayed
            self.dlg.ui.groupBoxObjType.setEnabled(False)
            self.dlg.ui.groupBoxPaths.setEnabled(False)
            self.dlg.ui.groupBoxIndicators.setEnabled(False)
            self.dlg.ui.groupBoxPerimetre.setEnabled(False)
            self.dlg.ui.pushButtonIndicCalculate.setEnabled(False)
            
            # "area_type" and "areas" fields
            if (self.modelReq.record(indexChosenLine).isNull("area_type")==True):
                self.dlg.ui.comboBoxAreaType.setCurrentIndex(0)
            else:
                self.dlg.ui.comboBoxAreaType.setCurrentIndex(self.modelAreaType.match(self.modelAreaType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("area_type"))[0].row())
            
            self.dlg.ui.comboBoxArea.setCurrentIndex(0)
            if (self.modelReq.record(indexChosenLine).isNull("areas")==False):
                for char_id in ((str(self.modelReq.record(indexChosenLine).value("areas"))).translate(None, "{}").split(",")):
                    self.dlg.ui.comboBoxArea.setCurrentIndex(self.modelArea.match(self.modelArea.index(0,1), 0, char_id)[0].row())
            
            # "indics" field
            for indic in ((str(self.modelReq.record(indexChosenLine).value("indics"))).translate(None, "{}").split(",")):
                row = self.modelIndic.match(self.modelIndic.index(0,1), 0, indic, 1)[0].row()
                self.dlg.ui.listViewIndic.selectionModel().select(self.modelIndic.index(row,0), QItemSelectionModel.Select)
            
            # origin and destination nodes
            if (self.modelReq.record(indexChosenLine).isNull("node_type")==False):
                self.node_type=self.modelReq.record(indexChosenLine).value("node_type")
                self.dlg.ui.comboBoxNodeType.setCurrentIndex(self.modelNodeType.match(self.modelNodeType.index(0,1), 0, self.node_type)[0].row())
                i=0
                if (self.node_type==0): # Stop areas
                    i=4
            
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details"):
                if (self.modelReq.record(indexChosenLine).isNull("o_node")==False) and (self.modelReq.record(indexChosenLine).isNull("d_node")==False):
                    self.dlg.ui.comboBoxOrig.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("o_node"),1)[0].row())
                    self.dlg.ui.comboBoxDest.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("d_node"),1)[0].row())
                        
            if (self.obj_def_name=="paths_tree"):
                if (self.modelReq.record(indexChosenLine).isNull("o_node")==False):
                    self.dlg.ui.comboBoxPathsTreeRootNode.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("o_node"),1)[0].row())
                    self.dlg.ui.comboBoxPathsTreeOD.setCurrentIndex(0)
                elif (self.modelReq.record(indexChosenLine).isNull("d_node")==False):
                    self.dlg.ui.comboBoxPathsTreeRootNode.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("d_node"),1)[0].row())
                    self.dlg.ui.comboBoxPathsTreeOD.setCurrentIndex(1)
            
                        
            if (self.obj_def_name=="comb_paths_trees"):
                if (self.modelReq.record(indexChosenLine).isNull("nodes_ag")==False):
                    self.nodes_ag = self.modelReq.record(indexChosenLine).value("nodes_ag")
                    self.dlg.ui.comboBoxNodeAg.setCurrentIndex(self.modelAgreg.match(self.modelAgreg.index(0,1), 0, self.nodes_ag)[0].row())
                else:
                    self.dlg.ui.comboBoxNodeAg.setCurrentIndex(0)
                if (self.modelReq.record(indexChosenLine).isNull("o_nodes")==False):
                    nodes=self.modelReq.record(indexChosenLine).value("o_nodes")
                elif (self.modelReq.record(indexChosenLine).isNull("d_nodes")==False):
                    nodes=self.modelReq.record(indexChosenLine).value("d_nodes")
                
                self.root_nodes=[]
                for node in ((str(nodes)).translate(None, "{}").split(",")):
                    self.root_nodes.append(node)
                self.updateSelectedNodes()
            
            # 2nd tab
            #####
            self.dlg.ui.groupBoxGTFSFeeds.setEnabled(False)
            self.dlg.ui.groupBoxAgencies.setEnabled(False)
            self.dlg.ui.groupBoxTransportModes.setEnabled(False)
            self.dlg.ui.groupBoxForcStop.setEnabled(False)
            self.dlg.ui.groupBoxForcRoute.setEnabled(False)
                        
            # "stop" field
            if (self.modelReq.record(indexChosenLine).isNull("stop")==False):
                self.dlg.ui.comboBoxForcStop.setCurrentIndex(self.modelStop.match(self.modelStop.index(0,1), 0, self.modelReq.record(indexChosenLine).value("stop"))[0].row())
            
            # "route" field
            if (self.modelReq.record(indexChosenLine).isNull("route")==False):
                self.dlg.ui.comboBoxForcRoute.setCurrentIndex(self.modelRoute.match(self.modelRoute.index(0,1), 0, self.modelReq.record(indexChosenLine).value("route"))[0].row())
            
            # "agencies" field
            if (self.modelReq.record(indexChosenLine).isNull("agencies")==False):
                for i in ((str(self.modelReq.record(indexChosenLine).value("agencies"))).translate(None, "{}").split(",")):
                    row = self.modelAgencies.match(self.modelAgencies.index(0,3), 0, i, 1)[0].row()
                    self.dlg.ui.tableViewAgencies.selectionModel().select(self.modelAgencies.index(row,0), QItemSelectionModel.Select)
            else:
                self.dlg.ui.tableViewAgencies.clearSelection()
            
            # "gtfs_feeds" field
            if (self.modelReq.record(indexChosenLine).isNull("gtfs_feeds")==False):
                for feed in ((str(self.modelReq.record(indexChosenLine).value("gtfs_feeds"))).translate(None, "{}").split(",")):
                    row = self.modelPTSources.match(self.modelIndic.index(0,1), 0, feed, 1)[0].row()
                    self.dlg.ui.listViewGTFSFeeds.selectionModel().select(self.modelPTSources.index(row,0), QItemSelectionModel.Select)
            
            # "pt_modes" field
            if (self.modelReq.record(indexChosenLine).isNull("pt_modes")==False):
                for i in ((str(self.modelReq.record(indexChosenLine).value("pt_modes"))).translate(None, "{}").split(",")):
                    if (i!="NULL"):
                        row = self.modelPTModes.match(self.modelPTModes.index(0,1), 0, i, 1)[0].row()
                        self.dlg.ui.listViewPTModes.selectionModel().select(self.modelPTModes.index(row,0), QItemSelectionModel.Select)
            
            # "i_modes" field
            for i in ((str(self.modelReq.record(indexChosenLine).value("i_modes"))).translate(None, "{}").split(",")):
                if (i!="NULL"):
                    row = self.modelIModes.match(self.modelIModes.index(0,1), 0, i, 1)[0].row()
                    self.dlg.ui.listViewIModes.selectionModel().select(self.modelIModes.index(row,0), QItemSelectionModel.Select)
            
            # 3rd tab
            #####
            self.dlg.ui.toolBoxDays.setEnabled(False)
            self.dlg.ui.toolBoxTime.setEnabled(False)
            self.dlg.ui.radioButtonTimePoint.setEnabled(False)
            
            # "day" / "day_type", "per_start", "per_end", "day_ag" fields
            if (self.modelReq.record(indexChosenLine).isNull("day_type")==True):
                for day in ((str(self.modelReq.record(indexChosenLine).value("days"))).translate(None, "{}").split(",")):
                    self.dlg.ui.calendarWidget.setSelectedDate(QDate.fromString(day, "yyyy-MM-dd"))
                self.dlg.ui.radioButtonPreciseDate.setChecked(True)
            else:
                self.dlg.ui.comboBoxDayType.setCurrentIndex(self.modelDayType.match(self.modelDayType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("day_type"))[0].row())
                self.dlg.ui.radioButtonDayType.setChecked(True)
                self.dlg.ui.dateEditPerStart.setDate(self.modelReq.record(indexChosenLine).value("per_start"))
                self.dlg.ui.dateEditPerEnd.setDate(self.modelReq.record(indexChosenLine).value("per_end"))
                self.dlg.ui.comboBoxPerType.setCurrentIndex(self.modelPerType.match(self.modelPerType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("per_type"))[0].row())
                self.dlg.ui.comboBoxDayAg.setCurrentIndex(self.modelAgreg.match(self.modelAgreg.index(0,1), 0, self.modelReq.record(indexChosenLine).value("day_ag"))[0].row())
            
            
            # "time_start", "time_end", "time_ag", "time_point" fields
            if (self.modelReq.record(indexChosenLine).isNull("time_start")==False):
                self.dlg.ui.timeEditTimeStart.setTime(self.modelReq.record(indexChosenLine).value("time_start"))
                self.dlg.ui.radioButtonTimePeriod.setChecked(True)
                self.dlg.ui.timeEditTimeEnd.setTime(self.modelReq.record(indexChosenLine).value("time_end"))
            elif (self.modelReq.record(indexChosenLine).isNull("constraint_date_after")==False):
                self.radioButtonTimePoint.setChecked(True)
                self.timeEditTimePoint.setTime(self.modelReq.record(indexChosenLine).value("time_point"))
                self.comboBoxTimePointConstraint.setCurrentIndex(self.modelTimeConst.match(self.modelTimeConst.index(0,1), 0, self.modelReq.record(indexChosenLine).value("time_const"))[0].row())
            
            # 4th tab
            #####
            
            if ((self.obj_def_name== "stop_areas") or (self.obj_def_name == "stops") or (self.obj_def_name == "sections") or (self.obj_def_name=="trips")):
                self.dlg.ui.groupBoxGeoQuery.setEnabled(True)
                self.dlg.ui.groupBoxColor.setEnabled(True)
                self.dlg.ui.groupBoxSize.setEnabled(True)
                self.dlg.ui.comboBoxPathID.setEnabled(False)
                self.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "paths") or (self.obj_def_name == "paths_details")):
                self.dlg.ui.groupBoxGeoQuery.setEnabled(False)
                self.dlg.ui.comboBoxPathID.setEnabled(True)
                if (self.obj_def_name=="paths"):
                    s="(SELECT 'Tous' as gid, -1 as gid_order) UNION (SELECT gid::character varying, gid FROM indic."+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+") ORDER BY gid_order"
                elif (self.obj_def_name=="paths_details"):
                    s="(SELECT 'Tous' as path_id, -1 as path_id_order) UNION (SELECT distinct path_id::character varying, path_id FROM indic."+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+") ORDER BY path_id_order"
                self.modelPathID.setQuery(unicode(s), self.db)
                self.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "routes") or (self.obj_def_name == "agencies")):
                self.dlg.ui.groupBoxGeoQuery.setEnabled(False)
                self.dlg.ui.comboBoxPathID.setEnabled(False)
                self.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "paths_tree") or (self.obj_def_name == "comb_paths_trees")):
                self.dlg.ui.groupBoxGeoQuery.setEnabled(True)
                self.dlg.ui.groupBoxColor.setEnabled(True)
                self.dlg.ui.groupBoxSize.setEnabled(True)
                self.dlg.ui.comboBoxPathID.setEnabled(False)
                # Update available derived surface representations
                self.dlg.ui.toolBoxDisplay.setItemEnabled(1,True)
                self.parent_layer = self.dlg.ui.comboBoxReq.currentText()
                self.refreshDerivedRep()             
                self._slotComboBoxDerivedRepIndexChanged(0)
            
            self.dlg.ui.pushButtonReqDisplay.setEnabled(True)
            self.dlg.ui.pushButtonReqRename.setEnabled(True)
            self.dlg.ui.pushButtonReqDelete.setEnabled(True)
            self.dlg.ui.pushButtonSaveComments.setEnabled(True)
            
            # Update color and size indicators
            self.updateReqIndicators()
            
            
            # Display comments of the current layer
            s="SELECT coalesce(pg_catalog.obj_description((SELECT 'indic."+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"'::regclass::oid)), '');"
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.dlg.ui.textEditComments.setPlainText(q.value(0))  
    
    
    def _slotComboBoxPathIDIndexChanged(self, indexChosenLine):
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
                if (layer.name()==self.dlg.ui.comboBoxReq.currentText()):
                    if (self.dlg.ui.comboBoxPathID.currentText()!="Tous" and self.dlg.ui.comboBoxPathID.currentText()!=""):
                        if (self.obj_def_name=="paths"):
                            layer.setSubsetString("gid = "+self.dlg.ui.comboBoxPathID.currentText())
                        elif (self.obj_def_name=="paths_details"):
                            layer.setSubsetString("path_id = "+self.dlg.ui.comboBoxPathID.currentText())
                    else:
                        layer.setSubsetString("")
        
    
    def _slotPushButtonReqDeleteClicked(self):
        ret = QMessageBox.question(self.dlg, "TempusAccess", u"La requête courante va être supprimée. \n Êtes vous certain(e) de vouloir faire cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)
        if (ret == QMessageBox.Ok):
            for layer in self.node_indicators.findLayers():
                if (layer.name()==self.dlg.ui.comboBoxReq.currentText()):
                    QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
            
            for i in range(0, self.modelDerivedRep.rowCount()):
                s="DROP TABLE indic."+self.modelDerivedRep.record(i).value(0)+";"
                if self.debug:
                    with open(self.plugin_dir+"/log.txt", "a") as log_file:
                        log_file.write(s+"\n")
                q=QtSql.QSqlQuery(self.db)
                q.exec_(unicode(s))
            
            s="DROP TABLE indic."+self.dlg.ui.comboBoxReq.currentText()+";\
            DELETE FROM tempus_access.indic_catalog WHERE layer_name = '"+self.dlg.ui.comboBoxReq.currentText()+"' OR parent_layer = '"+self.dlg.ui.comboBoxReq.currentText()+"';"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(s+"\n")
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
            self.refreshReq()
        
        
    def _slotPushButtonReqRenameClicked(self):
        old_name = self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")
        new_name = self.dlg.ui.comboBoxReq.currentText()
        s="ALTER TABLE indic."+old_name+" RENAME TO "+new_name+";\
        UPDATE tempus_access.indic_catalog SET layer_name = '"+new_name+"' WHERE layer_name = '"+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"';\
        UPDATE tempus_access.indic_catalog SET parent_layer = '"+new_name+"' WHERE parent_layer = '"+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"';\
        ALTER TABLE indic."+new_name+"\
        RENAME CONSTRAINT "+old_name+"_pkey TO "+new_name+"_pkey";
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(s+"\n")
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
        
        for layer in self.node_indicators.findLayers():
            if (layer.name()==old_name):
                QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
        
        self.refreshReq()
        
        self.dlg.ui.comboBoxReq.setCurrentIndex(self.modelReq.match(self.modelReq.index(0,0), 0, new_name)[0].row())

        
    def _slotPushButtonSaveCommentsClicked(self):
        s="COMMENT ON TABLE indic."+self.modelReq.record(self.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+" IS '"+unicode(self.dlg.ui.textEditComments.toPlainText())+"';"
        
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
    
    
    def _slotComboBoxSizeIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT coalesce(min("+self.modelSizeIndic.record(indexChosenLine).value("col_name")+"), 0), coalesce(max("+self.modelSizeIndic.record(indexChosenLine).value("col_name")+"), 0) FROM indic."+self.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.dlg.ui.spinBoxSizeIndicMinValue.setEnabled(True)
            self.dlg.ui.spinBoxSizeIndicMaxValue.setEnabled(True) 
            self.dlg.ui.spinBoxSizeIndicMinValue.setValue(max(0,q.value(0)-1))
            self.dlg.ui.spinBoxSizeIndicMaxValue.setValue(q.value(1))
        else:
            self.dlg.ui.spinBoxSizeIndicMinValue.setEnabled(False)
            self.dlg.ui.spinBoxSizeIndicMaxValue.setEnabled(False)
            self.dlg.ui.spinBoxSizeIndicMinValue.setValue(0)
            self.dlg.ui.spinBoxSizeIndicMaxValue.setValue(0)
        
    
    def _slotComboBoxColorIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT min("+self.modelColorIndic.record(indexChosenLine).value("col_name")+"), max("+self.modelColorIndic.record(indexChosenLine).value("col_name")+") FROM indic."+self.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.dlg.ui.spinBoxColorIndicMinValue.setEnabled(True)
            self.dlg.ui.spinBoxColorIndicMaxValue.setEnabled(True) 
            self.dlg.ui.spinBoxColorIndicMinValue.setValue(max(q.value(0),0))
            self.dlg.ui.spinBoxColorIndicMaxValue.setValue(q.value(1))
        else:
            self.dlg.ui.spinBoxColorIndicMinValue.setEnabled(False)
            self.dlg.ui.spinBoxColorIndicMaxValue.setEnabled(False) 
    
    
    def _slotComboBoxDerivedRepIndexChanged(self, indexChosenLine):
        if ((self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")): 
            if (indexChosenLine==0): # Ready to generate iso-surfaces
                self.dlg.ui.groupBoxParamDerivedRep.setEnabled(True)
                # Update available indicators for surface representation
                s="(\
                   SELECT lib, code, col_name FROM tempus_access.indicators \
                   WHERE sur_color = TRUE AND col_name IN \
                       (SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.dlg.ui.comboBoxReq.currentText()+"')\
                   AND col_name IN \
                       (SELECT col_name FROM tempus_access.indicators \
                       WHERE ARRAY[code] <@ (SELECT indic_list::integer[] FROM tempus_access.obj_type WHERE def_name = '"+self.obj_def_name+"') \
                       )\
                   )\
                   UNION \
                   (\
                   SELECT '', -1, '' \
                   )\
                   ORDER BY 2"
                self.modelDerivedRepIndic.setQuery(s, self.db)      
                
                self.dlg.ui.pushButtonDerivedRepDelete.setEnabled(False)
                self.dlg.ui.pushButtonDerivedRepRename.setEnabled(False)      
                self._slotComboBoxDerivedRepIndicIndexChanged(0)
            
            else: # Ready to display an already calculated isosurface
                self.dlg.ui.groupBoxParamDerivedRep.setEnabled(False)
                self.dlg.ui.pushButtonDerivedRepDelete.setEnabled(True)
                self.dlg.ui.pushButtonDerivedRepRename.setEnabled(True)
                self.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
                self.dlg.ui.groupBoxSize.setEnabled(False)
                s="(\
                       SELECT lib, code, col_name FROM tempus_access.indicators \
                       WHERE sur_color = TRUE AND col_name IN \
                           (SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.dlg.ui.comboBoxDerivedRep.currentText()+"') \
                       AND col_name IN \
                           (SELECT col_name FROM tempus_access.indicators \
                           WHERE ARRAY[code] <@ (SELECT indic_list::integer[] FROM tempus_access.obj_type WHERE def_name = '"+self.obj_def_name+"') \
                           )\
                   )\
                   UNION \
                   (\
                       SELECT '', -1, '' \
                   )\
                   ORDER BY 2"
                self.modelColorIndic.setQuery(s, self.db)

                
    def _slotPushButtonDerivedRepDeleteClicked(self):
        ret = QMessageBox.question(self.dlg, "TempusAccess", u"La représentation surfacique courante va être supprimée. \n Confirmez-vous cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)

        if (ret == QMessageBox.Ok):
            for layer in self.node_indicators.findLayers():
                if (layer.name()==self.dlg.ui.comboBoxDerivedRep.currentText()):
                    QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
                    
            s="DROP TABLE indic."+self.dlg.ui.comboBoxDerivedRep.currentText()+";\
            DELETE FROM tempus_access.indic_catalog WHERE layer_name = '"+self.dlg.ui.comboBoxDerivedRep.currentText()+"';"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(s+"\n")
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
            self.refreshDerivedRep()
            
        
    def _slotPushButtonDerivedRepRenameClicked(self):
        old_name = self.modelDerivedRep.record(self.dlg.ui.comboBoxDerivedRep.currentIndex()).value("layer_name")
        new_name = self.dlg.ui.comboBoxDerivedRep.currentText()
        s="ALTER TABLE indic."+old_name+" RENAME TO "+new_name+";\
        UPDATE tempus_access.indic_catalog SET layer_name = '"+new_name+"' WHERE layer_name = '"+self.modelDerivedRep.record(self.dlg.ui.comboBoxDerivedRep.currentIndex()).value("layer_name")+"';\
        ALTER TABLE indic."+new_name+"\
        RENAME CONSTRAINT "+old_name+"_pkey TO "+new_name+"_pkey";
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(s+"\n")
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
        
        for layer in self.node_indicators.findLayers():
            if (layer.name()==old_name):
                QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
        
        self.refreshDerivedRep()
        
        self.dlg.ui.comboBoxDerivedRep.setCurrentIndex(self.modelDerivedRep.match(self.modelDerivedRep.index(0,0), 0, new_name)[0].row())

            
    def _slotComboBoxDerivedRepIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT min("+self.modelDerivedRepIndic.record(indexChosenLine).value("col_name")+"), max("+self.modelDerivedRepIndic.record(indexChosenLine).value("col_name")+") FROM indic."+self.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.dlg.ui.spinBoxDerivedRepIndicMinValue.setEnabled(True)
            self.dlg.ui.spinBoxDerivedRepIndicMaxValue.setEnabled(True)
            self.dlg.ui.spinBoxDerivedRepIndicMinValue.setValue(q.value(0))
            self.dlg.ui.spinBoxDerivedRepIndicMaxValue.setRange(1, q.value(1))
            self.dlg.ui.spinBoxDerivedRepIndicMaxValue.setValue(q.value(1))
            self.dlg.ui.spinBoxDerivedRepIndicMaxValue.setRange(1, q.value(1))
            self.dlg.ui.spinBoxDerivedRepClasses.setRange(1, q.value(1))
            if (self.dlg.ui.comboBoxDerivedRep.currentText()==""):
                self.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(True)
            else:
                self.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
        else:
            self.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
            self.dlg.ui.spinBoxDerivedRepIndicMinValue.setEnabled(False)
            self.dlg.ui.spinBoxDerivedRepIndicMaxValue.setEnabled(False)
            self.dlg.ui.spinBoxColorIndicMinValue.setValue(0)
            self.dlg.ui.spinBoxColorIndicMaxValue.setValue(0)
                
    
    def _slotPushButtonDerivedRepGenerateClicked(self):
        self.isosurfaces=True
        self.buildQuery()
        if self.debug:
            with open(self.plugin_dir+"/log.txt", "a") as log_file:
                log_file.write(self.query+"\n")
        r=QtSql.QSqlQuery(self.db)
        done=r.exec_(self.query)
        self._slotResultAvailable(done, self.query)
    
    
    def _slotpushButtonReqDisplayClicked(self):
        size_indic_name=self.modelSizeIndic.record(self.dlg.ui.comboBoxSizeIndic.currentIndex()).value("col_name")
        color_indic_name=self.modelColorIndic.record(self.dlg.ui.comboBoxColorIndic.currentIndex()).value("col_name")
        
        self.dlg.ui.labelElapsedTime.setText("")
               
        if (size_indic_name!=""):
            s="SELECT tempus_access.map_indicator('"+self.dlg.ui.comboBoxReq.currentText()+"', '"+size_indic_name+"', 'size', "+str(self.dlg.ui.spinBoxSizeIndicMinValue.value())+", "+str(self.dlg.ui.spinBoxSizeIndicMaxValue.value())+", "+str(self.dlg.ui.doubleSpinBoxSize.value())+")"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(unicode(s)+"\n")
            
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        elif (self.obj_def_name != "paths_tree") and (self.obj_def_name != "comb_paths_trees"):
            s="UPDATE indic."+self.dlg.ui.comboBoxReq.currentText()+" SET symbol_size = 1"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(unicode(s)+"\n")
            
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
        if (color_indic_name!=""):
            s="SELECT tempus_access.map_indicator('"+self.dlg.ui.comboBoxReq.currentText()+"', '"+color_indic_name+"', 'color', "+str(self.dlg.ui.spinBoxColorIndicMinValue.value())+", "+str(self.dlg.ui.spinBoxColorIndicMaxValue.value())+", 1)"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(unicode(s)+"\n")
            
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        elif (self.obj_def_name != "paths_tree") and (self.obj_def_name != "comb_paths_trees"):
            s="UPDATE indic."+self.dlg.ui.comboBoxReq.currentText()+" SET symbol_color = 1"
            if self.debug:
                with open(self.plugin_dir+"/log.txt", "a") as log_file:
                    log_file.write(unicode(s)+"\n")
            
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s)) 
        
        for layer in self.node_indicators.findLayers():
            self.iface.legendInterface().setLayerVisible(layer.layer(), False)
        
        # Stop areas or stops
        if (((self.obj_def_name=="stops") or (self.obj_def_name=="stop_areas")) and self.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/stops_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif (((self.obj_def_name=="stops") or (self.obj_def_name=="stop_areas")) and self.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/stops_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Sections
        elif ((self.obj_def_name=="sections") and self.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif ((self.obj_def_name=="sections") and self.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Trips
        elif ((self.obj_def_name=="trips") and self.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif ((self.obj_def_name=="trips") and self.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Routes or agencies
        elif ((self.obj_def_name =="routes") or (self.obj_def_name=="agencies")):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), '', 'gid', None, '')
        # Paths
        elif (self.obj_def_name == "paths"):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/paths.qml", "gid", "the_geom", "")
        elif (self.obj_def_name=="paths_details"):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/paths_by_mode.qml", "gid", "the_geom", "") 
        # Paths tree described by nodes
        elif (self.obj_def_name=="paths_tree") and (self.dlg.ui.toolBoxDisplay.currentIndex()==0):            
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_nodes.qml", "to_node", "geom_point", "") 
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_edges.qml", "to_node", "geom_section", "")
        elif ((self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")) and (self.dlg.ui.toolBoxDisplay.currentIndex()==1):
            self.indicDisplay(self.dlg.ui.comboBoxDerivedRep.currentText(), self.plugin_dir + "/styles/isochrons_surfaces.qml", "id", "geom", "")
        elif (self.obj_def_name=="comb_paths_trees") and (self.dlg.ui.toolBoxDisplay.currentIndex()==0):
            self.indicDisplay(self.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_nodes.qml", "id", "geom", "")
        
        if (self.obj_def_name == "paths" or self.obj_def_name=="paths_details" or self.obj_def_name=="paths_tree" or self.obj_def_name=="comb_paths_trees"):
            for layer in self.node_indicators.findLayers():
                if (layer.name()== "Destinations" or layer.name() == "Origines"):
                    self.iface.legendInterface().setLayerVisible(layer.layer(), True)   
    
    
