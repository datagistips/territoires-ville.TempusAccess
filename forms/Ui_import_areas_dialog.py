# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_import_areas_dialog.ui'
#
# Created: Mon Nov 26 16:54:10 2018
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
        Dialog.resize(534, 355)
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 10, 511, 291))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.spinBoxSRID = QtGui.QSpinBox(self.layoutWidget)
        self.spinBoxSRID.setMaximum(9999)
        self.spinBoxSRID.setProperty("value", 2154)
        self.spinBoxSRID.setObjectName(_fromUtf8("spinBoxSRID"))
        self.gridLayout.addWidget(self.spinBoxSRID, 4, 1, 1, 1)
        self.lineEditSourceName = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceName.setObjectName(_fromUtf8("lineEditSourceName"))
        self.gridLayout.addWidget(self.lineEditSourceName, 0, 1, 1, 1)
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 0, 0, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 1, 0, 1, 1)
        self.label_8 = QtGui.QLabel(self.layoutWidget)
        self.label_8.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_8.setObjectName(_fromUtf8("label_8"))
        self.gridLayout.addWidget(self.label_8, 3, 0, 1, 1)
        self.comboBoxFormatVersion = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormatVersion.setObjectName(_fromUtf8("comboBoxFormatVersion"))
        self.gridLayout.addWidget(self.comboBoxFormatVersion, 2, 1, 1, 1)
        self.label_7 = QtGui.QLabel(self.layoutWidget)
        self.label_7.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_7.setObjectName(_fromUtf8("label_7"))
        self.gridLayout.addWidget(self.label_7, 2, 0, 1, 1)
        self.lineEditPrefix = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditPrefix.setObjectName(_fromUtf8("lineEditPrefix"))
        self.gridLayout.addWidget(self.lineEditPrefix, 3, 1, 1, 1)
        self.comboBoxEncoding = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxEncoding.setEditable(True)
        self.comboBoxEncoding.setObjectName(_fromUtf8("comboBoxEncoding"))
        self.gridLayout.addWidget(self.comboBoxEncoding, 5, 1, 1, 1)
        self.label_9 = QtGui.QLabel(self.layoutWidget)
        self.label_9.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_9.setObjectName(_fromUtf8("label_9"))
        self.gridLayout.addWidget(self.label_9, 5, 0, 1, 1)
        self.labelFilter = QtGui.QLabel(self.layoutWidget)
        self.labelFilter.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelFilter.setObjectName(_fromUtf8("labelFilter"))
        self.gridLayout.addWidget(self.labelFilter, 6, 0, 1, 1)
        self.lineEditFilter = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditFilter.setObjectName(_fromUtf8("lineEditFilter"))
        self.gridLayout.addWidget(self.lineEditFilter, 6, 1, 1, 1)
        self.lineEditAreasID = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditAreasID.setObjectName(_fromUtf8("lineEditAreasID"))
        self.gridLayout.addWidget(self.lineEditAreasID, 7, 1, 1, 1)
        self.lineEditAreasLib = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditAreasLib.setObjectName(_fromUtf8("lineEditAreasLib"))
        self.gridLayout.addWidget(self.lineEditAreasLib, 8, 1, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget)
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout.addWidget(self.label_4, 7, 0, 1, 1)
        self.pushButtonChoose = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonChoose.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChoose.sizePolicy().hasHeightForWidth())
        self.pushButtonChoose.setSizePolicy(sizePolicy)
        self.pushButtonChoose.setObjectName(_fromUtf8("pushButtonChoose"))
        self.gridLayout.addWidget(self.pushButtonChoose, 9, 1, 1, 1)
        self.label_5 = QtGui.QLabel(self.layoutWidget)
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.gridLayout.addWidget(self.label_5, 8, 0, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 4, 0, 1, 1)
        self.label_6 = QtGui.QLabel(self.layoutWidget)
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout.addWidget(self.label_6, 9, 0, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 1, 1, 1, 1)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(440, 310, 81, 41))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget_2 = QtGui.QWidget(Dialog)
        self.layoutWidget_2.setGeometry(QtCore.QRect(10, 320, 421, 22))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.layoutWidget_2)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_10 = QtGui.QLabel(self.layoutWidget_2)
        self.label_10.setObjectName(_fromUtf8("label_10"))
        self.horizontalLayout.addWidget(self.label_10)
        self.lineEditCommand = QtGui.QLineEdit(self.layoutWidget_2)
        self.lineEditCommand.setObjectName(_fromUtf8("lineEditCommand"))
        self.horizontalLayout.addWidget(self.lineEditCommand)

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer des données de zonage", None))
        self.lineEditSourceName.setText(_translate("Dialog", "Zonage XXX", None))
        self.label_3.setText(_translate("Dialog", "Nom du zonage *", None))
        self.label_2.setText(_translate("Dialog", "Type de données source *", None))
        self.label_8.setText(_translate("Dialog", "Préfixe fichiers", None))
        self.label_7.setText(_translate("Dialog", "Version du modèle de données", None))
        self.label_9.setText(_translate("Dialog", "Encodage de caractères *", None))
        self.labelFilter.setText(_translate("Dialog", "Filtre (clause WHERE)", None))
        self.lineEditAreasID.setText(_translate("Dialog", "char_id", None))
        self.lineEditAreasLib.setText(_translate("Dialog", "nom_zone", None))
        self.label_4.setText(_translate("Dialog", "Champ identifiant (clé primaire)", None))
        self.pushButtonChoose.setText(_translate("Dialog", "Parcourir...", None))
        self.label_5.setText(_translate("Dialog", "Champ libellé", None))
        self.label.setText(_translate("Dialog", "SRID *", None))
        self.label_6.setText(_translate("Dialog", "Choisir le fichier", None))
        self.label_10.setText(_translate("Dialog", "Dernière commande exécutée", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

