# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_import_zoning_dialog.ui'
#
# Created: Fri Feb 08 09:18:42 2019
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
        self.layoutWidget.setGeometry(QtCore.QRect(10, 10, 511, 304))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.lineEditSourceName = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceName.setText(_fromUtf8(""))
        self.lineEditSourceName.setObjectName(_fromUtf8("lineEditSourceName"))
        self.gridLayout.addWidget(self.lineEditSourceName, 3, 1, 1, 1)
        self.labelSourceComment = QtGui.QLabel(self.layoutWidget)
        self.labelSourceComment.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelSourceComment.setObjectName(_fromUtf8("labelSourceComment"))
        self.gridLayout.addWidget(self.labelSourceComment, 4, 0, 1, 1)
        self.label_9 = QtGui.QLabel(self.layoutWidget)
        self.label_9.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_9.setObjectName(_fromUtf8("label_9"))
        self.gridLayout.addWidget(self.label_9, 6, 0, 1, 1)
        self.labelNameField = QtGui.QLabel(self.layoutWidget)
        self.labelNameField.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelNameField.setObjectName(_fromUtf8("labelNameField"))
        self.gridLayout.addWidget(self.labelNameField, 9, 0, 1, 1)
        self.labelIdField = QtGui.QLabel(self.layoutWidget)
        self.labelIdField.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelIdField.setObjectName(_fromUtf8("labelIdField"))
        self.gridLayout.addWidget(self.labelIdField, 8, 0, 1, 1)
        self.comboBoxEncoding = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxEncoding.setEditable(True)
        self.comboBoxEncoding.setObjectName(_fromUtf8("comboBoxEncoding"))
        self.gridLayout.addWidget(self.comboBoxEncoding, 6, 1, 1, 1)
        self.pushButtonChoose = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonChoose.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChoose.sizePolicy().hasHeightForWidth())
        self.pushButtonChoose.setSizePolicy(sizePolicy)
        self.pushButtonChoose.setObjectName(_fromUtf8("pushButtonChoose"))
        self.gridLayout.addWidget(self.pushButtonChoose, 10, 1, 1, 1)
        self.lineEditNameField = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditNameField.setText(_fromUtf8(""))
        self.lineEditNameField.setObjectName(_fromUtf8("lineEditNameField"))
        self.gridLayout.addWidget(self.lineEditNameField, 9, 1, 1, 1)
        self.spinBoxSRID = QtGui.QSpinBox(self.layoutWidget)
        self.spinBoxSRID.setMaximum(9999)
        self.spinBoxSRID.setProperty("value", 2154)
        self.spinBoxSRID.setObjectName(_fromUtf8("spinBoxSRID"))
        self.gridLayout.addWidget(self.spinBoxSRID, 5, 1, 1, 1)
        self.label_7 = QtGui.QLabel(self.layoutWidget)
        self.label_7.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_7.setObjectName(_fromUtf8("label_7"))
        self.gridLayout.addWidget(self.label_7, 1, 0, 1, 1)
        self.lineEditSourceComment = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditSourceComment.setObjectName(_fromUtf8("lineEditSourceComment"))
        self.gridLayout.addWidget(self.lineEditSourceComment, 4, 1, 1, 1)
        self.labelPrefix = QtGui.QLabel(self.layoutWidget)
        self.labelPrefix.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelPrefix.setObjectName(_fromUtf8("labelPrefix"))
        self.gridLayout.addWidget(self.labelPrefix, 2, 0, 1, 1)
        self.lineEditPrefix = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditPrefix.setObjectName(_fromUtf8("lineEditPrefix"))
        self.gridLayout.addWidget(self.lineEditPrefix, 2, 1, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 5, 0, 1, 1)
        self.comboBoxFormatVersion = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormatVersion.setObjectName(_fromUtf8("comboBoxFormatVersion"))
        self.gridLayout.addWidget(self.comboBoxFormatVersion, 1, 1, 1, 1)
        self.labelChoose = QtGui.QLabel(self.layoutWidget)
        self.labelChoose.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelChoose.setObjectName(_fromUtf8("labelChoose"))
        self.gridLayout.addWidget(self.labelChoose, 10, 0, 1, 1)
        self.labelFilter = QtGui.QLabel(self.layoutWidget)
        self.labelFilter.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelFilter.setObjectName(_fromUtf8("labelFilter"))
        self.gridLayout.addWidget(self.labelFilter, 7, 0, 1, 1)
        self.lineEditFilter = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditFilter.setObjectName(_fromUtf8("lineEditFilter"))
        self.gridLayout.addWidget(self.lineEditFilter, 7, 1, 1, 1)
        self.labelZoningName = QtGui.QLabel(self.layoutWidget)
        self.labelZoningName.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelZoningName.setObjectName(_fromUtf8("labelZoningName"))
        self.gridLayout.addWidget(self.labelZoningName, 3, 0, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 0, 0, 1, 1)
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 0, 1, 1, 1)
        self.lineEditIdField = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditIdField.setText(_fromUtf8(""))
        self.lineEditIdField.setObjectName(_fromUtf8("lineEditIdField"))
        self.gridLayout.addWidget(self.lineEditIdField, 8, 1, 1, 1)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(440, 310, 81, 41))
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer des données de zonage", None))
        self.labelSourceComment.setText(_translate("Dialog", "Commentaire source de données", None))
        self.label_9.setText(_translate("Dialog", "Encodage de caractères *", None))
        self.labelNameField.setText(_translate("Dialog", "Champ libellé *", None))
        self.labelIdField.setText(_translate("Dialog", "Champ identifiant (clé primaire) *", None))
        self.pushButtonChoose.setText(_translate("Dialog", "Parcourir...", None))
        self.label_7.setText(_translate("Dialog", "Version du modèle de données", None))
        self.labelPrefix.setText(_translate("Dialog", "Préfixe fichiers", None))
        self.label.setText(_translate("Dialog", "SRID *", None))
        self.labelChoose.setText(_translate("Dialog", "Choisir le fichier", None))
        self.labelFilter.setText(_translate("Dialog", "Filtre (clause WHERE)", None))
        self.labelZoningName.setText(_translate("Dialog", "Nom court source de données  *", None))
        self.label_2.setText(_translate("Dialog", "Type de données source *", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

