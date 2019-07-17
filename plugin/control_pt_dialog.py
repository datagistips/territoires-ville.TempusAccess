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

from config import *
from thread_tools import execute_external_cmd


sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_control_pt_dialog import Ui_Dialog

class control_pt_dialog(QDialog):

    def __init__(self, caller, iface):
        QDialog.__init__(self)
        self.ui= Ui_Dialog()
        self.ui.setupUi(self)
        self.caller = caller
        self.db = caller.db
        self.iface = caller.iface

        self._connectSlots()
        
        
    def _connectSlots(self):
        pass