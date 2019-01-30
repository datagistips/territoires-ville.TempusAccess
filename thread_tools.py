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

from PyQt4.Qt import *
from PyQt4.QtGui import *
from PyQt4 import QtSql
from PyQt4.QtGui import QDockWidget

from config import *

import os
import sys
import string
import subprocess
import qgis
import platform 

# Thread for general import/export operations

def display_and_clear_python_console():
    pythonConsole = qgis.utils.iface.mainWindow().findChild( QDockWidget, 'PythonConsole' )
    #pythonConsole.console.shellOut.clearConsole()
    if not pythonConsole.isVisible():
        pythonConsole.setVisible( True )


def execute_external_cmd( cmd ):
    pythonConsole = qgis.utils.iface.mainWindow().findChild( QDockWidget, 'PythonConsole' )
    # pythonConsole.console.shellOut.clearConsole()
    if not pythonConsole.isVisible():
        pythonConsole.setVisible( True )
    
    if ((platform.system() == 'Windows')):# and (platform.release() == '7')):
        line_cmd = string.replace( cmd[0] + ' "' +'" "'.join(cmd[1:]) + '"', '\\', '/' )
        r = os.system (line_cmd)
        print line_cmd
        return r
    else:
        r = subprocess.Popen( cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT )
        while True:
            output = r.stdout.readline()
            if output == '' and r.poll() is not None:
                break
            if output:
                print output.strip()
        return r.poll()
    

# Thread for general indicators building (no path calculation)
class genIndicThread(QThread):
    resultAvailable = pyqtSignal(bool, str)

    def __init__(self, query_str, db, file, parent = None):
        super(genIndicThread, self).__init__(parent)
        self.query_str = query_str
        self.db = db
        self.file = file
        if (file!=None):
            f=open(file, "w").write(query_str)
            f.close()
    
    def __del__(self):
        self.wait()
        
    def run(self): 
        if (file==None):
            r=QtSql.QSqlQuery(self.db)
            done=r.exec_(self.query_str)
        else:
            done=True
        self.resultAvailable.emit(done, self.query_str)

        
class pathIndicThread(QThread):
    resultAvailable = pyqtSignal(bool, str)
    
    def __init__(self, query_str, db, dbstring, road_node_from, road_node_to, road_nodes, time_start, time_end, time_ag, time_point, time_interval, all_services, days, tran_modes, path_tree, max_cost, walking_speed, cycling_speed, constraint_date_after, parent = None):
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
        self.plugin_dir = os.path.dirname(__file__) 
        
        self.file = open(self.plugin_dir+"/scripts/temp.sql", "w")
        
    def __del__(self):
        self.wait() 
    
    def buildGraph(self):
        if (self.path_tree==True):
            s="DELETE FROM tempus_access.tempus_paths_tree_results; SELECT init_isochrone_plugin('"+self.dbstring+"');\n"
            print s
            self.file.write(s)
        else:
            s="DELETE FROM tempus_access.tempus_paths_results; SELECT init_multimodal_plugin('"+self.dbstring+"');\n"
            print s
            self.file.write(s)    
        
    def run(self):
        self.buildGraph()
        
        for d in self.days:
            if (self.time_point != "NULL"): # Simple time constraint
                if (self.path_tree==False): 
                    s = "SELECT tempus_access.shortest_path2(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+d + " " +self.time_point[1:len(self.time_point)-1]+"'::timestamp, "+str(self.constraint_date_after)+");\n"
                    print s
                    self.file.write(s)
                else:   
                    for node in self.road_nodes: # For each source node
                        s = "SELECT tempus_access.shortest_paths_tree(("+str(node)+"), ARRAY"+str(self.tran_modes)+", "+str(self.max_cost)+", "+str(self.walking_speed)+", "+str(self.cycling_speed)+", '"+d \
                            + " " +self.time_point[1:len(self.time_point)-1]+"'::timestamp, "+str(self.constraint_date_after)+");\n"
                        print s
                        self.file.write(s)
            
            else: # Time period constraint
                if (self.all_services==True): # All possible services of the period - only fo simple paths 
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
                        s = "SELECT tempus_access.shortest_path2(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");\n"
                        print s
                        self.file.write(s) 
                        
                        s1 = "SELECT next_pt_timestamp::character varying FROM tempus_access.next_pt_timestamp("+bound_time+"::time, '"+str(d)+"'::date, "+str(self.constraint_date_after)+")"
                        print s1
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
                    
                    while (current_timestamp != bound_timestamp):
                        if (self.path_tree==False): 
                            s = "SELECT tempus_access.shortest_path(("+str(self.road_node_from)+"), ("+str(self.road_node_to)+"), ARRAY"+str(self.tran_modes)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");\n"
                            print s
                            self.file.write(s)
                                                        
                        elif (self.path_tree==True):
                            for node in self.road_nodes: # For each source/target node
                                s = "SELECT tempus_access.shortest_paths_tree("+str(node)+", ARRAY"+str(self.tran_modes)+", "+str(self.max_cost)+", "+str(self.walking_speed)+", "+str(self.cycling_speed)+", '"+current_timestamp+"'::timestamp, "+str(self.constraint_date_after)+");\n"
                                print s
                                self.file.write(s)
                                
                        s1 = "SELECT next_timestamp::character varying FROM tempus_access.next_timestamp('"+current_timestamp+"'::timestamp, "+str(self.time_interval)+", '"+bound_timestamp+"'::timestamp, "+str(self.constraint_date_after)+")"
                        print s1
                        q1=QtSql.QSqlQuery(self.db)
                        q1.exec_(unicode(s1))
                        while q1.next():
                            current_timestamp = str(q1.value(0))       
                        
        print(self.query_str)
        self.file.write(self.query_str) 
        
        self.file.close()
        
        cmd = [ PSQL, "-h", self.db.hostName(), "-p", str(self.db.port()), "-d", self.db.databaseName(), "-U", self.db.userName(), "-f", self.plugin_dir+"\\scripts\\temp.sql" ]
        done = execute_external_cmd(cmd)
        res=False
        if (done==0):
            res=True
        self.resultAvailable.emit(res, self.query_str)
        
        
        
        