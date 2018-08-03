# -*- coding: utf-8 -*-
"""
/***************************************************************************
 TempusAccess
                                 A QGIS plugin
 Analyse de l'offre de transport en commun au format GTFS
                             -------------------
        begin                : 2017-01-26
        copyright            : (C) 2017 by Cerema
        email                : aurelie.bousquet@cerema.fr, patrick.palmier@cerema.fr, helene.ly@cerema.fr
        git sha              : $Format:%H$
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """Load TempusAccess class from file TempusAccess.

    :param iface: A QGIS interface instance.
    :type iface: QgsInterface
    """
    #
    from .TempusAccess import TempusAccess
    return TempusAccess(iface)
