#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
/**
 *   Copyright (C) 2018-2019 Cerema (https://www.cerema.fr)
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Library General Public
 *   License as published by the Free Software Foundation; either
 *   version 2 of the License, or (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Library General Public License for more details.
 *   You should have received a copy of the GNU Library General Public
 *   License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */
"""

# import the PyQt and QGIS libraries
from PyQt4.QtCore import *
from PyQt4.QtGui import *
from PyQt4.Qt import *
from PyQt4 import QtSql
from qgis.core import *
from qgis.utils import iface


# Initialize Qt resources from file resources.py
import subprocess
import resources
import sys
import string
import os

from config import *

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_manage_indicators_dialog import Ui_Dialog


class manage_indicators_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)        
        
        self.caller = caller
        self.iface = self.caller.iface
        
        self.plugin_dir = self.caller.plugin_dir
        
        self.ui.comboBoxColorIndic.setModel(self.caller.modelColorIndic)
        self.ui.comboBoxDerivedRepIndic.setModel(self.caller.modelDerivedRepIndic)
        self.ui.comboBoxSizeIndic.setModel(self.caller.modelSizeIndic)
        self.ui.comboBoxDerivedRep.setModel(self.caller.modelDerivedRep)
        self.ui.comboBoxPathID.setModel(self.caller.modelPathID)
        self.ui.comboBoxReq.setModel(self.caller.modelReq)
        self.ui.comboBoxRepMeth.setModel(self.caller.modelRepMeth)
        
        self.connectSlots()
    
    
    def connectSlots(self):        
        self.ui.pushButtonReqDelete.clicked.connect(self._slotPushButtonReqDeleteClicked)
        self.ui.pushButtonReqRename.clicked.connect(self._slotPushButtonReqRenameClicked)
        self.ui.pushButtonDerivedRepDelete.clicked.connect(self._slotPushButtonDerivedRepDeleteClicked)
        self.ui.pushButtonDerivedRepRename.clicked.connect(self._slotPushButtonDerivedRepRenameClicked)
        self.ui.pushButtonSaveComments.clicked.connect(self._slotPushButtonSaveCommentsClicked)
        self.ui.pushButtonDerivedRepGenerate.clicked.connect(self._slotPushButtonDerivedRepGenerateClicked)
        self.ui.comboBoxPathID.currentIndexChanged.connect(self._slotComboBoxPathIDIndexChanged)
        self.ui.pushButtonReqDisplay.clicked.connect(self._slotpushButtonReqDisplayClicked)
        self.ui.comboBoxSizeIndic.currentIndexChanged.connect(self._slotComboBoxSizeIndicIndexChanged)
        self.ui.comboBoxColorIndic.currentIndexChanged.connect(self._slotComboBoxColorIndicIndexChanged)
        self.ui.comboBoxDerivedRep.currentIndexChanged.connect(self._slotComboBoxDerivedRepIndexChanged)
        self.ui.comboBoxDerivedRepIndic.currentIndexChanged.connect(self._slotComboBoxDerivedRepIndicIndexChanged)
        self.ui.comboBoxReq.currentIndexChanged.connect(self._slotComboBoxReqIndexChanged)
        self.ui.buttonBox.button(QDialogButtonBox.Close).clicked.connect(self._slotClose)

        
    def _slotComboBoxReqIndexChanged(self, indexChosenLine):
        self.parent_layer=""
        if (indexChosenLine == 0):
            # General interface
            self.caller.dlg.ui.pushButtonIndicCalculate.setEnabled(True)
            self.caller.dlg.ui.pushButtonReinitCalc.setEnabled(True)
            self.comments = ""
            
            # 1st tab
            self.caller.dlg.ui.groupBoxObjType.setEnabled(True)
            self.caller.dlg.ui.groupBoxIndicators.setEnabled(True)
            self.caller.dlg.ui.toolBoxPaths.setEnabled(False)
            self.caller.dlg.ui.groupBoxPerimetre.setEnabled(True)
            self.caller.updateSelectedNodes()
            
            # 2nd tab
            self.caller.dlg.ui.groupBoxGTFSFeeds.setEnabled(True)
            self.caller.dlg.ui.groupBoxAgencies.setEnabled(True)
            self.caller.dlg.ui.groupBoxTransportModes.setEnabled(True)
            self.caller.dlg.ui.groupBoxForcStop.setEnabled(True)
            self.caller.dlg.ui.groupBoxForcRoute.setEnabled(True)
            
            # 3rd tab
            self.caller.dlg.ui.toolBoxDays.setEnabled(True)
            self.caller.dlg.ui.toolBoxTime.setEnabled(True)
            self.caller.dlg.ui.radioButtonTimePoint.setEnabled(False)
            
            # 4th tab
            
            self.ui.groupBoxSize.setEnabled(False)
            self.ui.groupBoxColor.setEnabled(False)
            self.ui.toolBoxDisplay.setItemEnabled(1, False)
            self.ui.pushButtonReqDisplay.setEnabled(False)
            self.ui.pushButtonReqRename.setEnabled(False)
            self.ui.pushButtonReqDelete.setEnabled(False)
            self.ui.pushButtonSaveComments.setEnabled(False)
            self.ui.comboBoxPathID.setEnabled(False)
            
            self.ui.textEditComments.setPlainText("")  
                    
        elif (indexChosenLine > 0):
            # 1st tab
            #####
            # "obj_type" field
            self.caller.dlg.ui.comboBoxObjType.setCurrentIndex(self.modelObjType.match(self.modelObjType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("obj_type"))[0].row())
            self.obj_def_name = self.modelObjType.record(self.caller.dlg.ui.comboBoxObjType.currentIndex()).value("def_name")
                        
            # Disables the groupBox since they should not be modified when an already calculated indicator is displayed
            self.caller.dlg.ui.groupBoxObjType.setEnabled(False)
            self.caller.dlg.ui.groupBoxPaths.setEnabled(False)
            self.caller.dlg.ui.groupBoxIndicators.setEnabled(False)
            self.caller.dlg.ui.groupBoxPerimetre.setEnabled(False)
            self.caller.dlg.ui.pushButtonIndicCalculate.setEnabled(False)
            
            # "area_type" and "areas" fields
            if (self.modelReq.record(indexChosenLine).isNull("area_type")==True):
                self.caller.dlg.ui.comboBoxAreaType.setCurrentIndex(0)
            else:
                self.caller.dlg.ui.comboBoxAreaType.setCurrentIndex(self.modelAreaType.match(self.modelAreaType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("area_type"))[0].row())
            
            self.caller.dlg.ui.comboBoxArea.setCurrentIndex(0)
            if (self.modelReq.record(indexChosenLine).isNull("areas")==False):
                for char_id in ((str(self.modelReq.record(indexChosenLine).value("areas"))).translate(None, "{}").split(",")):
                    self.caller.dlg.ui.comboBoxArea.setCurrentIndex(self.modelArea.match(self.modelArea.index(0,1), 0, char_id)[0].row())
            
            # "indics" field
            for indic in ((str(self.modelReq.record(indexChosenLine).value("indics"))).translate(None, "{}").split(",")):
                row = self.modelIndic.match(self.modelIndic.index(0,1), 0, indic, 1)[0].row()
                self.caller.dlg.ui.listViewIndic.selectionModel().select(self.modelIndic.index(row,0), QItemSelectionModel.Select)
            
            # origin and destination nodes
            if (self.modelReq.record(indexChosenLine).isNull("node_type")==False):
                self.node_type=self.modelReq.record(indexChosenLine).value("node_type")
                self.caller.dlg.ui.comboBoxNodeType.setCurrentIndex(self.modelNodeType.match(self.modelNodeType.index(0,1), 0, self.node_type)[0].row())
                i=0
                if (self.node_type==0): # Stop areas
                    i=4
            
            if (self.obj_def_name=="paths" or self.obj_def_name=="paths_details"):
                if (self.modelReq.record(indexChosenLine).isNull("o_node")==False) and (self.modelReq.record(indexChosenLine).isNull("d_node")==False):
                    self.caller.dlg.ui.comboBoxOrig.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("o_node"),1)[0].row())
                    self.caller.dlg.ui.comboBoxDest.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("d_node"),1)[0].row())
                        
            if (self.obj_def_name=="paths_tree"):
                if (self.modelReq.record(indexChosenLine).isNull("o_node")==False):
                    self.caller.dlg.ui.comboBoxPathsTreeRootNode.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("o_node"),1)[0].row())
                    self.caller.dlg.ui.comboBoxPathsTreeOD.setCurrentIndex(0)
                elif (self.modelReq.record(indexChosenLine).isNull("d_node")==False):
                    self.caller.dlg.ui.comboBoxPathsTreeRootNode.setCurrentIndex(self.modelNode.match(self.modelNode.index(0,i), 0, self.modelReq.record(indexChosenLine).value("d_node"),1)[0].row())
                    self.caller.dlg.ui.comboBoxPathsTreeOD.setCurrentIndex(1)
            
                        
            if (self.obj_def_name=="comb_paths_trees"):
                if (self.modelReq.record(indexChosenLine).isNull("nodes_ag")==False):
                    self.nodes_ag = self.modelReq.record(indexChosenLine).value("nodes_ag")
                    self.caller.dlg.ui.comboBoxNodeAg.setCurrentIndex(self.modelAgreg.match(self.modelAgreg.index(0,1), 0, self.nodes_ag)[0].row())
                else:
                    self.caller.dlg.ui.comboBoxNodeAg.setCurrentIndex(0)
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
            self.caller.dlg.ui.groupBoxGTFSFeeds.setEnabled(False)
            self.caller.dlg.ui.groupBoxAgencies.setEnabled(False)
            self.caller.dlg.ui.groupBoxTransportModes.setEnabled(False)
            self.caller.dlg.ui.groupBoxForcStop.setEnabled(False)
            self.caller.dlg.ui.groupBoxForcRoute.setEnabled(False)
                        
            # "stop" field
            if (self.modelReq.record(indexChosenLine).isNull("stop")==False):
                self.caller.dlg.ui.comboBoxForcStop.setCurrentIndex(self.modelStop.match(self.modelStop.index(0,1), 0, self.modelReq.record(indexChosenLine).value("stop"))[0].row())
            
            # "route" field
            if (self.modelReq.record(indexChosenLine).isNull("route")==False):
                self.caller.dlg.ui.comboBoxForcRoute.setCurrentIndex(self.modelRoute.match(self.modelRoute.index(0,1), 0, self.modelReq.record(indexChosenLine).value("route"))[0].row())
            
            # "agencies" field
            if (self.modelReq.record(indexChosenLine).isNull("agencies")==False):
                for i in ((str(self.modelReq.record(indexChosenLine).value("agencies"))).translate(None, "{}").split(",")):
                    row = self.modelAgencies.match(self.modelAgencies.index(0,3), 0, i, 1)[0].row()
                    self.caller.dlg.ui.tableViewAgencies.selectionModel().select(self.modelAgencies.index(row,0), QItemSelectionModel.Select)
            else:
                self.caller.dlg.ui.tableViewAgencies.clearSelection()
            
            # "gtfs_feeds" field
            if (self.modelReq.record(indexChosenLine).isNull("gtfs_feeds")==False):
                for feed in ((str(self.modelReq.record(indexChosenLine).value("gtfs_feeds"))).translate(None, "{}").split(",")):
                    row = self.modelPTSources.match(self.modelIndic.index(0,1), 0, feed, 1)[0].row()
                    self.caller.dlg.ui.listViewGTFSFeeds.selectionModel().select(self.modelPTSources.index(row,0), QItemSelectionModel.Select)
            
            # "pt_modes" field
            if (self.modelReq.record(indexChosenLine).isNull("pt_modes")==False):
                for i in ((str(self.modelReq.record(indexChosenLine).value("pt_modes"))).translate(None, "{}").split(",")):
                    if (i!="NULL"):
                        row = self.modelPTModes.match(self.modelPTModes.index(0,1), 0, i, 1)[0].row()
                        self.caller.dlg.ui.listViewPTModes.selectionModel().select(self.modelPTModes.index(row,0), QItemSelectionModel.Select)
            
            # "i_modes" field
            for i in ((str(self.modelReq.record(indexChosenLine).value("i_modes"))).translate(None, "{}").split(",")):
                if (i!="NULL"):
                    row = self.modelIModes.match(self.modelIModes.index(0,1), 0, i, 1)[0].row()
                    self.caller.dlg.ui.listViewIModes.selectionModel().select(self.modelIModes.index(row,0), QItemSelectionModel.Select)
            
            # 3rd tab
            #####
            self.caller.dlg.ui.toolBoxDays.setEnabled(False)
            self.caller.dlg.ui.toolBoxTime.setEnabled(False)
            self.caller.dlg.ui.radioButtonTimePoint.setEnabled(False)
            
            # "day" / "day_type", "per_start", "per_end", "day_ag" fields
            if (self.modelReq.record(indexChosenLine).isNull("day_type")==True):
                for day in ((str(self.modelReq.record(indexChosenLine).value("days"))).translate(None, "{}").split(",")):
                    self.caller.dlg.ui.calendarWidget.setSelectedDate(QDate.fromString(day, "yyyy-MM-dd"))
                self.caller.dlg.ui.radioButtonPreciseDate.setChecked(True)
            else:
                self.caller.dlg.ui.comboBoxDayType.setCurrentIndex(self.modelDayType.match(self.modelDayType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("day_type"))[0].row())
                self.caller.dlg.ui.radioButtonDayType.setChecked(True)
                self.caller.dlg.ui.dateEditPerStart.setDate(self.modelReq.record(indexChosenLine).value("per_start"))
                self.caller.dlg.ui.dateEditPerEnd.setDate(self.modelReq.record(indexChosenLine).value("per_end"))
                self.caller.dlg.ui.comboBoxPerType.setCurrentIndex(self.modelPerType.match(self.modelPerType.index(0,1), 0, self.modelReq.record(indexChosenLine).value("per_type"))[0].row())
                self.caller.dlg.ui.comboBoxDayAg.setCurrentIndex(self.modelAgreg.match(self.modelAgreg.index(0,1), 0, self.modelReq.record(indexChosenLine).value("day_ag"))[0].row())
            
            
            # "time_start", "time_end", "time_ag", "time_point" fields
            if (self.modelReq.record(indexChosenLine).isNull("time_start")==False):
                self.caller.dlg.ui.timeEditTimeStart.setTime(self.modelReq.record(indexChosenLine).value("time_start"))
                self.caller.dlg.ui.radioButtonTimePeriod.setChecked(True)
                self.caller.dlg.ui.timeEditTimeEnd.setTime(self.modelReq.record(indexChosenLine).value("time_end"))
            elif (self.modelReq.record(indexChosenLine).isNull("constraint_date_after")==False):
                self.radioButtonTimePoint.setChecked(True)
                self.timeEditTimePoint.setTime(self.modelReq.record(indexChosenLine).value("time_point"))
                self.comboBoxTimePointConstraint.setCurrentIndex(self.modelTimeConst.match(self.modelTimeConst.index(0,1), 0, self.modelReq.record(indexChosenLine).value("time_const"))[0].row())
            
            # 4th tab
            #####
            
            if ((self.obj_def_name== "stop_areas") or (self.obj_def_name == "stops") or (self.obj_def_name == "sections") or (self.obj_def_name=="trips")):
                self.caller.dlg.ui.groupBoxGeoQuery.setEnabled(True)
                self.caller.dlg.ui.groupBoxColor.setEnabled(True)
                self.caller.dlg.ui.groupBoxSize.setEnabled(True)
                self.caller.dlg.ui.comboBoxPathID.setEnabled(False)
                self.caller.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "paths") or (self.obj_def_name == "paths_details")):
                self.caller.dlg.ui.groupBoxGeoQuery.setEnabled(False)
                self.caller.dlg.ui.comboBoxPathID.setEnabled(True)
                if (self.obj_def_name=="paths"):
                    s="(SELECT 'Tous' as gid, -1 as gid_order) UNION (SELECT gid::character varying, gid FROM indic."+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+") ORDER BY gid_order"
                elif (self.obj_def_name=="paths_details"):
                    s="(SELECT 'Tous' as path_id, -1 as path_id_order) UNION (SELECT distinct path_id::character varying, path_id FROM indic."+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+") ORDER BY path_id_order"
                self.modelPathID.setQuery(unicode(s), self.db)
                self.caller.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "routes") or (self.obj_def_name == "agencies")):
                self.caller.dlg.ui.groupBoxGeoQuery.setEnabled(False)
                self.caller.dlg.ui.comboBoxPathID.setEnabled(False)
                self.caller.dlg.ui.toolBoxDisplay.setItemEnabled(1,False)
            elif ((self.obj_def_name == "paths_tree") or (self.obj_def_name == "comb_paths_trees")):
                self.caller.dlg.ui.groupBoxGeoQuery.setEnabled(True)
                self.caller.dlg.ui.groupBoxColor.setEnabled(True)
                self.caller.dlg.ui.groupBoxSize.setEnabled(True)
                self.caller.dlg.ui.comboBoxPathID.setEnabled(False)
                # Update available derived surface representations
                self.caller.dlg.ui.toolBoxDisplay.setItemEnabled(1,True)
                self.parent_layer = self.caller.dlg.ui.comboBoxReq.currentText()
                self.refreshDerivedRep()             
                self._slotComboBoxDerivedRepIndexChanged(0)
            
            self.caller.dlg.ui.pushButtonReqDisplay.setEnabled(True)
            self.caller.dlg.ui.pushButtonReqRename.setEnabled(True)
            self.caller.dlg.ui.pushButtonReqDelete.setEnabled(True)
            self.caller.dlg.ui.pushButtonSaveComments.setEnabled(True)
            
            # Update color and size indicators
            self.updateReqIndicators()
            
            
            # Display comments of the current layer
            s="SELECT coalesce(pg_catalog.obj_description((SELECT 'indic."+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"'::regclass::oid)), '');"
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.caller.dlg.ui.textEditComments.setPlainText(q.value(0))  
    
    
    def _slotComboBoxPathIDIndexChanged(self, indexChosenLine):
        for name, layer in QgsMapLayerRegistry.instance().mapLayers().iteritems(): 
                if (layer.name()==self.caller.dlg.ui.comboBoxReq.currentText()):
                    if (self.caller.dlg.ui.comboBoxPathID.currentText()!="Tous" and self.caller.dlg.ui.comboBoxPathID.currentText()!=""):
                        if (self.obj_def_name=="paths"):
                            layer.setSubsetString("gid = "+self.caller.dlg.ui.comboBoxPathID.currentText())
                        elif (self.obj_def_name=="paths_details"):
                            layer.setSubsetString("path_id = "+self.caller.dlg.ui.comboBoxPathID.currentText())
                    else:
                        layer.setSubsetString("")
        
    
    def _slotPushButtonReqDeleteClicked(self):
        ret = QMessageBox.question(self.dlg, "TempusAccess", u"La requête courante va être supprimée. \n Êtes vous certain(e) de vouloir faire cette opération ?", QMessageBox.Ok | QMessageBox.Cancel,QMessageBox.Cancel)
        if (ret == QMessageBox.Ok):
            for layer in self.node_indicators.findLayers():
                if (layer.name()==self.caller.dlg.ui.comboBoxReq.currentText()):
                    QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
            
            for i in range(0, self.modelDerivedRep.rowCount()):
                s="DROP TABLE indic."+self.modelDerivedRep.record(i).value(0)+";"
                q=QtSql.QSqlQuery(self.db)
                q.exec_(unicode(s))
            
            s="DROP TABLE indic."+self.caller.dlg.ui.comboBoxReq.currentText()+";\
            DELETE FROM tempus_access.indic_catalog WHERE layer_name = '"+self.caller.dlg.ui.comboBoxReq.currentText()+"' OR parent_layer = '"+self.caller.dlg.ui.comboBoxReq.currentText()+"';"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
            self.refreshReq()
        
        
    def _slotPushButtonReqRenameClicked(self):
        old_name = self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")
        new_name = self.caller.dlg.ui.comboBoxReq.currentText()
        s="ALTER TABLE indic."+old_name+" RENAME TO "+new_name+";\
        UPDATE tempus_access.indic_catalog SET layer_name = '"+new_name+"' WHERE layer_name = '"+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"';\
        UPDATE tempus_access.indic_catalog SET parent_layer = '"+new_name+"' WHERE parent_layer = '"+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+"';\
        ALTER TABLE indic."+new_name+"\
        RENAME CONSTRAINT "+old_name+"_pkey TO "+new_name+"_pkey";
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
        
        for layer in self.node_indicators.findLayers():
            if (layer.name()==old_name):
                QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
        
        self.refreshReq()
        
        self.caller.dlg.ui.comboBoxReq.setCurrentIndex(self.modelReq.match(self.modelReq.index(0,0), 0, new_name)[0].row())

        
    def _slotPushButtonSaveCommentsClicked(self):
        s="COMMENT ON TABLE indic."+self.modelReq.record(self.caller.dlg.ui.comboBoxReq.currentIndex()).value("layer_name")+" IS '"+unicode(self.caller.dlg.ui.textEditComments.toPlainText())+"';"
        
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
    
    
    def _slotComboBoxSizeIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT coalesce(min("+self.modelSizeIndic.record(indexChosenLine).value("col_name")+"), 0), coalesce(max("+self.modelSizeIndic.record(indexChosenLine).value("col_name")+"), 0) FROM indic."+self.caller.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.caller.dlg.ui.spinBoxSizeIndicMinValue.setEnabled(True)
            self.caller.dlg.ui.spinBoxSizeIndicMaxValue.setEnabled(True) 
            self.caller.dlg.ui.spinBoxSizeIndicMinValue.setValue(max(0,q.value(0)-1))
            self.caller.dlg.ui.spinBoxSizeIndicMaxValue.setValue(q.value(1))
        else:
            self.caller.dlg.ui.spinBoxSizeIndicMinValue.setEnabled(False)
            self.caller.dlg.ui.spinBoxSizeIndicMaxValue.setEnabled(False)
            self.caller.dlg.ui.spinBoxSizeIndicMinValue.setValue(0)
            self.caller.dlg.ui.spinBoxSizeIndicMaxValue.setValue(0)
        
    
    def _slotComboBoxColorIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT min("+self.modelColorIndic.record(indexChosenLine).value("col_name")+"), max("+self.modelColorIndic.record(indexChosenLine).value("col_name")+") FROM indic."+self.caller.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.caller.dlg.ui.spinBoxColorIndicMinValue.setEnabled(True)
            self.caller.dlg.ui.spinBoxColorIndicMaxValue.setEnabled(True) 
            self.caller.dlg.ui.spinBoxColorIndicMinValue.setValue(max(q.value(0),0))
            self.caller.dlg.ui.spinBoxColorIndicMaxValue.setValue(q.value(1))
        else:
            self.caller.dlg.ui.spinBoxColorIndicMinValue.setEnabled(False)
            self.caller.dlg.ui.spinBoxColorIndicMaxValue.setEnabled(False) 
    
    
    def _slotComboBoxDerivedRepIndexChanged(self, indexChosenLine):
        if ((self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")): 
            if (indexChosenLine==0): # Ready to generate iso-surfaces
                self.caller.dlg.ui.groupBoxParamDerivedRep.setEnabled(True)
                # Update available indicators for surface representation
                s="(\
                   SELECT lib, code, col_name FROM tempus_access.indicators \
                   WHERE sur_color = TRUE AND col_name IN \
                       (SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.caller.dlg.ui.comboBoxReq.currentText()+"')\
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
                
                self.caller.dlg.ui.pushButtonDerivedRepDelete.setEnabled(False)
                self.caller.dlg.ui.pushButtonDerivedRepRename.setEnabled(False)      
                self._slotComboBoxDerivedRepIndicIndexChanged(0)
            
            else: # Ready to display an already calculated isosurface
                self.caller.dlg.ui.groupBoxParamDerivedRep.setEnabled(False)
                self.caller.dlg.ui.pushButtonDerivedRepDelete.setEnabled(True)
                self.caller.dlg.ui.pushButtonDerivedRepRename.setEnabled(True)
                self.caller.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
                self.caller.dlg.ui.groupBoxSize.setEnabled(False)
                s="(\
                       SELECT lib, code, col_name FROM tempus_access.indicators \
                       WHERE sur_color = TRUE AND col_name IN \
                           (SELECT column_name FROM information_schema.columns WHERE table_schema = 'indic' AND table_name = '"+self.caller.dlg.ui.comboBoxDerivedRep.currentText()+"') \
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
                if (layer.name()==self.caller.dlg.ui.comboBoxDerivedRep.currentText()):
                    QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
                    
            s="DROP TABLE indic."+self.caller.dlg.ui.comboBoxDerivedRep.currentText()+";\
            DELETE FROM tempus_access.indic_catalog WHERE layer_name = '"+self.caller.dlg.ui.comboBoxDerivedRep.currentText()+"';"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
            self.refreshDerivedRep()
            
        
    def _slotPushButtonDerivedRepRenameClicked(self):
        old_name = self.modelDerivedRep.record(self.caller.dlg.ui.comboBoxDerivedRep.currentIndex()).value("layer_name")
        new_name = self.caller.dlg.ui.comboBoxDerivedRep.currentText()
        s="ALTER TABLE indic."+old_name+" RENAME TO "+new_name+";\
        UPDATE tempus_access.indic_catalog SET layer_name = '"+new_name+"' WHERE layer_name = '"+self.modelDerivedRep.record(self.caller.dlg.ui.comboBoxDerivedRep.currentIndex()).value("layer_name")+"';\
        ALTER TABLE indic."+new_name+"\
        RENAME CONSTRAINT "+old_name+"_pkey TO "+new_name+"_pkey";
        q=QtSql.QSqlQuery(self.db)
        q.exec_(unicode(s))
        
        for layer in self.node_indicators.findLayers():
            if (layer.name()==old_name):
                QgsMapLayerRegistry.instance().removeMapLayer(layer.layer().id())
        
        self.refreshDerivedRep()
        
        self.caller.dlg.ui.comboBoxDerivedRep.setCurrentIndex(self.modelDerivedRep.match(self.modelDerivedRep.index(0,0), 0, new_name)[0].row())

            
    def _slotComboBoxDerivedRepIndicIndexChanged(self, indexChosenLine):
        if (indexChosenLine>0):
            s="SELECT min("+self.modelDerivedRepIndic.record(indexChosenLine).value("col_name")+"), max("+self.modelDerivedRepIndic.record(indexChosenLine).value("col_name")+") FROM indic."+self.caller.dlg.ui.comboBoxReq.currentText()
            q=QtSql.QSqlQuery(unicode(s), self.db)
            q.next()
            self.caller.dlg.ui.spinBoxDerivedRepIndicMinValue.setEnabled(True)
            self.caller.dlg.ui.spinBoxDerivedRepIndicMaxValue.setEnabled(True)
            self.caller.dlg.ui.spinBoxDerivedRepIndicMinValue.setValue(q.value(0))
            self.caller.dlg.ui.spinBoxDerivedRepIndicMaxValue.setRange(1, q.value(1))
            self.caller.dlg.ui.spinBoxDerivedRepIndicMaxValue.setValue(q.value(1))
            self.caller.dlg.ui.spinBoxDerivedRepIndicMaxValue.setRange(1, q.value(1))
            self.caller.dlg.ui.spinBoxDerivedRepClasses.setRange(1, q.value(1))
            if (self.caller.dlg.ui.comboBoxDerivedRep.currentText()==""):
                self.caller.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(True)
            else:
                self.caller.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
        else:
            self.caller.dlg.ui.pushButtonDerivedRepGenerate.setEnabled(False)
            self.caller.dlg.ui.spinBoxDerivedRepIndicMinValue.setEnabled(False)
            self.caller.dlg.ui.spinBoxDerivedRepIndicMaxValue.setEnabled(False)
            self.caller.dlg.ui.spinBoxColorIndicMinValue.setValue(0)
            self.caller.dlg.ui.spinBoxColorIndicMaxValue.setValue(0)
                
    
    def _slotPushButtonDerivedRepGenerateClicked(self):
        self.isosurfaces=True
        self.buildQuery()
        r=QtSql.QSqlQuery(self.db)
        done=r.exec_(self.query)
        self._slotResultAvailable(done, self.query)
    
    
    def _slotpushButtonReqDisplayClicked(self):
        size_indic_name=self.modelSizeIndic.record(self.caller.dlg.ui.comboBoxSizeIndic.currentIndex()).value("col_name")
        color_indic_name=self.modelColorIndic.record(self.caller.dlg.ui.comboBoxColorIndic.currentIndex()).value("col_name")
        
        self.caller.dlg.ui.labelElapsedTime.setText("")
               
        if (size_indic_name!=""):
            s="SELECT tempus_access.map_indicator('"+self.caller.dlg.ui.comboBoxReq.currentText()+"', '"+size_indic_name+"', 'size', "+str(self.caller.dlg.ui.spinBoxSizeIndicMinValue.value())+", "+str(self.caller.dlg.ui.spinBoxSizeIndicMaxValue.value())+", "+str(self.caller.dlg.ui.doubleSpinBoxSize.value())+")"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        elif (self.obj_def_name != "paths_tree") and (self.obj_def_name != "comb_paths_trees"):
            s="UPDATE indic."+self.caller.dlg.ui.comboBoxReq.currentText()+" SET symbol_size = 1"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        
        if (color_indic_name!=""):
            s="SELECT tempus_access.map_indicator('"+self.caller.dlg.ui.comboBoxReq.currentText()+"', '"+color_indic_name+"', 'color', "+str(self.caller.dlg.ui.spinBoxColorIndicMinValue.value())+", "+str(self.caller.dlg.ui.spinBoxColorIndicMaxValue.value())+", 1)"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s))
        elif (self.obj_def_name != "paths_tree") and (self.obj_def_name != "comb_paths_trees"):
            s="UPDATE indic."+self.caller.dlg.ui.comboBoxReq.currentText()+" SET symbol_color = 1"
            q=QtSql.QSqlQuery(self.db)
            q.exec_(unicode(s)) 
        
        for layer in self.node_indicators.findLayers():
            self.iface.legendInterface().setLayerVisible(layer.layer(), False)
        
        # Stop areas or stops
        if (((self.obj_def_name=="stops") or (self.obj_def_name=="stop_areas")) and self.caller.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/stops_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif (((self.obj_def_name=="stops") or (self.obj_def_name=="stop_areas")) and self.caller.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/stops_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Sections
        elif ((self.obj_def_name=="sections") and self.caller.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif ((self.obj_def_name=="sections") and self.caller.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Trips
        elif ((self.obj_def_name=="trips") and self.caller.dlg.ui.radioButtonScreenUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_screen_unit.qml', 'gid', "the_geom", '')
        elif ((self.obj_def_name=="trips") and self.caller.dlg.ui.radioButtonMapUnit.isChecked()):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + '/styles/sections_by_mode_prop_size_prop_color_map_unit.qml', 'gid', "the_geom", '')
        # Routes or agencies
        elif ((self.obj_def_name =="routes") or (self.obj_def_name=="agencies")):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), '', 'gid', None, '')
        # Paths
        elif (self.obj_def_name == "paths"):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/paths.qml", "gid", "the_geom", "")
        elif (self.obj_def_name=="paths_details"):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/paths_by_mode.qml", "gid", "the_geom", "") 
        # Paths tree described by nodes
        elif (self.obj_def_name=="paths_tree") and (self.caller.dlg.ui.toolBoxDisplay.currentIndex()==0):            
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_nodes.qml", "to_node", "geom_point", "") 
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_edges.qml", "to_node", "geom_section", "")
        elif ((self.obj_def_name=="paths_tree") or (self.obj_def_name=="comb_paths_trees")) and (self.caller.dlg.ui.toolBoxDisplay.currentIndex()==1):
            self.indicDisplay(self.caller.dlg.ui.comboBoxDerivedRep.currentText(), self.plugin_dir + "/styles/isochrons_surfaces.qml", "id", "geom", "")
        elif (self.obj_def_name=="comb_paths_trees") and (self.caller.dlg.ui.toolBoxDisplay.currentIndex()==0):
            self.indicDisplay(self.caller.dlg.ui.comboBoxReq.currentText(), self.plugin_dir + "/styles/isochrons_nodes.qml", "id", "geom", "")
        
        if (self.obj_def_name == "paths" or self.obj_def_name=="paths_details" or self.obj_def_name=="paths_tree" or self.obj_def_name=="comb_paths_trees"):
            for layer in self.node_indicators.findLayers():
                if (layer.name()== "Destinations" or layer.name() == "Origines"):
                    self.iface.legendInterface().setLayerVisible(layer.layer(), True)   
       
    def _slotClose(self):
        self.hide()
