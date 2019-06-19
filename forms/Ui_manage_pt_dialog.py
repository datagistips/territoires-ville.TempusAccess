# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_manage_pt_dialog.ui'
#
# Created: Mon Jun 17 14:03:05 2019
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
        Dialog.resize(543, 268)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(340, 220, 181, 41))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.groupBoxPTNetworks = QtGui.QGroupBox(Dialog)
        self.groupBoxPTNetworks.setGeometry(QtCore.QRect(10, 110, 521, 111))
        self.groupBoxPTNetworks.setObjectName(_fromUtf8("groupBoxPTNetworks"))
        self.listViewPTNetworks = QtGui.QListView(self.groupBoxPTNetworks)
        self.listViewPTNetworks.setGeometry(QtCore.QRect(10, 30, 151, 71))
        self.listViewPTNetworks.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.listViewPTNetworks.setAlternatingRowColors(True)
        self.listViewPTNetworks.setSelectionMode(QtGui.QAbstractItemView.MultiSelection)
        self.listViewPTNetworks.setSelectionBehavior(QtGui.QAbstractItemView.SelectRows)
        self.listViewPTNetworks.setObjectName(_fromUtf8("listViewPTNetworks"))
        self.layoutWidget = QtGui.QWidget(self.groupBoxPTNetworks)
        self.layoutWidget.setGeometry(QtCore.QRect(180, 40, 331, 25))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.layoutWidget)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.horizontalLayout.addWidget(self.label_2)
        self.lineEditMergedPTNetwork = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditMergedPTNetwork.setObjectName(_fromUtf8("lineEditMergedPTNetwork"))
        self.horizontalLayout.addWidget(self.lineEditMergedPTNetwork)
        self.pushButtonMerge = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonMerge.setEnabled(False)
        self.pushButtonMerge.setObjectName(_fromUtf8("pushButtonMerge"))
        self.horizontalLayout.addWidget(self.pushButtonMerge)
        self.groupBox = QtGui.QGroupBox(Dialog)
        self.groupBox.setGeometry(QtCore.QRect(10, 10, 521, 91))
        self.groupBox.setObjectName(_fromUtf8("groupBox"))
        self.verticalLayoutWidget = QtGui.QWidget(self.groupBox)
        self.verticalLayoutWidget.setGeometry(QtCore.QRect(10, 20, 501, 61))
        self.verticalLayoutWidget.setObjectName(_fromUtf8("verticalLayoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.verticalLayoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.comboBoxSourceName = QtGui.QComboBox(self.verticalLayoutWidget)
        self.comboBoxSourceName.setObjectName(_fromUtf8("comboBoxSourceName"))
        self.gridLayout.addWidget(self.comboBoxSourceName, 0, 1, 1, 1)
        self.label = QtGui.QLabel(self.verticalLayoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.pushButtonDelete = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonDelete.setObjectName(_fromUtf8("pushButtonDelete"))
        self.gridLayout.addWidget(self.pushButtonDelete, 0, 2, 1, 1)
        self.pushButtonExport = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonExport.setObjectName(_fromUtf8("pushButtonExport"))
        self.gridLayout.addWidget(self.pushButtonExport, 1, 2, 1, 1)
        self.label_3 = QtGui.QLabel(self.verticalLayoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 1, 0, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.verticalLayoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 1, 1, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Gérer les données d\'offre de transport en commun", None))
        self.groupBoxPTNetworks.setTitle(_translate("Dialog", "Fusionner des offres de transport en commun", None))
        self.label_2.setText(_translate("Dialog", "Nom offre fusionnée", None))
        self.pushButtonMerge.setText(_translate("Dialog", "Fusionner", None))
        self.groupBox.setTitle(_translate("Dialog", "Supprimer ou exporter des offres de transport en commun", None))
        self.label.setText(_translate("Dialog", "Nom de la source *", None))
        self.pushButtonDelete.setText(_translate("Dialog", "Supprimer", None))
        self.pushButtonExport.setText(_translate("Dialog", "Exporter", None))
        self.label_3.setText(_translate("Dialog", "Format", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

