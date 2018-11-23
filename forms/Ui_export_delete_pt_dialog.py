# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_export_delete_pt_dialog.ui'
#
# Created: Thu Nov 22 13:16:56 2018
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
        Dialog.resize(538, 128)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(350, 90, 181, 41))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.verticalLayoutWidget = QtGui.QWidget(Dialog)
        self.verticalLayoutWidget.setGeometry(QtCore.QRect(20, 10, 511, 71))
        self.verticalLayoutWidget.setObjectName(_fromUtf8("verticalLayoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.verticalLayoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label = QtGui.QLabel(self.verticalLayoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.comboBoxSourceName = QtGui.QComboBox(self.verticalLayoutWidget)
        self.comboBoxSourceName.setObjectName(_fromUtf8("comboBoxSourceName"))
        self.gridLayout.addWidget(self.comboBoxSourceName, 0, 1, 1, 1)
        self.pushButtonDelete = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonDelete.setObjectName(_fromUtf8("pushButtonDelete"))
        self.gridLayout.addWidget(self.pushButtonDelete, 1, 0, 1, 1)
        self.pushButtonExport = QtGui.QPushButton(self.verticalLayoutWidget)
        self.pushButtonExport.setObjectName(_fromUtf8("pushButtonExport"))
        self.gridLayout.addWidget(self.pushButtonExport, 1, 1, 1, 1)
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(20, 100, 421, 22))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.layoutWidget)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_5 = QtGui.QLabel(self.layoutWidget)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.horizontalLayout.addWidget(self.label_5)
        self.lineEditCommand = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditCommand.setEnabled(False)
        self.lineEditCommand.setObjectName(_fromUtf8("lineEditCommand"))
        self.horizontalLayout.addWidget(self.lineEditCommand)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Gérer les données d\'offre de transport en commun", None))
        self.label.setText(_translate("Dialog", "Nom de la source *", None))
        self.pushButtonDelete.setText(_translate("Dialog", "Supprimer source", None))
        self.pushButtonExport.setText(_translate("Dialog", "Exporter source", None))
        self.label_5.setText(_translate("Dialog", "Dernière commande exécutée", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

