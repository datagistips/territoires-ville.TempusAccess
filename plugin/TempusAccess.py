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
import pdb
import config

# import the code for the dialogs
from TempusAccess_dock_widget import TempusAccess_dock_widget
from set_db_connection_dialog import set_db_connection_dialog
from manage_db_dialog import manage_db_dialog
from import_pt_dialog import import_pt_dialog
from manage_pt_dialog import manage_pt_dialog
from import_road_dialog import import_road_dialog
from export_delete_road_dialog import export_delete_road_dialog
from import_poi_dialog import import_poi_dialog
from delete_poi_dialog import delete_poi_dialog
from import_zoning_dialog import import_zoning_dialog
from delete_zoning_dialog import delete_zoning_dialog
from manage_indicators_dialog import manage_indicators_dialog
from indic_calc_tools import *

import subprocess
import qgis
import datetime
import os
import sys
import string
import csv

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
        
        # Keep reference to paths to the plugin storage directory and to the default directory for data recording and loading
        self.plugin_dir = os.path.dirname(__file__)
        self.data_dir = self.plugin_dir + "/data"
        self.styles_dir = self.plugin_dir + "/styles"
        self.sql_dir = self.plugin_dir + "/sql"
        self.icon_dir = self.plugin_dir + "/icons"
        self.last_dir = self.plugin_dir
        
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
        
        # Databases
        self.modelDB = QtSql.QSqlQueryModel()
        
        self.set_db_connection_dialog = set_db_connection_dialog(self, self.iface)
        self.set_db_connection_dialog.setModal(True)
        self.manage_db_dialog=manage_db_dialog(self, self.iface)
        self.manage_db_dialog.setModal(True) 
       
        # PT networks    
        self.modelPTNetwork = QtSql.QSqlQueryModel()
        self.modelPTNetworkImportFormat = QtSql.QSqlQueryModel()
        self.modelPTNetworkExportFormat = QtSql.QSqlQueryModel()
        self.modelPTNetworkFormatVersion = QtSql.QSqlQueryModel()
        self.dlg.ui.listViewPTNetworks.setModel(self.modelPTNetwork)
        self.PTNetworks = []
        
        self.import_pt_dialog=import_pt_dialog(self, self.iface)
        self.import_pt_dialog.setModal(True)         
        self.manage_pt_dialog=manage_pt_dialog(self, self.iface)
        self.manage_pt_dialog.setModal(True) 
        self.manage_pt_dialog.ui.listViewPTNetworks.setModel(self.modelPTNetwork)
        
        # Road networks
        self.modelRoadNetwork = QtSql.QSqlQueryModel()
        self.modelRoadNetworkImportFormat = QtSql.QSqlQueryModel()
        self.modelRoadNetworkExportFormat = QtSql.QSqlQueryModel()
        self.modelRoadNetworkFormatVersion = QtSql.QSqlQueryModel()
        
        self.import_road_dialog=import_road_dialog(self, self.iface)
        self.import_road_dialog.setModal(True) 
        self.export_delete_road_dialog=export_delete_road_dialog(self, self.iface)
        self.export_delete_road_dialog.setModal(True) 
        
        # POI
        self.modelPOISource = QtSql.QSqlQueryModel()
        self.modelPOIType = QtSql.QSqlQueryModel()
        self.modelPOISourceImportFormat = QtSql.QSqlQueryModel()
        self.modelPOISourceExportFormat = QtSql.QSqlQueryModel()
        self.modelPOISourceFormatVersion = QtSql.QSqlQueryModel()
        
        self.import_poi_dialog=import_poi_dialog(self, self.iface)
        self.import_poi_dialog.setModal(True) 
        self.delete_poi_dialog=delete_poi_dialog(self, self.iface)
        self.delete_poi_dialog.setModal(True) 
        
        # Zonings
        self.modelZoningSource=QtSql.QSqlQueryModel()  
        self.modelZoningSourceImportFormat = QtSql.QSqlQueryModel()
        self.modelZoningSourceFormatVersion = QtSql.QSqlQueryModel()
        self.modelZone=QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxIndicZoning.setModel(self.modelZoningSource)
        self.dlg.ui.comboBoxZoningFilter.setModel(self.modelZoningSource)
        self.dlg.ui.comboBoxZone.setModel(self.modelZone)

        self.import_zoning_dialog=import_zoning_dialog(self, self.iface)
        self.import_zoning_dialog.setModal(True) 
        self.delete_zoning_dialog=delete_zoning_dialog(self, self.iface)
        self.delete_zoning_dialog.setModal(True) 
        
        # Indicators, requests and representations
        self.modelIndic = QtSql.QSqlQueryModel()
        self.modelSizeIndic = QtSql.QSqlQueryModel()
        self.modelDerivedRepIndic = QtSql.QSqlQueryModel()
        self.modelColorIndic = QtSql.QSqlQueryModel()
        self.modelDerivedRep=QtSql.QSqlQueryModel()
        self.modelPathID = QtSql.QSqlQueryModel()
        self.modelRepMeth = QtSql.QSqlQueryModel()
        self.modelReq = QtSql.QSqlQueryModel()
        
        self.dlg.ui.listViewIndic.setModel(self.modelIndic)        
        
        self.manage_indicators_dialog=manage_indicators_dialog(self, self.iface)
        self.manage_indicators_dialog.setModal(True) 
        
        # Object types
        self.modelObjType = QtSql.QSqlQueryModel()
        self.dlg.ui.comboBoxObjType.setModel(self.modelObjType)
        self.obj_def_name="stop_areas"
        
        # Nodes
        self.modelNode = QtSql.QSqlQueryModel()
        self.modelNodeType = QtSql.QSqlQueryModel()
        self.modelSelectedNodes = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxOrig.setModel(self.modelNode)
        self.dlg.ui.comboBoxDest.setModel(self.modelNode)
        self.dlg.ui.comboBoxPathsTreeRootNode.setModel(self.modelNode)
        self.dlg.ui.comboBoxNodeType.setModel(self.modelNodeType)
        self.dlg.ui.listViewNodes.setModel(self.modelSelectedNodes)
        
        # Aggregation methods
        self.modelAgreg = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxNodeAg.setModel(self.modelAgreg)
        self.dlg.ui.comboBoxDayAg.setModel(self.modelAgreg)
        self.dlg.ui.comboBoxTimeAg.setModel(self.modelAgreg)
        
        # PT stops
        self.modelStop = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxForcStop.setModel(self.modelStop)
        
        # PT routes
        self.modelRoute = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxForcRoute.setModel(self.modelRoute)

        # PT agencies
        self.modelAgencies = QtSql.QSqlQueryModel()
        
        self.dlg.ui.tableViewAgencies.setModel(self.modelAgencies)
        self.dlg.ui.tableViewAgencies.verticalHeader().setVisible(False)
                
        # Transport modes        
        self.modelIModes = QtSql.QSqlQueryModel()
        self.modelPTModes = QtSql.QSqlQueryModel()
        
        self.dlg.ui.listViewIModes.setModel(self.modelIModes)
        self.dlg.ui.listViewPTModes.setModel(self.modelPTModes)

        # Days
        self.modelDayType = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxDayType.setModel(self.modelDayType)

        # Periods
        self.modelPerType = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxPerType.setModel(self.modelPerType)

        # Optimization criteria
        self.modelCriterion = QtSql.QSqlQueryModel()
        
        self.dlg.ui.comboBoxCriterion.setModel(self.modelCriterion)
        
        
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
        self.action = QAction(QIcon(self.icon_dir + "/icon_tempus.jpg"), u"Lancer le serveur",self.iface.mainWindow())
        self.action_set_db_connection = QAction(QIcon(self.icon_dir + "/icon_db.png"), u"Définir la connexion à la base de données", self.iface.mainWindow())
        self.action_manage_db = QAction(QIcon(self.icon_dir + "/icon_db.png"), u"Gérer les bases de données", self.iface.mainWindow())
        self.action_import_road = QAction(QIcon(self.icon_dir + "/icon_road.png"), u"Importer un réseau routier", self.iface.mainWindow())
        self.action_export_delete_road = QAction(QIcon(self.icon_dir + "/icon_road.png"), u"Exporter ou supprimer un réseau routier", self.iface.mainWindow())
        self.action_import_pt = QAction(QIcon(self.icon_dir + "/icon_pt.png"), u"Importer une offre de transport en commun", self.iface.mainWindow())
        self.action_manage_pt = QAction(QIcon(self.icon_dir + "/icon_pt.png"), u"Gérer les offres de transport en commun", self.iface.mainWindow())
        self.action_import_poi = QAction(QIcon(self.icon_dir + "/icon_poi.png"), u"Importer des points d'intérêt", self.iface.mainWindow())

        self.action_delete_poi = QAction(QIcon(self.icon_dir + "/icon_poi.png"), u"Supprimer une source de points d'intérêt", self.iface.mainWindow())
        self.action_import_zoning = QAction(QIcon(self.icon_dir + "/icon_zoning.png"), u"Importer un zonage", self.iface.mainWindow())
        self.action_delete_zoning = QAction(QIcon(self.icon_dir + "/icon_zoning.png"), u"Supprimer un zonage", self.iface.mainWindow())

        self.action_manage_indicators = QAction(QIcon(self.icon_dir + "/icon_indicators.png"), u"Gérer les calculs stockés", self.iface.mainWindow())
        
        self.action.setToolTip(u"Lancer le serveur")
        self.action_set_db_connection.setToolTip(u"Définir la connexion à la base de données")
        self.action_manage_db.setToolTip(u"Gérer les bases de données")
        self.action_import_road.setToolTip(u"Importer un réseau routier")
        self.action_export_delete_road.setToolTip(u"Exporter ou supprimer un réseau routier")
        self.action_import_pt.setToolTip(u"Importer une offre de transport en commun")
        self.action_manage_pt.setToolTip(u"Gérer les offres de transport en commun")
        self.action_import_poi.setToolTip(u"Importer des points d'intérêt")

        self.action_delete_poi.setToolTip(u"Supprimer une source de points d'intérêt")
        self.action_import_zoning.setToolTip(u"Importer un zonage")
        self.action_delete_zoning.setToolTip(u"Supprimer un zonage")
        self.action_manage_indicators.setToolTip(u"Gérer les indicateurs")
        
        # Connect the actions to the methods
        self.action.triggered.connect(self.load)
        self.action_set_db_connection.triggered.connect(self.set_db_connection)
        self.action_manage_db.triggered.connect(self.manage_db)
        self.action_import_road.triggered.connect(self.import_road)
        self.action_export_delete_road.triggered.connect(self.export_delete_road)
        self.action_import_pt.triggered.connect(self.import_pt)
        self.action_manage_pt.triggered.connect(self.manage_pt)
        self.action_import_poi.triggered.connect(self.import_poi)
        self.action_delete_poi.triggered.connect(self.delete_poi)
        self.action_import_zoning.triggered.connect(self.import_zoning)
        self.action_delete_zoning.triggered.connect(self.delete_zoning)
        self.action_manage_indicators.triggered.connect(self.manage_indicators)
        
        # Add toolbar buttons and menu items
        self.iface.addPluginToMenu(u"&TempusAccess",self.action)
        self.iface.addPluginToMenu(u"&TempusAccess", self.action_set_db_connection)
        self.iface.addPluginToMenu(u"&TempusAccess", self.action_manage_db)
        self.iface.addPluginToMenu(u"&TempusAccess", self.action_import_road)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_export_delete_road)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_import_pt)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_manage_pt)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_import_poi)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_delete_poi)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_import_zoning)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_delete_zoning)
        self.iface.addPluginToMenu(u"&TempusAccess",self.action_manage_indicators)
                
        m = self.toolButton.menu()
        m.addAction(self.action)
        m.addAction(self.action_set_db_connection)
        m.addAction(self.action_manage_db)
        m.addAction(self.action_import_road)
        m.addAction(self.action_export_delete_road)
        m.addAction(self.action_import_pt)
        m.addAction(self.action_manage_pt)
        m.addAction(self.action_import_poi)
        m.addAction(self.action_delete_poi)
        m.addAction(self.action_import_zoning)
        m.addAction(self.action_delete_zoning)
        m.addAction(self.action_manage_indicators)
        
        self.toolButton.setDefaultAction(self.action)
        self.first = False
    
    
    def load(self):           
        cmd = [ "python", "-m", "pglite", "init" ]
        r = subprocess.call( cmd )
        cmd = [ "python", "-m", "pglite", "start" ]
        r = subprocess.call( cmd )
        
        self.iface.addDockWidget(Qt.RightDockWidgetArea, self.dlg)
        
        # Set on-the-fly projection
        self.iface.mapCanvas().mapRenderer().setProjectionsEnabled(True) # Enable on the fly reprojections
        #self.iface.mapCanvas().mapRenderer().setDestinationCrs(QgsCoordinateReferenceSystem(2154, QgsCoordinateReferenceSystem.PostgisCrsId))
        
        qgis.utils.iface.actionShowPythonDialog().trigger()
        pythonConsole = qgis.utils.iface.mainWindow().findChild( QDockWidget, 'PythonConsole' )
        pythonConsole.console.shellOut.clearConsole()
        
        # Prepare main dock widget
        self.dlg.ui.radioButtonDayType.setChecked(True)
        self.dlg.ui.radioButtonPreciseDate.setChecked(True)
        self.dlg.ui.radioButtonTimePeriod.setChecked(True)
        self.node_type=0
        
        # Show DBConnectionDialog
        self.set_db_connection_dialog.show()
        
    
    def unload(self):
        root = QgsProject.instance().layerTreeRoot()
        node_group=root.findGroup("Analyse de l'offre de transport collectif")
        root.removeChildNode(node_group)
        
        # Remove the plugin menu items and icons
        self.iface.removePluginMenu(u"&TempusAccess", self.action_manage_indicators) 
        self.iface.removePluginMenu(u"&TempusAccess", self.action_import_zoning)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_delete_zoning)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_import_poi)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_delete_poi)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_import_pt)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_manage_pt)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_import_road)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_export_delete_road)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_set_db_connection)
        self.iface.removePluginMenu(u"&TempusAccess", self.action_manage_db)
        self.iface.removePluginMenu(u"&TempusAccess", self.action)

        self.iface.removeToolBarIcon(self.action_manage_indicators)
        self.iface.removeToolBarIcon(self.action_import_zoning)
        self.iface.removeToolBarIcon(self.action_delete_zoning)
        self.iface.removeToolBarIcon(self.action_import_poi)
        self.iface.removeToolBarIcon(self.action_delete_poi)
        self.iface.removeToolBarIcon(self.action_import_pt)
        self.iface.removeToolBarIcon(self.action_manage_pt)
        self.iface.removeToolBarIcon(self.action_import_road)
        self.iface.removeToolBarIcon(self.action_export_delete_road)
        self.iface.removeToolBarIcon(self.action_set_db_connection)
        self.iface.removeToolBarIcon(self.action_manage_db)
        self.iface.removeToolBarIcon(self.action)
        del self.toolButton
        
        # Close dialogs which would stay opened
        self.dlg.hide()
        self.manage_indicators_dialog.hide()
        self.import_zoning_dialog.hide()
        self.delete_zoning_dialog.hide()
        self.import_poi_dialog.hide()
        self.delete_poi_dialog.hide()
        self.import_pt_dialog.hide()
        self.manage_pt_dialog.hide()
        self.import_road_dialog.hide()
        self.export_delete_road_dialog.hide() 
        self.set_db_connection_dialog.hide()
        self.manage_db_dialog.hide()
        
    
    def _connectSlots(self):
        
        # General interface
        self.dlg.ui.pushButtonIndicCalculate.clicked.connect(self._slotPushButtonIndicCalculateClicked)
        self.dlg.ui.pushButtonReinitCalc.clicked.connect(self._slotPushButtonReinitCalcClicked)
        self.timer.timeout.connect(self._slotUpdateTimer) 
        
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
        self.dlg.ui.comboBoxZoningFilter.currentIndexChanged.connect(self._slotComboBoxZoningFilterIndexChanged)
        self.dlg.ui.comboBoxZone.currentIndexChanged.connect(self._slotComboBoxZoneIndexChanged)
        self.dlg.ui.pushButtonInvertOD.clicked.connect(self._slotPushButtonInvertODClicked)
        self.dlg.ui.comboBoxPathsTreeOD.currentIndexChanged.connect(self._slotComboBoxPathsTreeODIndexChanged)
        self.dlg.ui.comboBoxCombPathsTreesOD.currentIndexChanged.connect(self._slotComboBoxCombPathsTreesODIndexChanged)
        
        
        # 2nd tab
        self.dlg.ui.listViewPTNetworks.selectionModel().selectionChanged.connect(self._slotlistViewPTNetworksSelectionChanged)
        
        
        # 3rd tab 
        self.dlg.ui.radioButtonPreciseDate.toggled.connect(self._slotRadioButtonPreciseDateToggled)
        self.dlg.ui.radioButtonDayType.toggled.connect(self._slotRadioButtonDayTypeToggled)
        self.dlg.ui.radioButtonTimePeriod.toggled.connect(self._slotRadioButtonTimePeriodToggled)
        self.dlg.ui.radioButtonTimePoint.toggled.connect(self._slotRadioButtonTimePointToggled)
        self.dlg.ui.comboBoxTimeConstraint.currentIndexChanged.connect(self._slotComboBoxTimeConstraintIndexChanged)
        self.dlg.ui.radioButtonTimeInterval.toggled.connect(self._slotRadioButtonTimeIntervalToggled)
       
    
    def set_db_connection(self):        
        self.set_db_connection_dialog.show()
    
    
    def manage_db(self):
        self.manage_db_dialog.show()
    
    
    def import_road(self):
        self.import_road_dialog.show()
        self.import_road_dialog._slotComboBoxFormatCurrentIndexChanged(self.import_road_dialog.ui.comboBoxFormat.currentIndex())


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
        self.import_pt_dialog._slotComboBoxFormatCurrentIndexChanged(self.import_pt_dialog.ui.comboBoxFormat.currentIndex())
    
    
    def manage_pt(self):
        self.manage_pt_dialog.show()
    
    
    def import_poi(self):
        self.import_poi_dialog.show()
        self.import_poi_dialog._slotComboBoxFormatCurrentIndexChanged(self.import_poi_dialog.ui.comboBoxFormat.currentIndex())

    
    def delete_poi(self):
        self.delete_poi_dialog.show()
    
    
    def import_zoning(self):
        self.import_zoning_dialog.show()
        
    
    def delete_zoning(self):
        self.delete_zoning_dialog.show()
        
      
    def manage_indicators(self):
        self.manage_indicators_dialog.show()
    
    
    def refreshPTNetworks(self):    
        # Populate the listView containing GTFS data sources
        s="SELECT feed_id, id FROM tempus_gtfs.feed_info ORDER BY 2"
        self.modelPTNetwork.setQuery(unicode(s), self.db)
                
        # Each update of the model must be accompanied by a new connexion of signal and slot on the listView selection
        self.dlg.ui.listViewPTNetworks.selectionModel().selectionChanged.connect(self._slotlistViewPTNetworksSelectionChanged)
        
        self.modelAgencies.clear()
        
        sel = QItemSelection(self.modelPTNetwork.index(0,0), self.modelPTNetwork.index(0,1))
        self.dlg.ui.listViewPTNetworks.selectionModel().select(sel, QItemSelectionModel.ClearAndSelect)
    
    
    def refreshRoadNetworks(self):
        s="SELECT name, id, comment FROM tempus.road_network ORDER BY 2"
        self.modelRoadNetwork.setQuery(unicode(s), self.db)
        
        
    def refreshPOISources(self):
        s="SELECT name, id, comment FROM tempus.poi_source ORDER BY 2"
        self.modelPOISource.setQuery(unicode(s), self.db)    
    
    
    def refreshZoningSources(self):
        s="SELECT comment, name, id FROM zoning.zoning_source ORDER BY 2"
        self.modelZoningSource.setQuery(unicode(s), self.db)
        
    
    def refreshPTData(self):        
        s="REFRESH MATERIALIZED VIEW tempus_access.stops_by_mode;\
           REFRESH MATERIALIZED VIEW tempus_access.sections_by_mode;\
           REFRESH MATERIALIZED VIEW tempus_access.trips_by_mode;"
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
    
    
    def zoomToLayersList(self, layers, visible):
        from_proj = QgsCoordinateReferenceSystem()
        from_proj.createFromSrid(4326)
        to_proj = QgsCoordinateReferenceSystem()
        to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
        crd=QgsCoordinateTransform(from_proj, to_proj)
        
        extent = QgsRectangle()
        for layer in layers:
            extent.combineExtentWith( layer.extent() )
            if (visible == True):
                self.iface.legendInterface().setLayerVisible(layer, True)
        
        extent.scale( 1.1 ) # Increase a bit the extent to make sure all geometries lie inside 
        if (extent.isEmpty==False): 
            self.iface.mapCanvas().setExtent(crd.transform(extent))
        
        self.iface.mapCanvas().refresh()
    
        
    def loadLayers(self):
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
        
        # Zonings
        for i in range(0,self.modelZoningSource.rowCount()):
            if (self.modelZoningSource.record(i).value("id")!=-1):
                uri.setDataSource("zoning", self.modelZoningSource.record(i).value("name"), "geom", "")
                layer = QgsVectorLayer(uri.uri(), self.modelZoningSource.record(i).value("comment"), "postgres")
                if (layer.isValid()):
                    QgsMapLayerRegistry.instance().addMapLayer(layer, False)
                    node_layer = QgsLayerTreeLayer(layer)
                    self.node_zoning.insertChildNode(i, node_layer)
                    self.iface.legendInterface().setLayerVisible(layer, False)
        
        # Stops by mode (view)
        uri.setDataSource("tempus_gtfs", "stops_by_mode", "geom", "", "gid") 
        layer = QgsVectorLayer(uri.uri(), u"Arrêts par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_stop_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(0, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True) 
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+"::integer[])")
        
        # Sections by mode (view)
        uri.setDataSource("tempus_gtfs", "sections_by_mode", "geom", "", "gid")
        layer = QgsVectorLayer(uri.uri(), "Sections par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_section_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(1, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+"::integer[])")
        
        # Trips by mode (view)
        uri.setDataSource("tempus_gtfs", "trips_by_mode", "geom_multi", "", "gid")
        layer = QgsVectorLayer(uri.uri(), u"Itinéraires de ligne par mode", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_trip_by_mode.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(2, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+"::integer[])")
        
        # Stops
        uri.setDataSource("tempus_gtfs", "stops", "geom", "", "id") 
        layer = QgsVectorLayer(uri.uri(), u"Arrêts", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_stop.qml')
        if (layer.isValid):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(3, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+"::integer[])")
        
        
        # Stop areas
        uri.setDataSource("tempus_gtfs", "stops", "geom", "", "id") 
        layer = QgsVectorLayer(uri.uri(), u"Zones d'arrêts et entrées de stations", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_stop_area.qml')
        if (layer.isValid):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(4, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+"::integer[])")
        
        
        
        # Sections
        uri.setDataSource("tempus_gtfs", "sections", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), "Sections", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/pt_section.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_pt_offer.insertChildNode(5, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, False)
            layer.setSubsetString("ARRAY[feed_id] <@ ARRAY"+str(self.PTNetworks)+"::integer[]")
        
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
        layer.loadNamedStyle(self.styles_dir + '/road_section_pedestrians.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(2, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
        
        uri.setDataSource("tempus", "road_section_cyclists", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Réseau vélo", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_section_bicycles.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(3, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            
        uri.setDataSource("tempus", "road_section_cars", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Réseau voiture", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_section_cars.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(4, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)

        # Penalized road movements
        uri.setDataSource("tempus", "view_penalized_movements_cars", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Mouvements pénalisés voitures", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_penalized_movement.qml')
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_road_offer.insertChildNode(5, node_layer)
            self.iface.legendInterface().setLayerVisible(layer,False)
            
        uri.setDataSource("tempus", "view_penalized_movements_cyclists", "geom", "", "id")
        layer = QgsVectorLayer(uri.uri(), u"Mouvements pénalisés vélos", "postgres")
        layer.loadNamedStyle(self.styles_dir + '/road_penalized_movements.qml')
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
        self.node_zoning.setExpanded(False)
        
        # Zoom to all layers
        self.zoomToLayersList(QgsMapLayerRegistry.instance().mapLayers().values(), False)
        
    
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
        self.PTNetworks = []
        if (self.dlg.ui.listViewPTNetworks.selectionModel().hasSelection()):
            for item in self.dlg.ui.listViewPTNetworks.selectionModel().selectedRows():
                self.PTNetworks.append(self.modelPTNetwork.record(item.row()).value("id"))
        
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
        
        # Zoning filter
        if (self.modelZoningSource.record(self.dlg.ui.comboBoxZoningFilter.currentIndex()).value("id")>=0):
            self.zoning_filter = self.modelZoningSource.record(self.dlg.ui.comboBoxZoningFilter.currentIndex()).value("id")
        
        # Filtered zones
        if (self.modelZone.record(self.dlg.ui.comboBoxZone.currentIndex()).value("id")>=0):
            self.zones = "ARRAY["+str(self.modelZone.record(self.dlg.ui.comboBoxZone.currentIndex()).value("id"))+"]"
        else:
            self.zones = "NULL"
        
        # Zoning used to build population indicator
        if (self.modelZoningSource.record(self.dlg.ui.comboBoxIndicZoning.currentIndex()).value("id")>=0):
            self.indic_zoning = self.modelZoningSource.record(self.dlg.ui.comboBoxIndicZoning.currentIndex()).value("id")        
        
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
        if ((self.obj_def_name == "stop_areas") or (self.obj_def_name == "stops") or (self.obj_def_name=="sections") or (self.obj_def_name=="trips") or (self.obj_def_name=="stops_routes") or (self.obj_def_name=="routes")):
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
                self.query="SELECT tempus_access.create_pt_stop_area_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_route := "+self.route+"::integer\
                                                                                );"
            
            elif (self.obj_def_name=="stops"):
                self.query="SELECT tempus_access.create_pt_stop_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_route := "+self.route+"::integer\
                                                                                );"
            
            # Build sections indicators
            elif (self.obj_def_name=="sections"):
                self.query="SELECT tempus_access.create_pt_section_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_time_ag := "+str(self.time_ag)+",\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_route := "+self.route+"::integer, \
                                                                                param_stop_area := "+self.stop+"::integer);"
            
            # Build trips indicators
            elif (self.obj_def_name=="trips"):
                self.query="SELECT tempus_access.create_pt_trip_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_time_ag := "+str(self.time_ag)+",\
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_route := "+self.route+"::integer, \
                                                                                param_stop_area := "+self.stop+"::integer\
                                                                                );"
            # Build stops routes indicators
            elif (self.obj_def_name=="stops_routes"):
                self.query="SELECT tempus_access.create_pt_stops_route_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_time_ag := "+str(self.time_ag)+",\
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_route := "+self.route+"::integer, \
                                                                                param_stop_area := "+self.stop+"::integer\
                                                                                );"
            # Build routes indicators
            elif (self.obj_def_name=="routes"):
                self.query="SELECT tempus_access.create_pt_route_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_agencies := ARRAY"+str(self.agencies)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_time_ag := "+str(self.time_ag)+",\
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_stop_area := "+self.stop+"::integer);"
        
        # Build agencies indicators
        if (self.obj_def_name=="agencies"):
            self.query="SELECT tempus_access.create_pt_agency_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_pt_networks := ARRAY"+str(self.PTNetworks)+"::integer[],\
                                                                                param_route_types := ARRAY"+str(self.route_types)+"::integer[],\
                                                                                param_day := "+self.day+"::date,\
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_day_ag := "+str(self.day_ag)+"::integer,\
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_indic_zoning := "+str(self.indic_zoning)+"::integer,\
                                                                                param_zoning_filter := "+str(self.zoning_filter)+"::integer,\
                                                                                param_zones := "+self.zones+"::integer[],\
                                                                                param_stop_area := "+self.stop+"::integer);"
        
        
        # Build paths/paths trees/isochrons indicators
        elif ((self.obj_def_name=="paths") or (self.obj_def_name=="paths_details") or (self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")):
            self.days = []
            s1="SELECT unnest(days)::character varying FROM tempus_access.days("+self.day+"::date,"+str(self.day_type)+"::integer,"+str(self.per_type)+"::integer,"+self.per_start+"::date,"+self.per_end+"::date);"
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
                q1=QtSql.QSqlQuery(self.db)
                q1.exec_(unicode(s1))
                
                self.max_cost=0
                self.walking_speed=0
                self.cycling_speed=0
                self.node_ag = self.modelAgreg.record(self.dlg.ui.comboBoxNodeAg.currentIndex()).value("code")
                
                if (self.obj_def_name == "paths"):
                    self.query="SELECT tempus_access.create_path_indicator_layer(\
                                                                                param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                param_node_type := "+str(self.node_type)+"::integer, \
                                                                                param_o_node := "+str(self.from_node)+"::integer, \
                                                                                param_d_node := "+str(self.to_node)+"::integer, \
                                                                                param_i_modes := ARRAY"+str(self.i_modes)+"::integer[], \
                                                                                param_pt_modes := ARRAY"+str(self.pt_modes)+"::integer[], \
                                                                                param_day := "+self.day+"::date, \
                                                                                param_day_type := "+str(self.day_type)+"::integer, \
                                                                                param_per_type := "+str(self.per_type)+"::integer, \
                                                                                param_per_start := "+self.per_start+"::date, \
                                                                                param_per_end := "+self.per_end+"::date, \
                                                                                param_time_point := "+self.time_point+"::time, \
                                                                                param_time_start := "+self.time_start+"::time, \
                                                                                param_time_end := "+self.time_end+"::time, \
                                                                                param_time_inter := "+str(self.time_interval)+"::integer, \
                                                                                param_all_services := "+str(self.all_services)+"::boolean, \
                                                                                param_constraint_date_after := "+str(self.constraint_date_after)+"::boolean\
                                                                                );"
                                                                       
                elif (self.obj_def_name == "paths_details"):
                    self.query = "SELECT tempus_access.create_path_details_indicator_layer(\
                                                                                            param_indics := ARRAY"+str(self.indics)+"::integer[],\
                                                                                            param_node_type := "+str(self.node_type)+"::integer, \
                                                                                            param_o_node := "+str(self.from_node)+"::integer, \
                                                                                            param_d_node := "+str(self.to_node)+"::integer, \
                                                                                            param_i_modes := ARRAY"+str(self.i_modes)+"::integer[], \
                                                                                            param_pt_modes := ARRAY"+str(self.pt_modes)+"::integer[], \
                                                                                            param_day := "+self.day+"::date, \
                                                                                            param_day_type := "+str(self.day_type)+"::integer, \
                                                                                            param_per_type := "+str(self.per_type)+"::integer, \
                                                                                            param_per_start := "+self.per_start+"::date, \
                                                                                            param_per_end := "+self.per_end+"::date, \
                                                                                            param_time_point := "+self.time_point+"::time, \
                                                                                            param_time_start := "+self.time_start+"::time, \
                                                                                            param_time_end := "+self.time_end+"::time, \
                                                                                            param_time_inter := "+str(self.time_interval)+"::integer, \
                                                                                            param_all_services := "+str(self.all_services)+"::boolean, \
                                                                                            param_constraint_date_after := "+str(self.constraint_date_after)+"::boolean\
                                                                                          );"
            
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
                        self.road_nodes.append(int(self.root_node))
                    elif (self.obj_def_name=="comb_paths_trees"):
                        self.road_nodes = self.root_nodes
                
                self.max_cost=self.dlg.ui.spinBoxMaxCost.value()
                self.walking_speed=self.dlg.ui.doubleSpinBoxWalkingSpeed.value()
                self.cycling_speed=self.dlg.ui.doubleSpinBoxCyclingSpeed.value()
                
                # For isosurfaces computation
                self.indic = self.modelDerivedRepIndic.record(self.manage_indicators_dialog.ui.comboBoxDerivedRepIndic.currentIndex()).value("code")
                self.rep_meth = self.modelRepMeth.record(self.manage_indicators_dialog.ui.comboBoxRepMeth.currentIndex()).value("mod_code")
                self.classes_num=self.manage_indicators_dialog.ui.spinBoxDerivedRepClasses.value()
                self.param=self.manage_indicators_dialog.ui.doubleSpinBoxRepParam.value()                
                
                if (self.isosurfaces==False):
                    if (self.obj_def_name == "paths_tree"):
                        self.query="SELECT tempus_access.create_paths_tree_indicator_layer(\
                                                                                            param_indics := ARRAY"+str(self.indics)+", \
                                                                                            param_node_type := "+str(self.node_type)+", \
                                                                                            param_root_node := "+str(self.root_node)+", \
                                                                                            param_i_modes := ARRAY"+str(self.i_modes)+"::integer[], \
                                                                                            param_pt_modes := ARRAY"+str(self.pt_modes)+"::integer[], \
                                                                                            param_day := "+self.day+"::date, \
                                                                                            param_time_point := "+self.time_point+"::time, \
                                                                                            param_constraint_date_after := "+str(self.constraint_date_after)+"::boolean,\
                                                                                            param_max_cost := "+str(self.max_cost)+",\
                                                                                            param_walking_speed := "+str(self.walking_speed)+",\
                                                                                            param_cycling_speed := "+str(self.cycling_speed)+"\
                                                                                          );"
                                                                           
                    elif (self.obj_def_name == "comb_paths_trees"):
                        self.nodes_ag = self.modelAgreg.record(self.dlg.ui.comboBoxNodeAg.currentIndex()).value("code")
                        self.query="SELECT tempus_access.create_comb_paths_trees_indicator_layer(\
                                                                                            param_indics := ARRAY"+str(self.indics)+", \
                                                                                            param_node_type := "+str(self.node_type)+", \
                                                                                            param_root_nodes := ARRAY"+str(self.root_nodes)+", \
                                                                                            param_node_ag := "+str(self.nodes_ag)+",\
                                                                                            param_i_modes := ARRAY"+str(self.i_modes)+"::integer[], \
                                                                                            param_pt_modes := ARRAY"+str(self.pt_modes)+"::integer[], \
                                                                                            param_day := "+self.day+"::date, \
                                                                                            param_day_type := "+str(self.day_type)+"::integer, \
                                                                                            param_per_type := "+str(self.per_type)+"::integer, \
                                                                                            param_per_start := "+self.per_start+"::date, \
                                                                                            param_per_end := "+self.per_end+"::date, \
                                                                                            param_day_ag := "+str(self.day_ag)+",\
                                                                                            param_time_point := "+self.time_point+"::time, \
                                                                                            param_time_start := "+self.time_start+"::time, \
                                                                                            param_time_end := "+self.time_end+"::time, \
                                                                                            param_time_interval := "+str(self.time_interval)+"::integer, \
                                                                                            param_time_ag := "+str(self.time_ag)+",\
                                                                                            param_constraint_date_after := "+str(self.constraint_date_after)+"::boolean,\
                                                                                            param_max_cost := "+str(self.max_cost)+",\
                                                                                            param_walking_speed := "+str(self.walking_speed)+",\
                                                                                            param_cycling_speed := "+str(self.cycling_speed)+"\
                                                                                          );"
                                                                           
                elif (self.parent_layer!=""):
                    self.query="SELECT tempus_access.create_isosurfaces_indicator_layer(\
                                                                                         param_indics := ARRAY"+str(self.indics)+", \
                                                                                         param_parent_layer := '"+self.parent_layer+"',\
                                                                                         param_classes_num := "+str(self.classes_num)+"::integer, \
                                                                                         param_param := "+str(self.param)+"::double precision, \
                                                                                         param_rep_meth := "+str(self.rep_meth)+"::integer);"
        self.query=self.query.replace("  ", "")
            
    
    # Slots of the general interface
    
    def _slotPushButtonIndicCalculateClicked(self):
        self.isosurfaces=False
        self.buildQuery()
        
        self.done=False
        self.time.start()
        self.timer.start()
        
        if ((self.obj_def_name == "stop_areas") or \
            (self.obj_def_name == "stops") or \
            (self.obj_def_name=="sections") or \
            (self.obj_def_name == "trips") or \
            (self.obj_def_name == "stops_routes") or \
            (self.obj_def_name == "routes") or \
            (self.obj_def_name == "agencies")\
           ):
            self.gen_indic = genIndic(self.query, self.db)
            done = self.gen_indic.run()
            self.resultAvailable(done)
        
        elif ((self.obj_def_name == "paths") or \
              (self.obj_def_name == "paths_details") or \
              (self.obj_def_name == "paths_tree") or \
              (self.obj_def_name == "comb_paths_trees")\
             ):
            path_tree=False
            if (self.obj_def_name == "paths_tree") or (self.obj_def_name == "comb_paths_trees"):
                path_tree=True
            
            dbstring="host="+self.db.hostName()+" dbname="+self.db.databaseName()+" port="+str(self.db.port())
            
            self.path_indic = pathIndic(
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
                                            self.constraint_date_after\
                                        )
            done = self.path_indic.run()
            self.timer.stop()
            self.resultAvailable(done)
            
            
    def resultAvailable(self, done): 
        if (done==True):
            s="UPDATE tempus_access.indic_catalog SET calc_time = "+str(self.time.elapsed()/1000)+" WHERE layer_name = '"+self.obj_def_name+"';"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
            
            if (self.isosurfaces==False):
                t="SELECT count(*) FROM indic."+self.obj_def_name+" as count;"
            else:
                t="SELECT count(*) FROM indic.isosurfaces as count;"
            r=QtSql.QSqlQuery(unicode(t), self.db)
            r.next()
            
            if (r.value(0)>0): # has returned at least one row
                if (self.isosurfaces==False):
                    self.manage_indicators_dialog.refreshReq()
                    self.manage_indicators_dialog.ui.comboBoxReq.setCurrentIndex(self.manage_indicators_dialog.ui.comboBoxReq.findText(self.obj_def_name)) 
                    self.manage_indicators_dialog.show()
                else:
                    self.refreshDerivedRep()
                    manage_indicators_dialog.ui.comboBoxDerivedRep.setCurrentIndex(manage_indicators_dialog.ui.comboBoxDerivedRep.findText("isosurfaces"))
            
            else: # has not returned any row
                box = QMessageBox()
                box.setText(u"La requête a abouti mais n'a pas retourné de résultats." )
                display_and_clear_python_console()
                box.exec_()
        else:
            box = QMessageBox()
            box.setText(u"La requête a échoué.")
            display_and_clear_python_console()
            box.exec_()

      
    def _slotPushButtonReinitCalcClicked(self):
        self.manage_indicators_dialog.ui.comboBoxReq.setCurrentIndex(0)
        self._slotComboBoxObjTypeIndexChanged(self.dlg.ui.comboBoxObjType.currentIndex())
        self.node_indicators.setExpanded(False)
        
        self.dlg.ui.Tabs.setCurrentIndex(0)
        
        self.dlg.ui.labelElapsedTime.setText("")
            
        
    def _slotUpdateTimer(self):
        pass
        #self.dlg.ui.labelElapsedTime.setText(u"Temps d'exécution : "+str(self.time.elapsed()/1000)+" secondes")
        
    
    # Slots of the 1st tab
    
    def _slotComboBoxObjTypeIndexChanged(self, indexChosenLine):
        self.iface.mapCanvas().setMapTool(self.toolPan)
        self.obj_type = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("code")
        self.obj_def_name = self.modelObjType.record(self.dlg.ui.comboBoxObjType.currentIndex()).value("def_name")

        if (self.modelPTNetwork.rowCount()>0):
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
        elif (self.modelRoadNetwork.rowCount()>1):
            self.modelIndic.setQuery("SELECT lib, code, col_name\
                                        FROM tempus_access.indicators\
                                        WHERE needs_pt=False AND code IN \
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
            self.dlg.ui.groupBoxPTNetworks.setEnabled(True)
            self.dlg.ui.listViewPTNetworks.setSelectionMode(QAbstractItemView.SingleSelection)
            self.dlg.ui.listViewPTNetworks.setEnabled(True)
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
            self.manage_indicators_dialog.ui.toolBoxDisplay.setItemEnabled(1,False) # Isochron representations
        
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
            self.dlg.ui.groupBoxPTNetworks.setEnabled(True)
            self.dlg.ui.listViewPTNetworks.setSelectionMode(QAbstractItemView.MultiSelection)
            self.dlg.ui.listViewPTNetworks.selectAll()
            self.dlg.ui.listViewPTNetworks.setEnabled(False)
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
            self.manage_indicators_dialog.ui.toolBoxDisplay.setItemEnabled(1,False) # Isochron representations
        
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details"):
                self.addODLayers()
                
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
                self.addODLayers()
                
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
                self.addODLayers()
                
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
                
            self.updateSelectedNodes()
            self.dlg.ui.listViewPTModes.selectAll()
        self.dlg.ui.listViewIndic.selectAll()
    
    
    def _slotComboBoxNodeTypeIndexChanged(self, indexChosenLine):
        s=""
        self.node_type = self.modelNodeType.record(indexChosenLine).value("mod_code")
        self.root_nodes=[]
        
        # Origine and destination layers are removed
        layerList = [layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"Origines") or (layer.name()==u"Destinations"))]
        for lyr in layerList:
            QgsMapLayerRegistry.instance().removeMapLayer(lyr.id())
        
        
        if (self.node_type==0): # Stops area
            s="SELECT stop_name as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTNetworks) + ") ORDER BY 1"
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
        
        self.iface.mapCanvas().refresh()

    
    def _slotClickPoint(self, point, button): # 3rd argument gives the mouse button used for the clic 
        
        s=""
        i=0
        if (self.node_type==0): # Stop areas
            s="SELECT id, st_distance(geom, st_transform(st_setSRID(st_makepoint("+str(point.x())+", "+str(point.y())+"), "+str(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())+"), 4326)) as dist \
               FROM tempus_gtfs.stops \
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+") \
               ORDER BY 2 \
               LIMIT 1"
            i=4
        elif (self.node_type==1): # Road nodes
            s="SELECT id, st_distance(geom, st_transform(st_setSRID(st_makepoint("+str(point.x())+", "+str(point.y())+"), "+str(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())+"), 4326)) as dist \
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
            self.root_nodes.append(int(q.value(0)))
        
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
            layer.loadNamedStyle(self.styles_dir + '/mm_path_orig.qml')
        layer = QgsVectorLayer(uriDestinations.uri(), u"Destinations", "postgres")
        if (layer.isValid()):
            QgsMapLayerRegistry.instance().addMapLayer(layer, False)
            node_layer = QgsLayerTreeLayer(layer)
            self.node_indicators.insertChildNode(1, node_layer)
            self.iface.legendInterface().setLayerVisible(layer, True)
            layer.loadNamedStyle(self.styles_dir + '/mm_path_dest.qml')
    
       
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
                t="SELECT stop_name as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops \
                   WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTNetworks) + ") AND ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"\
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
            s="SELECT stop_name as stop, feed_id, stop_id, stop_name, id FROM tempus_gtfs.stops \
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+ str(self.PTNetworks) + ") AND ARRAY[id] <@ ARRAY"+str(self.root_nodes)+"\
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
        
        
    def _slotComboBoxZoningFilterIndexChanged(self, indexChosenLine):
        if (indexChosenLine>=0):
            s="SELECT lib, id FROM zoning."+self.modelZoningSource.record(self.dlg.ui.comboBoxZoningFilter.currentIndex()).value("name")+" \
                UNION \
                SELECT '', '-1' \
                ORDER BY 1"
        else:
            s="SELECT '' as lib, '-1' as char_id"
        self.modelZone.setQuery(unicode(s), self.db)
        
   
    def _slotComboBoxZoneIndexChanged(self):
        from_proj = QgsCoordinateReferenceSystem()
        from_proj.createFromSrid(4326)
        to_proj = QgsCoordinateReferenceSystem()
        to_proj.createFromSrid(self.iface.mapCanvas().mapRenderer().destinationCrs().postgisSrid())
        crd=QgsCoordinateTransform(from_proj, to_proj)
        
        self.zone_id = self.modelZone.record(self.dlg.ui.comboBoxZone.currentIndex()).value("id")
        
        # Filtering map display on the area layer
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems():
            for i in range(0,self.modelZoningSource.rowCount()):
                if ((self.modelZoningSource.record(i).value("id")==self.modelZoningSource.record(self.dlg.ui.comboBoxZoningFilter.currentIndex()).value("id")) and (layer.name()==self.modelZoningSource.record(i).value("comment"))):
                    if (self.zone_id == -1):
                        layer.setSubsetString("")
                        self.iface.legendInterface().setLayerVisible(layer, False)
                    elif (self.zone_id != None):
                        layer.setSubsetString("id = " + str(self.modelZone.record(self.dlg.ui.comboBoxZone.currentIndex()).value("id")))
                        self.iface.mapCanvas().setExtent(crd.transform(layer.extent()))
                        self.iface.legendInterface().setLayerVisible(layer, True)
                elif (layer.name() == self.modelZoningSource.record(i).value("comment")):
                    layer.setSubsetString("")
                    self.iface.legendInterface().setLayerVisible(layer, False)
        
        self.iface.mapCanvas().refresh()
    
    
    def _slotPushButtonInvertODClicked(self):
        index_orig=self.dlg.ui.comboBoxOrig.currentIndex()
        self.dlg.ui.comboBoxOrig.setCurrentIndex(self.dlg.ui.comboBoxDest.currentIndex())
        self.dlg.ui.comboBoxDest.setCurrentIndex(index_orig)
    
    
    # Slots of the 2nd tab
    
    def _slotlistViewPTNetworksSelectionChanged(self, selected, deselected):
        self.PTNetworks = []
        for item in self.dlg.ui.listViewPTNetworks.selectionModel().selectedRows():
            self.PTNetworks.append(self.modelPTNetwork.record(item.row()).value("id"))
        
        # Update of the dialog widgets with the selected feeds
        
        if (len(self.PTNetworks)>0):
            # Agencies
            s="SELECT feed_id, agency_id, agency_name, id \
               FROM tempus_gtfs.agency \
               WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTNetworks) + ") ORDER BY feed_id, agency_id"
            self.modelAgencies.setQuery(unicode(s), self.db)
            self.dlg.ui.tableViewAgencies.selectAll()
            self.dlg.ui.tableViewAgencies.resizeRowsToContents()
            self.dlg.ui.tableViewAgencies.resizeColumnsToContents()
            self.dlg.ui.tableViewAgencies.setColumnHidden(3, True)
            
            # PT modes
            s="SELECT name, id, gtfs_feed_id, gtfs_route_type \
               FROM tempus.transport_mode \
               WHERE gtfs_feed_id is not null AND ARRAY[gtfs_feed_id]::integer[] <@ ARRAY" + str(self.PTNetworks) 
            self.modelPTModes.setQuery(unicode(s), self.db)
            self.dlg.ui.listViewPTModes.selectAll()
            
            # From and to nodes for paths
            self._slotComboBoxNodeTypeIndexChanged(self.dlg.ui.comboBoxNodeType.currentIndex())        
            
            # PT stops
            s="SELECT DISTINCT stop_name as stop, id, feed_id, stop_id, stop_name \
               FROM tempus_gtfs.stops\
               WHERE location_type = 1 AND parent_station_id IS NULL AND feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTNetworks) + ")\
               UNION SELECT '', -1, '', '', ''\
               ORDER BY 1"
            self.modelStop.setQuery(unicode(s), self.db)
            
            # PT routes
            s="SELECT route_long_name as route_name, id, feed_id, route_id \
               FROM tempus_gtfs.routes \
               WHERE  feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTNetworks) + ")\
               UNION SELECT '', -1, null, null ORDER BY 1; "
            self.dlg.ui.comboBoxForcRoute.setModelColumn(0)
            self.modelRoute.setQuery(s, self.db)
            
            # PT sections
            s="SELECT DISTINCT id, stop_from, stop_to \
                 FROM tempus_gtfs.sections \
                 WHERE ARRAY[feed_id] <@ ARRAY" + str(self.PTNetworks) + "\
                 UNION SELECT -1, null, null ORDER BY 1;"
            
            # Calendar and date edition widgets : updated with the minimum and maximum dates in the selected data sources
            if (len(self.dlg.ui.listViewPTNetworks.selectionModel().selection().indexes())>0):
                s="SELECT min(date), max(date) \
                   FROM tempus_gtfs.calendar_dates \
                   WHERE feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY" + str(self.PTNetworks) + ")"
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
                layerList[0].setSubsetString("ARRAY[feed_id] <@ ARRAY"+str(self.PTNetworks))
                if (layerList[0].extent().isEmpty()==False): 
                    self.iface.mapCanvas().setExtent(crd.transform(layerList[0].extent()))
            
            layerList = [layer for layer in QgsMapLayerRegistry.instance().mapLayers().values() if ((layer.name()==u"Itinéraires de ligne par mode") \
                                                                                                or (layer.name()==u"Arrêts") or (layer.name()==u"Arrêts par mode") \
                                                                                                or (layer.name()=="Sections par mode"))]
            for lyr in layerList:
                lyr.setSubsetString("feed_id IN (SELECT feed_id FROM tempus_gtfs.feed_info WHERE ARRAY[id] <@ ARRAY"+str(self.PTNetworks)+")")
            self.iface.mapCanvas().refresh()
    

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

