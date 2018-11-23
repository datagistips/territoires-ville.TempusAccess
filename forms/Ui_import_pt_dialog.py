# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_import_pt_dialog.ui'
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
        Dialog.resize(534, 230)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(440, 190, 81, 41))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget_2 = QtGui.QWidget(Dialog)
        self.layoutWidget_2.setGeometry(QtCore.QRect(10, 10, 511, 171))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget_2)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.comboBoxFormat = QtGui.QComboBox(self.layoutWidget_2)
        self.comboBoxFormat.setObjectName(_fromUtf8("comboBoxFormat"))
        self.gridLayout.addWidget(self.comboBoxFormat, 1, 1, 1, 1)
        self.pushButtonChoose2 = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonChoose2.setEnabled(False)
        self.pushButtonChoose2.setObjectName(_fromUtf8("pushButtonChoose2"))
        self.gridLayout.addWidget(self.pushButtonChoose2, 3, 1, 1, 1)
        self.labelChoose1 = QtGui.QLabel(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelChoose1.sizePolicy().hasHeightForWidth())
        self.labelChoose1.setSizePolicy(sizePolicy)
        self.labelChoose1.setWhatsThis(_fromUtf8(""))
        self.labelChoose1.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelChoose1.setObjectName(_fromUtf8("labelChoose1"))
        self.gridLayout.addWidget(self.labelChoose1, 2, 0, 1, 1)
        self.labelFile1 = QtGui.QLabel(self.layoutWidget_2)
        self.labelFile1.setEnabled(False)
        self.labelFile1.setObjectName(_fromUtf8("labelFile1"))
        self.gridLayout.addWidget(self.labelFile1, 2, 2, 1, 1)
        self.pushButtonImport = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonImport.setEnabled(False)
        self.pushButtonImport.setObjectName(_fromUtf8("pushButtonImport"))
        self.gridLayout.addWidget(self.pushButtonImport, 5, 1, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget_2)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 1, 0, 1, 1)
        self.labelFile2 = QtGui.QLabel(self.layoutWidget_2)
        self.labelFile2.setEnabled(False)
        self.labelFile2.setObjectName(_fromUtf8("labelFile2"))
        self.gridLayout.addWidget(self.labelFile2, 3, 2, 1, 1)
        self.labelSchemaStockage = QtGui.QLabel(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelSchemaStockage.sizePolicy().hasHeightForWidth())
        self.labelSchemaStockage.setSizePolicy(sizePolicy)
        self.labelSchemaStockage.setWhatsThis(_fromUtf8(""))
        self.labelSchemaStockage.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelSchemaStockage.setObjectName(_fromUtf8("labelSchemaStockage"))
        self.gridLayout.addWidget(self.labelSchemaStockage, 0, 0, 1, 1)
        self.pushButtonChoose1 = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonChoose1.setEnabled(True)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonChoose1.sizePolicy().hasHeightForWidth())
        self.pushButtonChoose1.setSizePolicy(sizePolicy)
        self.pushButtonChoose1.setObjectName(_fromUtf8("pushButtonChoose1"))
        self.gridLayout.addWidget(self.pushButtonChoose1, 2, 1, 1, 1)
        self.lineEditSourceName = QtGui.QLineEdit(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEditSourceName.sizePolicy().hasHeightForWidth())
        self.lineEditSourceName.setSizePolicy(sizePolicy)
        self.lineEditSourceName.setWhatsThis(_fromUtf8(""))
        self.lineEditSourceName.setText(_fromUtf8(""))
        self.lineEditSourceName.setObjectName(_fromUtf8("lineEditSourceName"))
        self.gridLayout.addWidget(self.lineEditSourceName, 0, 1, 1, 1)
        self.labelChoose2 = QtGui.QLabel(self.layoutWidget_2)
        self.labelChoose2.setEnabled(False)
        self.labelChoose2.setText(_fromUtf8(""))
        self.labelChoose2.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelChoose2.setObjectName(_fromUtf8("labelChoose2"))
        self.gridLayout.addWidget(self.labelChoose2, 3, 0, 1, 1)
        self.labelChoose3 = QtGui.QLabel(self.layoutWidget_2)
        self.labelChoose3.setEnabled(False)
        self.labelChoose3.setText(_fromUtf8(""))
        self.labelChoose3.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.labelChoose3.setObjectName(_fromUtf8("labelChoose3"))
        self.gridLayout.addWidget(self.labelChoose3, 4, 0, 1, 1)
        self.pushButtonChoose3 = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonChoose3.setEnabled(False)
        self.pushButtonChoose3.setObjectName(_fromUtf8("pushButtonChoose3"))
        self.gridLayout.addWidget(self.pushButtonChoose3, 4, 1, 1, 1)
        self.labelFile3 = QtGui.QLabel(self.layoutWidget_2)
        self.labelFile3.setEnabled(False)
        self.labelFile3.setObjectName(_fromUtf8("labelFile3"))
        self.gridLayout.addWidget(self.labelFile3, 4, 2, 1, 1)
        self.widget = QtGui.QWidget(Dialog)
        self.widget.setGeometry(QtCore.QRect(10, 200, 421, 22))
        self.widget.setObjectName(_fromUtf8("widget"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.widget)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_5 = QtGui.QLabel(self.widget)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.horizontalLayout.addWidget(self.label_5)
        self.lineEditCommand = QtGui.QLineEdit(self.widget)
        self.lineEditCommand.setEnabled(False)
        self.lineEditCommand.setObjectName(_fromUtf8("lineEditCommand"))
        self.horizontalLayout.addWidget(self.lineEditCommand)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer une nouvelle offre de transport en commun", None))
        self.pushButtonChoose2.setText(_translate("Dialog", "Parcourir...", None))
        self.labelChoose1.setText(_translate("Dialog", "Choisir le fichier .zip", None))
        self.labelFile1.setText(_translate("Dialog", "...", None))
        self.pushButtonImport.setText(_translate("Dialog", "Importer", None))
        self.label.setText(_translate("Dialog", "Type données source *", None))
        self.labelFile2.setText(_translate("Dialog", "...", None))
        self.labelSchemaStockage.setText(_translate("Dialog", "Nom de la source *", None))
        self.pushButtonChoose1.setToolTip(_translate("Dialog", "<html><head/><body><p>Le bouton n\'est accessible qu\'après avoir renseigné un préfixe pour la source. Le préfixe doit être différent de ceux des sources déjà importées (voir liste ci-dessous). </p><p>Attention : la source doit être un fichier .zip contenant directement les fichiers .txt, aucun dossier ne doit être inclus dans le fichier .zip. </p></body></html>", None))
        self.pushButtonChoose1.setText(_translate("Dialog", "Parcourir...", None))
        self.lineEditSourceName.setToolTip(_translate("Dialog", "<html><head/><body><p>Le préfixe sera accolé aux identifiants des objets de la source (arrêts, services, lignes, etc.).</p><p>Il est obligatoire pour pouvoir charger une source et doit être différents des préfixes des sources déjà chargées dans la base (voir ci-dessous). </p></body></html>", None))
        self.pushButtonChoose3.setText(_translate("Dialog", "Parcourir...", None))
        self.labelFile3.setText(_translate("Dialog", "...", None))
        self.label_5.setText(_translate("Dialog", "Dernière commande exécutée", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

