# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_import_poi_dialog.ui'
#
# Created: Mon Nov 26 16:54:12 2018
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
        Dialog.resize(534, 320)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(440, 280, 81, 41))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 11, 511, 261))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.pushButtonChoose = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonChoose.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChoose.sizePolicy().hasHeightForWidth())
        self.pushButtonChoose.setSizePolicy(sizePolicy)
        self.pushButtonChoose.setObjectName(_fromUtf8("pushButtonChoose"))
        self.gridLayout.addWidget(self.pushButtonChoose, 8, 1, 1, 1)
        self.lineEditPrefix = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditPrefix.setObjectName(_fromUtf8("lineEditPrefix"))
        self.gridLayout.addWidget(self.lineEditPrefix, 4, 1, 1, 1)
        self.comboBoxFormatVersion = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormatVersion.setObjectName(_fromUtf8("comboBoxFormatVersion"))
        self.gridLayout.addWidget(self.comboBoxFormatVersion, 3, 1, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 1, 1, 1, 1)
        self.spinBoxSRID = QtGui.QSpinBox(self.layoutWidget)
        self.spinBoxSRID.setMaximum(9999)
        self.spinBoxSRID.setProperty("value", 2154)
        self.spinBoxSRID.setObjectName(_fromUtf8("spinBoxSRID"))
        self.gridLayout.addWidget(self.spinBoxSRID, 5, 1, 1, 1)
        self.lineEditSourceName = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceName.setObjectName(_fromUtf8("lineEditSourceName"))
        self.gridLayout.addWidget(self.lineEditSourceName, 0, 1, 1, 1)
        self.labelFilter = QtGui.QLabel(self.layoutWidget)
        self.labelFilter.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelFilter.setObjectName(_fromUtf8("labelFilter"))
        self.gridLayout.addWidget(self.labelFilter, 7, 0, 1, 1)
        self.lineEditFilter = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditFilter.setObjectName(_fromUtf8("lineEditFilter"))
        self.gridLayout.addWidget(self.lineEditFilter, 7, 1, 1, 1)
        self.labelPath = QtGui.QLabel(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelPath.sizePolicy().hasHeightForWidth())
        self.labelPath.setSizePolicy(sizePolicy)
        self.labelPath.setWhatsThis(_fromUtf8(""))
        self.labelPath.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelPath.setObjectName(_fromUtf8("labelPath"))
        self.gridLayout.addWidget(self.labelPath, 8, 0, 1, 1)
        self.label_6 = QtGui.QLabel(self.layoutWidget)
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout.addWidget(self.label_6, 0, 0, 1, 1)
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 3, 0, 1, 1)
        self.comboBoxEncoding = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxEncoding.setEditable(True)
        self.comboBoxEncoding.setObjectName(_fromUtf8("comboBoxEncoding"))
        self.gridLayout.addWidget(self.comboBoxEncoding, 6, 1, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 1, 0, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 5, 0, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget)
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout.addWidget(self.label_4, 4, 0, 1, 1)
        self.label_5 = QtGui.QLabel(self.layoutWidget)
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.gridLayout.addWidget(self.label_5, 6, 0, 1, 1)
        self.label_7 = QtGui.QLabel(self.layoutWidget)
        self.label_7.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_7.setObjectName(_fromUtf8("label_7"))
        self.gridLayout.addWidget(self.label_7, 2, 0, 1, 1)
        self.comboBoxPOIType = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxPOIType.setObjectName(_fromUtf8("comboBoxPOIType"))
        self.gridLayout.addWidget(self.comboBoxPOIType, 2, 1, 1, 1)
        self.layoutWidget_2 = QtGui.QWidget(Dialog)
        self.layoutWidget_2.setGeometry(QtCore.QRect(10, 290, 421, 22))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.layoutWidget_2)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_8 = QtGui.QLabel(self.layoutWidget_2)
        self.label_8.setObjectName(_fromUtf8("label_8"))
        self.horizontalLayout.addWidget(self.label_8)
        self.lineEditCommand = QtGui.QLineEdit(self.layoutWidget_2)
        self.lineEditCommand.setObjectName(_fromUtf8("lineEditCommand"))
        self.horizontalLayout.addWidget(self.lineEditCommand)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer des points d\'intérêt", None))
        self.pushButtonChoose.setToolTip(_translate("Dialog", "<html><head/><body><p>Le bouton n\'est accessible qu\'après avoir renseigné un préfixe pour la source. Le préfixe doit être différent de ceux des sources déjà importées (voir liste ci-dessous). </p><p>Attention : la source doit être un fichier .zip contenant directement les fichiers .txt, aucun dossier ne doit être inclus dans le fichier .zip. </p></body></html>", None))
        self.pushButtonChoose.setText(_translate("Dialog", "Parcourir...", None))
        self.labelFilter.setText(_translate("Dialog", "Filtre (clause WHERE)", None))
        self.labelPath.setText(_translate("Dialog", "Choisir le dossier *", None))
        self.label_6.setText(_translate("Dialog", "Nom de la source ou du service *", None))
        self.label_3.setText(_translate("Dialog", "Version du modèle de données", None))
        self.label.setText(_translate("Dialog", "Type de données source *", None))
        self.label_2.setText(_translate("Dialog", "SRID *", None))
        self.label_4.setText(_translate("Dialog", "Préfixe fichiers", None))
        self.label_5.setText(_translate("Dialog", "Encodage de caractères *", None))
        self.label_7.setText(_translate("Dialog", "Type de POI *", None))
        self.label_8.setText(_translate("Dialog", "Dernière commande exécutée", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

