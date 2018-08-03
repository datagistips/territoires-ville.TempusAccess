# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\GTFSAnalyst\forms\Ui_importOtherDataDialog.ui'
#
# Created: Mon Feb 26 11:30:54 2018
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
        Dialog.resize(582, 311)
        self.groupBox = QtGui.QGroupBox(Dialog)
        self.groupBox.setGeometry(QtCore.QRect(10, 20, 551, 81))
        self.groupBox.setObjectName(_fromUtf8("groupBox"))
        self.horizontalLayoutWidget = QtGui.QWidget(self.groupBox)
        self.horizontalLayoutWidget.setGeometry(QtCore.QRect(10, 30, 301, 36))
        self.horizontalLayoutWidget.setObjectName(_fromUtf8("horizontalLayoutWidget"))
        self.horizontalLayout_2 = QtGui.QHBoxLayout(self.horizontalLayoutWidget)
        self.horizontalLayout_2.setMargin(0)
        self.horizontalLayout_2.setObjectName(_fromUtf8("horizontalLayout_2"))
        self.label_2 = QtGui.QLabel(self.horizontalLayoutWidget)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.horizontalLayout_2.addWidget(self.label_2)
        self.pushButtonImporterPerimetres = QtGui.QPushButton(self.horizontalLayoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonImporterPerimetres.sizePolicy().hasHeightForWidth())
        self.pushButtonImporterPerimetres.setSizePolicy(sizePolicy)
        self.pushButtonImporterPerimetres.setObjectName(_fromUtf8("pushButtonImporterPerimetres"))
        self.horizontalLayout_2.addWidget(self.pushButtonImporterPerimetres)
        self.groupBox_4 = QtGui.QGroupBox(Dialog)
        self.groupBox_4.setGeometry(QtCore.QRect(10, 210, 551, 81))
        self.groupBox_4.setObjectName(_fromUtf8("groupBox_4"))
        self.horizontalLayoutWidget_4 = QtGui.QWidget(self.groupBox_4)
        self.horizontalLayoutWidget_4.setGeometry(QtCore.QRect(10, 30, 531, 36))
        self.horizontalLayoutWidget_4.setObjectName(_fromUtf8("horizontalLayoutWidget_4"))
        self.horizontalLayout_5 = QtGui.QHBoxLayout(self.horizontalLayoutWidget_4)
        self.horizontalLayout_5.setMargin(0)
        self.horizontalLayout_5.setObjectName(_fromUtf8("horizontalLayout_5"))
        self.label_3 = QtGui.QLabel(self.horizontalLayoutWidget_4)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.horizontalLayout_5.addWidget(self.label_3)
        self.pushButtonImporterVacances = QtGui.QPushButton(self.horizontalLayoutWidget_4)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonImporterVacances.sizePolicy().hasHeightForWidth())
        self.pushButtonImporterVacances.setSizePolicy(sizePolicy)
        self.pushButtonImporterVacances.setObjectName(_fromUtf8("pushButtonImporterVacances"))
        self.horizontalLayout_5.addWidget(self.pushButtonImporterVacances)
        self.checkBoxAjouterVacancesSco = QtGui.QCheckBox(self.horizontalLayoutWidget_4)
        self.checkBoxAjouterVacancesSco.setChecked(True)
        self.checkBoxAjouterVacancesSco.setObjectName(_fromUtf8("checkBoxAjouterVacancesSco"))
        self.horizontalLayout_5.addWidget(self.checkBoxAjouterVacancesSco)
        self.groupBox_6 = QtGui.QGroupBox(Dialog)
        self.groupBox_6.setGeometry(QtCore.QRect(10, 120, 551, 81))
        self.groupBox_6.setObjectName(_fromUtf8("groupBox_6"))
        self.horizontalLayoutWidget_6 = QtGui.QWidget(self.groupBox_6)
        self.horizontalLayoutWidget_6.setGeometry(QtCore.QRect(10, 30, 301, 36))
        self.horizontalLayoutWidget_6.setObjectName(_fromUtf8("horizontalLayoutWidget_6"))
        self.horizontalLayout_7 = QtGui.QHBoxLayout(self.horizontalLayoutWidget_6)
        self.horizontalLayout_7.setMargin(0)
        self.horizontalLayout_7.setObjectName(_fromUtf8("horizontalLayout_7"))
        self.label_6 = QtGui.QLabel(self.horizontalLayoutWidget_6)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.horizontalLayout_7.addWidget(self.label_6)
        self.pushButtonImporterArrets = QtGui.QPushButton(self.horizontalLayoutWidget_6)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonImporterArrets.sizePolicy().hasHeightForWidth())
        self.pushButtonImporterArrets.setSizePolicy(sizePolicy)
        self.pushButtonImporterArrets.setObjectName(_fromUtf8("pushButtonImporterArrets"))
        self.horizontalLayout_7.addWidget(self.pushButtonImporterArrets)

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer d\'autres sources que les données GTFS", None))
        self.groupBox.setTitle(_translate("Dialog", "Importer les périmètres administratifs (IGN AdminExpress)", None))
        self.label_2.setText(_translate("Dialog", "Choisir le dossier", None))
        self.pushButtonImporterPerimetres.setText(_translate("Dialog", "Parcourir...", None))
        self.groupBox_4.setTitle(_translate("Dialog", "Importer les périodes de vacances scolaires (fichier .dbf spécifique - voir doc)", None))
        self.label_3.setText(_translate("Dialog", "Choisir le fichier", None))
        self.pushButtonImporterVacances.setText(_translate("Dialog", "Parcourir...", None))
        self.checkBoxAjouterVacancesSco.setText(_translate("Dialog", "Ajouter aux données existantes", None))
        self.groupBox_6.setTitle(_translate("Dialog", "Importer un référentiel d\'arrêts", None))
        self.label_6.setText(_translate("Dialog", "Choisir le fichier", None))
        self.pushButtonImporterArrets.setText(_translate("Dialog", "Parcourir...", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

