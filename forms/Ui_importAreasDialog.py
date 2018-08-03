# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_importAreasDialog.ui'
#
# Created: Fri Jun 22 23:10:13 2018
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
        Dialog.resize(582, 221)
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 10, 561, 171))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 1, 0, 1, 1)
        self.label_5 = QtGui.QLabel(self.layoutWidget)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.gridLayout.addWidget(self.label_5, 3, 0, 1, 1)
        self.label_6 = QtGui.QLabel(self.layoutWidget)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout.addWidget(self.label_6, 4, 0, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout.addWidget(self.label_4, 2, 0, 1, 1)
        self.lineEditAreasName = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditAreasName.setObjectName(_fromUtf8("lineEditAreasName"))
        self.gridLayout.addWidget(self.lineEditAreasName, 1, 1, 1, 1)
        self.lineEditAreasID = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditAreasID.setObjectName(_fromUtf8("lineEditAreasID"))
        self.gridLayout.addWidget(self.lineEditAreasID, 2, 1, 1, 1)
        self.pushButtonImportAreas = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonImportAreas.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonImportAreas.sizePolicy().hasHeightForWidth())
        self.pushButtonImportAreas.setSizePolicy(sizePolicy)
        self.pushButtonImportAreas.setObjectName(_fromUtf8("pushButtonImportAreas"))
        self.gridLayout.addWidget(self.pushButtonImportAreas, 4, 1, 1, 1)
        self.lineEditAreasLib = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditAreasLib.setObjectName(_fromUtf8("lineEditAreasLib"))
        self.gridLayout.addWidget(self.lineEditAreasLib, 3, 1, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.lineEditSRID = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSRID.setObjectName(_fromUtf8("lineEditSRID"))
        self.gridLayout.addWidget(self.lineEditSRID, 0, 1, 1, 1)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(410, 190, 156, 23))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer des données de zonage", None))
        self.label_3.setText(_translate("Dialog", "Nom du zonage", None))
        self.label_5.setText(_translate("Dialog", "Nom du champ libellé de zone (de type \"caractères\")", None))
        self.label_6.setText(_translate("Dialog", "Choisir le fichier", None))
        self.label_4.setText(_translate("Dialog", "Nom du champ identifiant de zone (clé primaire de type \"caractères\")", None))
        self.lineEditAreasName.setText(_translate("Dialog", "Zonage XXX", None))
        self.lineEditAreasID.setText(_translate("Dialog", "char_id", None))
        self.pushButtonImportAreas.setText(_translate("Dialog", "Parcourir...", None))
        self.lineEditAreasLib.setText(_translate("Dialog", "nom_zone", None))
        self.label.setText(_translate("Dialog", "Code SRID (4326 pour WGS84, 2154 pour Lambert93)", None))
        self.lineEditSRID.setText(_translate("Dialog", "2154", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

