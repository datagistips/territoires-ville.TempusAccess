# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_import_road_dialog.ui'
#
# Created: Fri Feb 08 09:18:47 2019
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
        Dialog.resize(533, 300)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(440, 260, 81, 41))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(10, 11, 511, 245))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.lineEditVisumModes = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditVisumModes.setObjectName(_fromUtf8("lineEditVisumModes"))
        self.gridLayout.addWidget(self.lineEditVisumModes, 7, 1, 2, 1)
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 1, 0, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.comboBoxFormatVersion = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormatVersion.setObjectName(_fromUtf8("comboBoxFormatVersion"))
        self.gridLayout.addWidget(self.comboBoxFormatVersion, 1, 1, 1, 1)
        self.labelSRID = QtGui.QLabel(self.layoutWidget)
        self.labelSRID.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelSRID.setObjectName(_fromUtf8("labelSRID"))
        self.gridLayout.addWidget(self.labelSRID, 5, 0, 1, 1)
        self.labelPrefix = QtGui.QLabel(self.layoutWidget)
        self.labelPrefix.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelPrefix.setObjectName(_fromUtf8("labelPrefix"))
        self.gridLayout.addWidget(self.labelPrefix, 2, 0, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 0, 1, 1, 1)
        self.spinBoxSRID = QtGui.QSpinBox(self.layoutWidget)
        self.spinBoxSRID.setMaximum(9999)
        self.spinBoxSRID.setProperty("value", 2154)
        self.spinBoxSRID.setObjectName(_fromUtf8("spinBoxSRID"))
        self.gridLayout.addWidget(self.spinBoxSRID, 5, 1, 1, 1)
        self.labelChoose = QtGui.QLabel(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelChoose.sizePolicy().hasHeightForWidth())
        self.labelChoose.setSizePolicy(sizePolicy)
        self.labelChoose.setWhatsThis(_fromUtf8(""))
        self.labelChoose.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelChoose.setObjectName(_fromUtf8("labelChoose"))
        self.gridLayout.addWidget(self.labelChoose, 9, 0, 1, 1)
        self.labelEncoding = QtGui.QLabel(self.layoutWidget)
        self.labelEncoding.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelEncoding.setObjectName(_fromUtf8("labelEncoding"))
        self.gridLayout.addWidget(self.labelEncoding, 6, 0, 1, 1)
        self.labelSourceName = QtGui.QLabel(self.layoutWidget)
        self.labelSourceName.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelSourceName.setObjectName(_fromUtf8("labelSourceName"))
        self.gridLayout.addWidget(self.labelSourceName, 3, 0, 1, 1)
        self.lineEditPrefix = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditPrefix.setObjectName(_fromUtf8("lineEditPrefix"))
        self.gridLayout.addWidget(self.lineEditPrefix, 2, 1, 1, 1)
        self.comboBoxEncoding = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxEncoding.setEditable(True)
        self.comboBoxEncoding.setObjectName(_fromUtf8("comboBoxEncoding"))
        self.gridLayout.addWidget(self.comboBoxEncoding, 6, 1, 1, 1)
        self.pushButtonChoose = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonChoose.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChoose.sizePolicy().hasHeightForWidth())
        self.pushButtonChoose.setSizePolicy(sizePolicy)
        self.pushButtonChoose.setObjectName(_fromUtf8("pushButtonChoose"))
        self.gridLayout.addWidget(self.pushButtonChoose, 9, 1, 1, 1)
        self.labelVisumModes1 = QtGui.QLabel(self.layoutWidget)
        self.labelVisumModes1.setAlignment(QtCore.Qt.AlignBottom|QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing)
        self.labelVisumModes1.setObjectName(_fromUtf8("labelVisumModes1"))
        self.gridLayout.addWidget(self.labelVisumModes1, 7, 0, 1, 1)
        self.lineEditSourceName = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceName.setObjectName(_fromUtf8("lineEditSourceName"))
        self.gridLayout.addWidget(self.lineEditSourceName, 3, 1, 1, 1)
        self.labelVisumModes2 = QtGui.QLabel(self.layoutWidget)
        self.labelVisumModes2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTop|QtCore.Qt.AlignTrailing)
        self.labelVisumModes2.setObjectName(_fromUtf8("labelVisumModes2"))
        self.gridLayout.addWidget(self.labelVisumModes2, 8, 0, 1, 1)
        self.labelSourceComment = QtGui.QLabel(self.layoutWidget)
        self.labelSourceComment.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelSourceComment.setObjectName(_fromUtf8("labelSourceComment"))
        self.gridLayout.addWidget(self.labelSourceComment, 4, 0, 1, 1)
        self.lineEditSourceComment = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceComment.setObjectName(_fromUtf8("lineEditSourceComment"))
        self.gridLayout.addWidget(self.lineEditSourceComment, 4, 1, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer un réseau routier", None))
        self.label_3.setText(_translate("Dialog", "Version du modèle de données", None))
        self.label.setText(_translate("Dialog", "Type données source *", None))
        self.labelSRID.setText(_translate("Dialog", "SRID *", None))
        self.labelPrefix.setText(_translate("Dialog", "Préfixe fichiers", None))
        self.labelChoose.setText(_translate("Dialog", "Choisir le dossier", None))
        self.labelEncoding.setText(_translate("Dialog", "Encodage de caractères *", None))
        self.labelSourceName.setText(_translate("Dialog", "Nom court source de données *", None))
        self.pushButtonChoose.setToolTip(_translate("Dialog", "<html><head/><body><p>Le bouton n\'est accessible qu\'après avoir renseigné un nom pour le réseau. </p></body></html>", None))
        self.pushButtonChoose.setText(_translate("Dialog", "Parcourir...", None))
        self.labelVisumModes1.setText(_translate("Dialog", "Codification des modes (marche,vélo,voiture,taxi)", None))
        self.labelVisumModes2.setText(_translate("Dialog", "séparateur \",\", sans espace", None))
        self.labelSourceComment.setText(_translate("Dialog", "Commentaire source de données", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

