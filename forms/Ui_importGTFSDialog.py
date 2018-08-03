# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_importGTFSDialog.ui'
#
# Created: Thu May 17 22:17:18 2018
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
        Dialog.resize(589, 164)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(450, 110, 121, 51))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget_2 = QtGui.QWidget(Dialog)
        self.layoutWidget_2.setGeometry(QtCore.QRect(20, 31, 553, 51))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget_2)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.pushButtonImportGTFSFeed = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonImportGTFSFeed.setEnabled(False)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonImportGTFSFeed.sizePolicy().hasHeightForWidth())
        self.pushButtonImportGTFSFeed.setSizePolicy(sizePolicy)
        self.pushButtonImportGTFSFeed.setObjectName(_fromUtf8("pushButtonImportGTFSFeed"))
        self.gridLayout.addWidget(self.pushButtonImportGTFSFeed, 1, 1, 1, 1)
        self.lineEditPrefixeGTFS = QtGui.QLineEdit(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEditPrefixeGTFS.sizePolicy().hasHeightForWidth())
        self.lineEditPrefixeGTFS.setSizePolicy(sizePolicy)
        self.lineEditPrefixeGTFS.setWhatsThis(_fromUtf8(""))
        self.lineEditPrefixeGTFS.setText(_fromUtf8(""))
        self.lineEditPrefixeGTFS.setObjectName(_fromUtf8("lineEditPrefixeGTFS"))
        self.gridLayout.addWidget(self.lineEditPrefixeGTFS, 0, 1, 1, 1)
        self.labelSchemaStockage = QtGui.QLabel(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelSchemaStockage.sizePolicy().hasHeightForWidth())
        self.labelSchemaStockage.setSizePolicy(sizePolicy)
        self.labelSchemaStockage.setWhatsThis(_fromUtf8(""))
        self.labelSchemaStockage.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.labelSchemaStockage.setObjectName(_fromUtf8("labelSchemaStockage"))
        self.gridLayout.addWidget(self.labelSchemaStockage, 0, 0, 1, 1)
        self.labelSchemaStockage_2 = QtGui.QLabel(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.labelSchemaStockage_2.sizePolicy().hasHeightForWidth())
        self.labelSchemaStockage_2.setSizePolicy(sizePolicy)
        self.labelSchemaStockage_2.setWhatsThis(_fromUtf8(""))
        self.labelSchemaStockage_2.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.labelSchemaStockage_2.setObjectName(_fromUtf8("labelSchemaStockage_2"))
        self.gridLayout.addWidget(self.labelSchemaStockage_2, 1, 0, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Importer une nouvelle source de données GTFS", None))
        self.pushButtonImportGTFSFeed.setToolTip(_translate("Dialog", "<html><head/><body><p>Le bouton n\'est accessible qu\'après avoir renseigné un préfixe pour la source. Le préfixe doit être différent de ceux des sources déjà importées (voir liste ci-dessous). </p><p>Attention : la source doit être un fichier .zip contenant directement les fichiers .txt, aucun dossier ne doit être inclus dans le fichier .zip. </p></body></html>", None))
        self.pushButtonImportGTFSFeed.setText(_translate("Dialog", "Parcourir...", None))
        self.lineEditPrefixeGTFS.setToolTip(_translate("Dialog", "<html><head/><body><p>Le préfixe sera accolé aux identifiants des objets de la source (arrêts, services, lignes, etc.).</p><p>Il est obligatoire pour pouvoir charger une source et doit être différents des préfixes des sources déjà chargées dans la base (voir ci-dessous). </p></body></html>", None))
        self.labelSchemaStockage.setText(_translate("Dialog", "1. Définir le préfixe pour la source (obligatoire)", None))
        self.labelSchemaStockage_2.setText(_translate("Dialog", "2. Choisir la source (fichier .zip)", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

