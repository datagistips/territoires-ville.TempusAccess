# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_merge_pt_dialog.ui'
#
# Created: Tue Jul 16 14:47:31 2019
#      by: PyQt4 UI code generator 4.10.2
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

try:
    _fromUtf8 = QtCore.QString.fromUtf8
except AttributeError:
    def _fromUtf8(s):
        return s

try:
    _encoding = QtGui.QApplication.UnicodeUTF8
    def _translate(context, text, disambig):
        return QtGui.QApplication.translate(context, text, disambig, _encoding)
except AttributeError:
    def _translate(context, text, disambig):
        return QtGui.QApplication.translate(context, text, disambig)

class Ui_Dialog(object):
    def setupUi(self, Dialog):
        Dialog.setObjectName(_fromUtf8("Dialog"))
        Dialog.resize(599, 196)
        self.layoutWidget_2 = QtGui.QWidget(Dialog)
        self.layoutWidget_2.setGeometry(QtCore.QRect(10, 10, 501, 176))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.gridLayout_3 = QtGui.QGridLayout(self.layoutWidget_2)
        self.gridLayout_3.setMargin(0)
        self.gridLayout_3.setObjectName(_fromUtf8("gridLayout_3"))
        self.checkBoxServices = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxServices.setObjectName(_fromUtf8("checkBoxServices"))
        self.gridLayout_3.addWidget(self.checkBoxServices, 4, 2, 1, 1)
        self.checkBoxAgencies = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxAgencies.setObjectName(_fromUtf8("checkBoxAgencies"))
        self.gridLayout_3.addWidget(self.checkBoxAgencies, 3, 3, 1, 1)
        self.pushButtonChooseTransfersFile = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonChooseTransfersFile.setObjectName(_fromUtf8("pushButtonChooseTransfersFile"))
        self.gridLayout_3.addWidget(self.pushButtonChooseTransfersFile, 2, 4, 1, 1)
        self.label_6 = QtGui.QLabel(self.layoutWidget_2)
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTop|QtCore.Qt.AlignTrailing)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout_3.addWidget(self.label_6, 4, 0, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget_2)
        self.label_4.setAlignment(QtCore.Qt.AlignBottom|QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout_3.addWidget(self.label_4, 3, 0, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget_2)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout_3.addWidget(self.label_2, 0, 0, 1, 1)
        self.label_7 = QtGui.QLabel(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.label_7.sizePolicy().hasHeightForWidth())
        self.label_7.setSizePolicy(sizePolicy)
        self.label_7.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_7.setObjectName(_fromUtf8("label_7"))
        self.gridLayout_3.addWidget(self.label_7, 2, 0, 1, 1)
        self.checkBoxFares = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxFares.setObjectName(_fromUtf8("checkBoxFares"))
        self.gridLayout_3.addWidget(self.checkBoxFares, 4, 4, 1, 1)
        self.checkBoxShapes = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxShapes.setObjectName(_fromUtf8("checkBoxShapes"))
        self.gridLayout_3.addWidget(self.checkBoxShapes, 4, 3, 1, 1)
        self.label_5 = QtGui.QLabel(self.layoutWidget_2)
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.gridLayout_3.addWidget(self.label_5, 1, 0, 1, 1)
        self.checkBoxRoutes = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxRoutes.setObjectName(_fromUtf8("checkBoxRoutes"))
        self.gridLayout_3.addWidget(self.checkBoxRoutes, 3, 4, 1, 1)
        self.checkBoxTrips = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxTrips.setObjectName(_fromUtf8("checkBoxTrips"))
        self.gridLayout_3.addWidget(self.checkBoxTrips, 4, 1, 1, 1)
        self.checkBoxStops = QtGui.QCheckBox(self.layoutWidget_2)
        self.checkBoxStops.setObjectName(_fromUtf8("checkBoxStops"))
        self.gridLayout_3.addWidget(self.checkBoxStops, 3, 1, 1, 2)
        self.labelTransfersFile = QtGui.QLabel(self.layoutWidget_2)
        self.labelTransfersFile.setObjectName(_fromUtf8("labelTransfersFile"))
        self.gridLayout_3.addWidget(self.labelTransfersFile, 2, 1, 1, 3)
        self.lineEditMergedPTNetwork = QtGui.QLineEdit(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEditMergedPTNetwork.sizePolicy().hasHeightForWidth())
        self.lineEditMergedPTNetwork.setSizePolicy(sizePolicy)
        self.lineEditMergedPTNetwork.setObjectName(_fromUtf8("lineEditMergedPTNetwork"))
        self.gridLayout_3.addWidget(self.lineEditMergedPTNetwork, 0, 1, 1, 4)
        self.listViewPTNetworks = QtGui.QListView(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Expanding)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.listViewPTNetworks.sizePolicy().hasHeightForWidth())
        self.listViewPTNetworks.setSizePolicy(sizePolicy)
        self.listViewPTNetworks.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.listViewPTNetworks.setAlternatingRowColors(True)
        self.listViewPTNetworks.setSelectionMode(QtGui.QAbstractItemView.MultiSelection)
        self.listViewPTNetworks.setSelectionBehavior(QtGui.QAbstractItemView.SelectRows)
        self.listViewPTNetworks.setObjectName(_fromUtf8("listViewPTNetworks"))
        self.gridLayout_3.addWidget(self.listViewPTNetworks, 1, 1, 1, 4)
        self.pushButtonMerge = QtGui.QPushButton(Dialog)
        self.pushButtonMerge.setEnabled(False)
        self.pushButtonMerge.setGeometry(QtCore.QRect(520, 80, 71, 23))
        self.pushButtonMerge.setObjectName(_fromUtf8("pushButtonMerge"))

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Fusionner des offres de transport collectif", None))
        self.checkBoxServices.setText(_translate("Dialog", "Services", None))
        self.checkBoxAgencies.setText(_translate("Dialog", "Opérateurs", None))
        self.pushButtonChooseTransfersFile.setText(_translate("Dialog", "...", None))
        self.label_6.setText(_translate("Dialog", "lorsqu\'ils ont un identifiant commun", None))
        self.label_4.setText(_translate("Dialog", "Choisir les types d\'objets à fusionner", None))
        self.label_2.setText(_translate("Dialog", "Nom offre fusionnée", None))
        self.label_7.setText(_translate("Dialog", "Fichier de correspondance entre arrêts", None))
        self.checkBoxFares.setText(_translate("Dialog", "Tarifs", None))
        self.checkBoxShapes.setText(_translate("Dialog", "Tracés", None))
        self.label_5.setText(_translate("Dialog", "Offres à fusionner", None))
        self.checkBoxRoutes.setText(_translate("Dialog", "Lignes", None))
        self.checkBoxTrips.setText(_translate("Dialog", "Trajets", None))
        self.checkBoxStops.setText(_translate("Dialog", "Arrêts et zones d\'arrêt", None))
        self.labelTransfersFile.setText(_translate("Dialog", "...", None))
        self.pushButtonMerge.setText(_translate("Dialog", "Fusionner", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

