# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_set_db_connection_dialog.ui'
#
# Created: Thu Nov 29 14:50:39 2018
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
        Dialog.resize(418, 199)
        self.layoutWidget_155 = QtGui.QWidget(Dialog)
        self.layoutWidget_155.setGeometry(QtCore.QRect(10, 10, 391, 141))
        self.layoutWidget_155.setObjectName(_fromUtf8("layoutWidget_155"))
        self.gridLayout_16 = QtGui.QGridLayout(self.layoutWidget_155)
        self.gridLayout_16.setMargin(0)
        self.gridLayout_16.setObjectName(_fromUtf8("gridLayout_16"))
        self.label_192 = QtGui.QLabel(self.layoutWidget_155)
        self.label_192.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_192.setObjectName(_fromUtf8("label_192"))
        self.gridLayout_16.addWidget(self.label_192, 0, 0, 1, 1)
        self.label_194 = QtGui.QLabel(self.layoutWidget_155)
        self.label_194.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_194.setObjectName(_fromUtf8("label_194"))
        self.gridLayout_16.addWidget(self.label_194, 3, 0, 1, 1)
        self.lineEdit_port = QtGui.QLineEdit(self.layoutWidget_155)
        self.lineEdit_port.setObjectName(_fromUtf8("lineEdit_port"))
        self.gridLayout_16.addWidget(self.lineEdit_port, 1, 1, 1, 2)
        self.lineEdit_login = QtGui.QLineEdit(self.layoutWidget_155)
        self.lineEdit_login.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.lineEdit_login.setText(_fromUtf8(""))
        self.lineEdit_login.setObjectName(_fromUtf8("lineEdit_login"))
        self.gridLayout_16.addWidget(self.lineEdit_login, 2, 1, 1, 2)
        self.lineEdit_pwd = QtGui.QLineEdit(self.layoutWidget_155)
        self.lineEdit_pwd.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.lineEdit_pwd.setText(_fromUtf8(""))
        self.lineEdit_pwd.setObjectName(_fromUtf8("lineEdit_pwd"))
        self.gridLayout_16.addWidget(self.lineEdit_pwd, 3, 1, 1, 2)
        self.label = QtGui.QLabel(self.layoutWidget_155)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout_16.addWidget(self.label, 1, 0, 1, 1)
        self.lineEdit_host = QtGui.QLineEdit(self.layoutWidget_155)
        self.lineEdit_host.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.lineEdit_host.setObjectName(_fromUtf8("lineEdit_host"))
        self.gridLayout_16.addWidget(self.lineEdit_host, 0, 1, 1, 2)
        self.label_193 = QtGui.QLabel(self.layoutWidget_155)
        self.label_193.setStyleSheet(_fromUtf8("color: rgb(0, 0, 0);"))
        self.label_193.setObjectName(_fromUtf8("label_193"))
        self.gridLayout_16.addWidget(self.label_193, 2, 0, 1, 1)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(220, 160, 181, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Apply|QtGui.QDialogButtonBox.Cancel)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))

        self.retranslateUi(Dialog)
        QtCore.QMetaObject.connectSlotsByName(Dialog)
        Dialog.setTabOrder(self.lineEdit_host, self.lineEdit_port)
        Dialog.setTabOrder(self.lineEdit_port, self.lineEdit_login)
        Dialog.setTabOrder(self.lineEdit_login, self.lineEdit_pwd)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Paramètres de connexion au serveur de bases de données", None))
        self.label_192.setText(_translate("Dialog", "Serveur", None))
        self.label_194.setText(_translate("Dialog", "Mot de passe", None))
        self.lineEdit_port.setText(_translate("Dialog", "55432", None))
        self.label.setText(_translate("Dialog", "Port", None))
        self.lineEdit_host.setToolTip(_translate("Dialog", "<html><head/><body><p>GTFSAnalyst utilise une base de données PostgreSQL-PostGIS pour le stockage des données et le calcul <br/>des indicateurs. Par défaut, elle est configurée pour être stockée localement sur la machine (installation PostgreSQL &quot;PGLite&quot;, base &quot;gtfsanalyst&quot; sur le port 55432 avec le nom d\'utilisateur de la session Windows et sans mot de passe).</p><p>Ce paramétrage peut être modifié ici, pour configurer le stockage de la base de données de l\'application<br/>sur un autre serveur ou dans une autre base.</p><p><br/></p></body></html>", None))
        self.lineEdit_host.setText(_translate("Dialog", "localhost", None))
        self.label_193.setText(_translate("Dialog", "Login", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

