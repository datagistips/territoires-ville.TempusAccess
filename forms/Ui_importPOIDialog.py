# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_importPOIDialog.ui'
#
# Created: Thu Oct 25 17:01:16 2018
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
        Dialog.resize(473, 218)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(380, 180, 81, 31))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 11, 451, 161))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 1, 0, 1, 1)
        self.spinBoxSRID = QtGui.QSpinBox(self.layoutWidget)
        self.spinBoxSRID.setMaximum(9999)
        self.spinBoxSRID.setProperty("value", 2154)
        self.spinBoxSRID.setObjectName(_fromUtf8("spinBoxSRID"))
        self.gridLayout.addWidget(self.spinBoxSRID, 3, 1, 1, 1)
        self.pushButtonChooseDir = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonChooseDir.setEnabled(True)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChooseDir.sizePolicy().hasHeightForWidth())
        self.pushButtonChooseDir.setSizePolicy(sizePolicy)
        self.pushButtonChooseDir.setObjectName(_fromUtf8("pushButtonChooseDir"))
        self.gridLayout.addWidget(self.pushButtonChooseDir, 5, 1, 1, 1)
        self.lineEditPrefix = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditPrefix.setObjectName(_fromUtf8("lineEditPrefix"))
        self.gridLayout.addWidget(self.lineEditPrefix, 2, 1, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 3, 0, 1, 1)
        self.comboBoxFormatVersion = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormatVersion.setObjectName(_fromUtf8("comboBoxFormatVersion"))
        self.gridLayout.addWidget(self.comboBoxFormatVersion, 1, 1, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 0, 1, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.comboBoxEncoding = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxEncoding.setEditable(True)
        self.comboBoxEncoding.setObjectName(_fromUtf8("comboBoxEncoding"))
        self.gridLayout.addWidget(self.comboBoxEncoding, 4, 1, 1, 1)
        self.labelPath = QtGui.QLabel(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelPath.sizePolicy().hasHeightForWidth())
        self.labelPath.setSizePolicy(sizePolicy)
        self.labelPath.setWhatsThis(_fromUtf8(""))
        self.labelPath.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelPath.setObjectName(_fromUtf8("labelPath"))
        self.gridLayout.addWidget(self.labelPath, 5, 0, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget)
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout.addWidget(self.label_4, 2, 0, 1, 1)
        self.label_5 = QtGui.QLabel(self.layoutWidget)
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.gridLayout.addWidget(self.label_5, 4, 0, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer un réseau routier", None))
        self.label_3.setText(_translate("Dialog", "Version du modèle de données", None))
        self.pushButtonChooseDir.setToolTip(_translate("Dialog", "<html><head/><body><p>Le bouton n\'est accessible qu\'après avoir renseigné un préfixe pour la source. Le préfixe doit être différent de ceux des sources déjà importées (voir liste ci-dessous). </p><p>Attention : la source doit être un fichier .zip contenant directement les fichiers .txt, aucun dossier ne doit être inclus dans le fichier .zip. </p></body></html>", None))
        self.pushButtonChooseDir.setText(_translate("Dialog", "Parcourir...", None))
        self.label_2.setText(_translate("Dialog", "SRID", None))
        self.label.setText(_translate("Dialog", "Type données source", None))
        self.labelPath.setText(_translate("Dialog", "Choisir le dossier", None))
        self.label_4.setText(_translate("Dialog", "Préfixe fichiers", None))
        self.label_5.setText(_translate("Dialog", "Encodage de caractères", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

