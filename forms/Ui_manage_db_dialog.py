# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_manage_db_dialog.ui'
#
# Created: Tue Jul 16 14:35:08 2019
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
        Dialog.resize(458, 398)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(350, 360, 81, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.groupBox = QtGui.QGroupBox(Dialog)
        self.groupBox.setGeometry(QtCore.QRect(10, 10, 441, 201))
        self.groupBox.setObjectName(_fromUtf8("groupBox"))
        self.layoutWidget = QtGui.QWidget(self.groupBox)
        self.layoutWidget.setGeometry(QtCore.QRect(20, 30, 401, 121))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout_2 = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout_2.setMargin(0)
        self.gridLayout_2.setObjectName(_fromUtf8("gridLayout_2"))
        self.labelRouteDataSize = QtGui.QLabel(self.layoutWidget)
        self.labelRouteDataSize.setObjectName(_fromUtf8("labelRouteDataSize"))
        self.gridLayout_2.addWidget(self.labelRouteDataSize, 2, 2, 1, 1)
        self.labelPTDataSize = QtGui.QLabel(self.layoutWidget)
        self.labelPTDataSize.setObjectName(_fromUtf8("labelPTDataSize"))
        self.gridLayout_2.addWidget(self.labelPTDataSize, 1, 2, 1, 1)
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout_2.addWidget(self.label_3, 2, 1, 1, 1)
        self.label_197 = QtGui.QLabel(self.layoutWidget)
        self.label_197.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_197.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.label_197.setObjectName(_fromUtf8("label_197"))
        self.gridLayout_2.addWidget(self.label_197, 1, 1, 1, 1)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_2.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout_2.addWidget(self.label_2, 4, 1, 1, 1)
        self.label_196 = QtGui.QLabel(self.layoutWidget)
        self.label_196.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_196.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.label_196.setObjectName(_fromUtf8("label_196"))
        self.gridLayout_2.addWidget(self.label_196, 3, 1, 1, 1)
        self.labelIndicDataSize = QtGui.QLabel(self.layoutWidget)
        self.labelIndicDataSize.setObjectName(_fromUtf8("labelIndicDataSize"))
        self.gridLayout_2.addWidget(self.labelIndicDataSize, 3, 2, 1, 1)
        self.labelAuxDataSize = QtGui.QLabel(self.layoutWidget)
        self.labelAuxDataSize.setObjectName(_fromUtf8("labelAuxDataSize"))
        self.gridLayout_2.addWidget(self.labelAuxDataSize, 4, 2, 1, 1)
        self.label_4 = QtGui.QLabel(self.layoutWidget)
        self.label_4.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout_2.addWidget(self.label_4, 0, 0, 1, 1)
        self.comboBoxDB = QtGui.QComboBox(self.layoutWidget)
        self.comboBoxDB.setEditable(False)
        self.comboBoxDB.setObjectName(_fromUtf8("comboBoxDB"))
        self.gridLayout_2.addWidget(self.comboBoxDB, 0, 1, 1, 2)
        self.layoutWidget1 = QtGui.QWidget(self.groupBox)
        self.layoutWidget1.setGeometry(QtCore.QRect(20, 160, 401, 25))
        self.layoutWidget1.setObjectName(_fromUtf8("layoutWidget1"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.layoutWidget1)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.pushButtonLoad = QtGui.QPushButton(self.layoutWidget1)
        self.pushButtonLoad.setObjectName(_fromUtf8("pushButtonLoad"))
        self.horizontalLayout.addWidget(self.pushButtonLoad)
        self.pushButtonDelete = QtGui.QPushButton(self.layoutWidget1)
        self.pushButtonDelete.setObjectName(_fromUtf8("pushButtonDelete"))
        self.horizontalLayout.addWidget(self.pushButtonDelete)
        self.pushButtonExport = QtGui.QPushButton(self.layoutWidget1)
        self.pushButtonExport.setEnabled(True)
        self.pushButtonExport.setObjectName(_fromUtf8("pushButtonExport"))
        self.horizontalLayout.addWidget(self.pushButtonExport)
        self.groupBox_2 = QtGui.QGroupBox(Dialog)
        self.groupBox_2.setGeometry(QtCore.QRect(10, 220, 441, 101))
        self.groupBox_2.setObjectName(_fromUtf8("groupBox_2"))
        self.layoutWidget_2 = QtGui.QWidget(self.groupBox_2)
        self.layoutWidget_2.setGeometry(QtCore.QRect(20, 30, 401, 54))
        self.layoutWidget_2.setObjectName(_fromUtf8("layoutWidget_2"))
        self.gridLayout_3 = QtGui.QGridLayout(self.layoutWidget_2)
        self.gridLayout_3.setMargin(0)
        self.gridLayout_3.setObjectName(_fromUtf8("gridLayout_3"))
        self.lineEditNewDB = QtGui.QLineEdit(self.layoutWidget_2)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEditNewDB.sizePolicy().hasHeightForWidth())
        self.lineEditNewDB.setSizePolicy(sizePolicy)
        self.lineEditNewDB.setObjectName(_fromUtf8("lineEditNewDB"))
        self.gridLayout_3.addWidget(self.lineEditNewDB, 0, 1, 1, 1)
        self.label_6 = QtGui.QLabel(self.layoutWidget_2)
        self.label_6.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout_3.addWidget(self.label_6, 0, 0, 1, 1)
        self.pushButtonCreate = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonCreate.setObjectName(_fromUtf8("pushButtonCreate"))
        self.gridLayout_3.addWidget(self.pushButtonCreate, 1, 0, 1, 1)
        self.pushButtonImport = QtGui.QPushButton(self.layoutWidget_2)
        self.pushButtonImport.setEnabled(True)
        self.pushButtonImport.setObjectName(_fromUtf8("pushButtonImport"))
        self.gridLayout_3.addWidget(self.pushButtonImport, 1, 1, 1, 1)
        self.layoutWidget2 = QtGui.QWidget(Dialog)
        self.layoutWidget2.setGeometry(QtCore.QRect(30, 330, 401, 21))
        self.layoutWidget2.setObjectName(_fromUtf8("layoutWidget2"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget2)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label = QtGui.QLabel(self.layoutWidget2)
        self.label.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.labelLoadedDB = QtGui.QLabel(self.layoutWidget2)
        self.labelLoadedDB.setAlignment(QtCore.Qt.AlignCenter)
        self.labelLoadedDB.setObjectName(_fromUtf8("labelLoadedDB"))
        self.gridLayout.addWidget(self.labelLoadedDB, 0, 1, 1, 1)

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Gestion des bases de données", None))
        self.groupBox.setTitle(_translate("Dialog", "Gérer une base existante", None))
        self.labelRouteDataSize.setText(_translate("Dialog", "...", None))
        self.labelPTDataSize.setText(_translate("Dialog", "...", None))
        self.label_3.setText(_translate("Dialog", "Taille base de données d\'offre routière", None))
        self.label_197.setToolTip(_translate("Dialog", "<html><head/><body><p>Cette fenêtre permet de surveiller l\'espace disque utilisé par la base de données. Afin d\'éviter de saturer le disque dur de la machine, il est peut être nécessaire de faire du vide quand l\'espace occupé par la base est trop important (suppression d\'indicateurs calculés, de données auxiliaires, etc.). </p></body></html>", None))
        self.label_197.setText(_translate("Dialog", "Taille base de données d\'offre TC", None))
        self.label_2.setText(_translate("Dialog", "Taille base de données auxiliaires", None))
        self.label_196.setText(_translate("Dialog", "Taille base de données d\'indicateurs", None))
        self.labelIndicDataSize.setText(_translate("Dialog", "...", None))
        self.labelAuxDataSize.setText(_translate("Dialog", "...", None))
        self.label_4.setText(_translate("Dialog", "tempusaccess_", None))
        self.pushButtonLoad.setText(_translate("Dialog", "Charger dans QGIS", None))
        self.pushButtonDelete.setText(_translate("Dialog", "Supprimer", None))
        self.pushButtonExport.setToolTip(_translate("Dialog", "<html><head/><body><p>Sauvegarde la base dans un fichier externe pour pouvoir la recharger ultérieurement. </p></body></html>", None))
        self.pushButtonExport.setText(_translate("Dialog", "Sauvegarder...", None))
        self.groupBox_2.setTitle(_translate("Dialog", "Créer une nouvelle base", None))
        self.label_6.setText(_translate("Dialog", "tempusaccess_", None))
        self.pushButtonCreate.setToolTip(_translate("Dialog", "<html><head/><body><p>Saisir un nom de base pour activer la fonction. Si la base existe déjà, efface toutes les données présentes dans la base.</p></body></html>", None))
        self.pushButtonCreate.setText(_translate("Dialog", "Créer une base vierge", None))
        self.pushButtonImport.setToolTip(_translate("Dialog", "<html><head/><body><p>Ecrase toutes les données déjà présentes dans la base et les remplace par les données du fichier de sauvegarde choisi.  </p></body></html>", None))
        self.pushButtonImport.setText(_translate("Dialog", "Créer à partir d\'une sauvegarde...", None))
        self.label.setText(_translate("Dialog", "Base actuellement chargée", None))
        self.labelLoadedDB.setText(_translate("Dialog", "...", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

