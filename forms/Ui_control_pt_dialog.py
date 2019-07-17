# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\aurelie-p.bousquet\.qgis2\python\plugins\TempusAccess\forms\Ui_control_pt_dialog.ui'
#
# Created: Tue Jul 16 14:35:10 2019
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
        Dialog.resize(620, 458)
        self.buttonBox = QtGui.QDialogButtonBox(Dialog)
        self.buttonBox.setGeometry(QtCore.QRect(430, 430, 171, 21))
        self.buttonBox.setOrientation(QtCore.Qt.Horizontal)
        self.buttonBox.setStandardButtons(QtGui.QDialogButtonBox.Close)
        self.buttonBox.setObjectName(_fromUtf8("buttonBox"))
        self.tabWidget = QtGui.QTabWidget(Dialog)
        self.tabWidget.setGeometry(QtCore.QRect(10, 130, 601, 291))
        self.tabWidget.setObjectName(_fromUtf8("tabWidget"))
        self.tab = QtGui.QWidget()
        self.tab.setObjectName(_fromUtf8("tab"))
        self.label_14 = QtGui.QLabel(self.tab)
        self.label_14.setGeometry(QtCore.QRect(20, 140, 581, 16))
        self.label_14.setObjectName(_fromUtf8("label_14"))
        self.label_15 = QtGui.QLabel(self.tab)
        self.label_15.setGeometry(QtCore.QRect(20, 180, 461, 16))
        self.label_15.setObjectName(_fromUtf8("label_15"))
        self.label_16 = QtGui.QLabel(self.tab)
        self.label_16.setGeometry(QtCore.QRect(240, 200, 231, 16))
        self.label_16.setObjectName(_fromUtf8("label_16"))
        self.label_17 = QtGui.QLabel(self.tab)
        self.label_17.setGeometry(QtCore.QRect(240, 220, 221, 16))
        self.label_17.setObjectName(_fromUtf8("label_17"))
        self.label_18 = QtGui.QLabel(self.tab)
        self.label_18.setGeometry(QtCore.QRect(240, 240, 231, 20))
        self.label_18.setObjectName(_fromUtf8("label_18"))
        self.label_19 = QtGui.QLabel(self.tab)
        self.label_19.setGeometry(QtCore.QRect(20, 160, 471, 16))
        self.label_19.setObjectName(_fromUtf8("label_19"))
        self.tabWidget.addTab(self.tab, _fromUtf8(""))
        self.tab_2 = QtGui.QWidget()
        self.tab_2.setObjectName(_fromUtf8("tab_2"))
        self.gridLayoutWidget = QtGui.QWidget(self.tab_2)
        self.gridLayoutWidget.setGeometry(QtCore.QRect(10, 10, 231, 161))
        self.gridLayoutWidget.setObjectName(_fromUtf8("gridLayoutWidget"))
        self.gridLayout = QtGui.QGridLayout(self.gridLayoutWidget)
        self.gridLayout.setMargin(0)
        self.gridLayout.setObjectName(_fromUtf8("gridLayout"))
        self.label_6 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_6.setObjectName(_fromUtf8("label_6"))
        self.gridLayout.addWidget(self.label_6, 3, 0, 1, 1)
        self.label_7 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_7.setObjectName(_fromUtf8("label_7"))
        self.gridLayout.addWidget(self.label_7, 4, 0, 1, 1)
        self.label_4 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_4.setObjectName(_fromUtf8("label_4"))
        self.gridLayout.addWidget(self.label_4, 5, 0, 1, 1)
        self.label = QtGui.QLabel(self.gridLayoutWidget)
        self.label.setObjectName(_fromUtf8("label"))
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.label_2 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_2.setObjectName(_fromUtf8("label_2"))
        self.gridLayout.addWidget(self.label_2, 1, 0, 1, 1)
        self.label_3 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_3.setObjectName(_fromUtf8("label_3"))
        self.gridLayout.addWidget(self.label_3, 2, 0, 1, 1)
        self.label_8 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_8.setObjectName(_fromUtf8("label_8"))
        self.gridLayout.addWidget(self.label_8, 5, 1, 1, 1)
        self.label_9 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_9.setObjectName(_fromUtf8("label_9"))
        self.gridLayout.addWidget(self.label_9, 4, 1, 1, 1)
        self.label_10 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_10.setObjectName(_fromUtf8("label_10"))
        self.gridLayout.addWidget(self.label_10, 3, 1, 1, 1)
        self.label_11 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_11.setObjectName(_fromUtf8("label_11"))
        self.gridLayout.addWidget(self.label_11, 2, 1, 1, 1)
        self.label_12 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_12.setObjectName(_fromUtf8("label_12"))
        self.gridLayout.addWidget(self.label_12, 1, 1, 1, 1)
        self.label_13 = QtGui.QLabel(self.gridLayoutWidget)
        self.label_13.setObjectName(_fromUtf8("label_13"))
        self.gridLayout.addWidget(self.label_13, 0, 1, 1, 1)
        self.tabWidget.addTab(self.tab_2, _fromUtf8(""))
        self.widget = QtGui.QWidget(Dialog)
        self.widget.setGeometry(QtCore.QRect(10, 10, 601, 101))
        self.widget.setObjectName(_fromUtf8("widget"))
        self.horizontalLayout = QtGui.QHBoxLayout(self.widget)
        self.horizontalLayout.setMargin(0)
        self.horizontalLayout.setObjectName(_fromUtf8("horizontalLayout"))
        self.label_5 = QtGui.QLabel(self.widget)
        self.label_5.setAlignment(QtCore.Qt.AlignRight|QtCore.Qt.AlignTrailing|QtCore.Qt.AlignVCenter)
        self.label_5.setObjectName(_fromUtf8("label_5"))
        self.horizontalLayout.addWidget(self.label_5)
        self.listViewPTNetworks = QtGui.QListView(self.widget)
        sizePolicy = QtGui.QSizePolicy(QtGui.QSizePolicy.Preferred, QtGui.QSizePolicy.Expanding)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.listViewPTNetworks.sizePolicy().hasHeightForWidth())
        self.listViewPTNetworks.setSizePolicy(sizePolicy)
        self.listViewPTNetworks.setEditTriggers(QtGui.QAbstractItemView.NoEditTriggers)
        self.listViewPTNetworks.setAlternatingRowColors(True)
        self.listViewPTNetworks.setSelectionMode(QtGui.QAbstractItemView.MultiSelection)
        self.listViewPTNetworks.setSelectionBehavior(QtGui.QAbstractItemView.SelectRows)
        self.listViewPTNetworks.setObjectName(_fromUtf8("listViewPTNetworks"))
        self.horizontalLayout.addWidget(self.listViewPTNetworks)

        self.retranslateUi(Dialog)
        self.tabWidget.setCurrentIndex(0)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("accepted()")), Dialog.accept)
        QtCore.QObject.connect(self.buttonBox, QtCore.SIGNAL(_fromUtf8("rejected()")), Dialog.reject)
        QtCore.QMetaObject.connectSlotsByName(Dialog)

    def retranslateUi(self, Dialog):
        Dialog.setWindowTitle(_translate("Dialog", "Contrôle de la qualité des offres de transport collectif", None))
        self.label_14.setText(_translate("Dialog", "Le nombre dans la case correspond au nombre d\'offres présentes chaque jour.", None))
        self.label_15.setText(_translate("Dialog", "L\'entourage des cases donne le type de jour : - en gris les week-ends et les jours fériés ;", None))
        self.label_16.setText(_translate("Dialog", "- en rouge les vacances scolaires de la zone A ;", None))
        self.label_17.setText(_translate("Dialog", "- en bleu les vacances scolaires de la zone B ;", None))
        self.label_18.setText(_translate("Dialog", "- en vert les vacances scolaires de la zone C.", None))
        self.label_19.setText(_translate("Dialog", "La couleur de la case est d\'autant plus foncée que le nombre de services du jour est important. ", None))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab), _translate("Dialog", "Calendrier des dessertes", None))
        self.label_6.setText(_translate("Dialog", "Itinéraires de lignes", None))
        self.label_7.setText(_translate("Dialog", "Services", None))
        self.label_4.setText(_translate("Dialog", "Transporteurs", None))
        self.label.setText(_translate("Dialog", "Points d\'arrêt", None))
        self.label_2.setText(_translate("Dialog", "Zones d\'arrêt", None))
        self.label_3.setText(_translate("Dialog", "Lignes", None))
        self.label_8.setText(_translate("Dialog", "...", None))
        self.label_9.setText(_translate("Dialog", "...", None))
        self.label_10.setText(_translate("Dialog", "...", None))
        self.label_11.setText(_translate("Dialog", "...", None))
        self.label_12.setText(_translate("Dialog", "...", None))
        self.label_13.setText(_translate("Dialog", "...", None))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.tab_2), _translate("Dialog", "Nombre d\'objets", None))
        self.label_5.setText(_translate("Dialog", "Choisir une ou plusieurs offres", None))


if __name__ == "__main__":
    import sys
    app = QtGui.QApplication(sys.argv)
    Dialog = QtGui.QDialog()
    ui = Ui_Dialog()
    ui.setupUi(Dialog)
    Dialog.show()
    sys.exit(app.exec_())

