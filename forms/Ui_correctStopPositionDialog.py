# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\GTFSAnalyst\forms\Ui_correctStopPositionDialog.ui'
#
# Created: Mon Feb 26 11:30:59 2018
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
        Dialog.resize(966, 349)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(830, 310, 121, 32))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.layoutWidget = QtGui.QWidget(Dialog)
        self.layoutWidget.setGeometry(QtCore.QRect(20, 10, 931, 291))
        self.layoutWidget.setObjectName(_fromUtf8("layoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.layoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.lineEditArret = QtGui.QLineEdit(self.layoutWidget)
        self.lineEditArret.setObjectName(_fromUtf8("lineEditArret"))
        self.gridLayout.addWidget(self.lineEditArret, 1, 1, 1, 2)
        self.tableViewPropositionsCommunes = QtGui.QTableView(self.layoutWidget)
        self.tableViewPropositionsCommunes.setAlternatingRowColors(True)
        self.tableViewPropositionsCommunes.setSelectionMode(QtGui.QAbstractItemView.SingleSelection)
        self.tableViewPropositionsCommunes.setSelectionBehavior(QtGui.QAbstractItemView.SelectRows)
        self.tableViewPropositionsCommunes.setSortingEnabled(True)
        self.tableViewPropositionsCommunes.setObjectName(_fromUtf8("tableViewPropositionsCommunes"))
        self.gridLayout.addWidget(self.tableViewPropositionsCommunes, 2, 1, 1, 4)
        self.label_3 = QtGui.QLabel(self.layoutWidget)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 3, 0, 1, 1)
        self.spinBoxNbPropositions = QtGui.QSpinBox(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.spinBoxNbPropositions.sizePolicy().hasHeightForWidth())
        self.spinBoxNbPropositions.setSizePolicy(sizePolicy)
        self.spinBoxNbPropositions.setProperty("value", 10)
        self.spinBoxNbPropositions.setObjectName(_fromUtf8("spinBoxNbPropositions"))
        self.gridLayout.addWidget(self.spinBoxNbPropositions, 3, 1, 1, 1)
        self.pushButtonActualiser = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonActualiser.setObjectName(_fromUtf8("pushButtonActualiser"))
        self.gridLayout.addWidget(self.pushButtonActualiser, 1, 3, 1, 2)
        self.label_2 = QtGui.QLabel(self.layoutWidget)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 2, 0, 1, 1)
        self.label = QtGui.QLabel(self.layoutWidget)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.comboBoxArrets = QtGui.QComboBox(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.comboBoxArrets.sizePolicy().hasHeightForWidth())
        self.comboBoxArrets.setSizePolicy(sizePolicy)
        self.comboBoxArrets.setObjectName(_fromUtf8("comboBoxArrets"))
        self.gridLayout.addWidget(self.comboBoxArrets, 0, 1, 1, 4)
        self.pushButtonPasser = QtGui.QPushButton(self.layoutWidget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Fixed, QtGui.QSizePolicy.Minimum)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButtonPasser.sizePolicy().hasHeightForWidth())
        self.pushButtonPasser.setSizePolicy(sizePolicy)
        self.pushButtonPasser.setObjectName(_fromUtf8("pushButtonPasser"))
        self.gridLayout.addWidget(self.pushButtonPasser, 3, 4, 1, 1)
        self.pushButtonLocaliserArret = QtGui.QPushButton(self.layoutWidget)
        self.pushButtonLocaliserArret.setObjectName(_fromUtf8("pushButtonLocaliserArret"))
        self.gridLayout.addWidget(self.pushButtonLocaliserArret, 3, 2, 1, 2)

        self.retranslateUi(Dialog)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Correction de la position des arrêts", None))
        self.label_3.setText(_translate("Dialog", "Nombre de propositions à afficher", None))
        self.pushButtonActualiser.setText(_translate("Dialog", "Actualiser la recherche", None))
        self.label_2.setText(_translate("Dialog", "Propositions de communes de rattachement", None))
        self.label.setText(_translate("Dialog", "Arrêt", None))
        self.pushButtonPasser.setText(_translate("Dialog", "Passer", None))
        self.pushButtonLocaliserArret.setText(_translate("Dialog", "Localiser au centroïde de la commune", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

