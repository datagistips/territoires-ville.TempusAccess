# -*- coding: utf-8 -*-
"""
/***************************************************************************
 TempusAccessDockWidget
                                 A QGIS plugin
 Analyse de l'offre de transport en commun au format GTFS
                             -------------------
        begin                : 2017-01-26
        git sha              : $Format:%H$
        copyright            : (C) 2017 by Cerema
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

import sys, os

from PyQt4 import QtGui, uic
from PyQt4.QtCore import pyqtSignal
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "\\forms")
from Ui_TempusAccess_dock_widget import Ui_DockWidget

FORM_CLASS, _ = uic.loadUiType(os.path.join(
    os.path.dirname(__file__) + "\\forms", 'Ui_TempusAccess_dock_widget.ui'))


class TempusAccess_dock_widget(QtGui.QDockWidget, FORM_CLASS):

    closingPlugin = pyqtSignal()

    def __init__(self, parent=None):
        """Constructor."""
        super(TempusAccess_dock_widget, self).__init__(parent)
        # Set up the user interface from Designer.
        # After setupUI you can access any designer object by doing
        # self.<objectname>, and you can use autoconnect slots - see
        # http://qt-project.org/doc/qt-4.8/designer-using-a-ui-file.html
        # #widgets-and-dialogs-with-auto-connect
        self.ui = Ui_DockWidget()
        self.ui.setupUi(self)

    def closeEvent(self, event):
        self.closingPlugin.emit()
        event.accept()

