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
from Ui_set_db_connection_dialog import Ui_Dialog


class set_db_connection_dialog(QDialog): 

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)        
        
        self.caller = caller
        self.iface = self.caller.iface
        
        self.ui.lineEdit_login.setText(os.getenv("USERNAME"))
        
        # Connexion des signaux et des slots
        self._connectSlots()
        
        
    def _connectSlots(self):
        self.ui.buttonBox.button(QDialogButtonBox.Apply).clicked.connect(self._slotApply)
        self.ui.buttonBox.button(QDialogButtonBox.Cancel).clicked.connect(self._slotCancel)
    
    
    def _slotApply(self):
        self.refreshDBList()
        self.caller.manage_db_dialog.show()
        self.hide()
    
    
    def _slotCancel(self):
        self.hide()
    
    
    def refreshDBList(self):
        self.caller.db.setHostName(str(self.ui.lineEdit_host.text()))
        self.caller.db.setUserName(str(self.ui.lineEdit_login.text()))
        self.caller.db.setPort(int(self.ui.lineEdit_port.text()))
        self.caller.db.setPassword(self.ui.lineEdit_pwd.text())
        self.caller.db.setDatabaseName("postgres")
        
        self.caller.db.open() 
        
        s="select substring(datname from 14 for length(datname)) as datname from pg_database\
            WHERE datname like 'tempusaccess_%'\
            ORDER BY 1";            
        self.caller.modelDB.setQuery(s, self.caller.db)
    
 
    
       

