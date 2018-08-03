# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_manageGTFSDialog.ui'
#
# Created: Sun Jun 24 18:52:48 2018
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
        Dialog.resize(292, 130)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(100, 90, 181, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Cancel|QtGui.QDialogButtonBox.Ok)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.verticalLayoutWidget = QtGui.QWidget(Dialog)
        self.verticalLayoutWidget.setGeometry(QtCore.QRect(20, 10, 261, 71))
        self.verticalLayoutWidget.setObjectName(_fromUtf8("verticalLayoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.verticalLayoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label_8 = QtGui.QLabel(self.verticalLayoutWidget)
        self.label_8.setObjectName(_fromUtf8("label_8"))
        self.gridLayout.addWidget(self.label_8, 0, 0, 1, 1)
        self.comboBoxGTFSFeeds = QtGui.QComboBox(self.verticalLayoutWidget)
        self.comboBoxGTFSFeeds.setObjectName(_fromUtf8("comboBoxGTFSFeeds"))
        self.gridLayout.addWidget(self.comboBoxGTFSFeeds, 0, 1, 1, 1)
        self.pushButtonDeleteGTFSFeed = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonDeleteGTFSFeed.setObjectName(_fromUtf8("pushButtonDeleteGTFSFeed"))
        self.gridLayout.addWidget(self.pushButtonDeleteGTFSFeed, 1, 0, 1, 1)
        self.pushButtonExportGTFSFeed = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonExportGTFSFeed.setObjectName(_fromUtf8("pushButtonExportGTFSFeed"))
        self.gridLayout.addWidget(self.pushButtonExportGTFSFeed, 1, 1, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Gérer les sources GTFS", None))
        self.label_8.setText(_translate("Dialog", "Choisir la source :", None))
        self.pushButtonDeleteGTFSFeed.setText(_translate("Dialog", "Supprimer source", None))
        self.pushButtonExportGTFSFeed.setText(_translate("Dialog", "Exporter source", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

