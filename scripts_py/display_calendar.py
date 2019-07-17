from display_calendar_proc import display_calendar_for_gtfs

# CAPA
plot_capa = display_calendar_for_gtfs("C:/Users/mathieu.rajerison/Desktop/TAFF_MAISON/A_WKSP/190410_TEMPUS/data_corse/3_aurelie/capa_GTFS_022019/")

# save as png and show
plot_capa.savefig("capa.png")
plot_capa.show()


# CFC
plot_cfc = display_calendar_for_gtfs("C:/Users/mathieu.rajerison/Desktop/TAFF_MAISON/A_WKSP/190410_TEMPUS/data_corse/3_aurelie/chemin-de-fer-corse_ligne-ferroviaire-corse-v3_gtfs_2019-03-27_14-05-43/")

# save as png and show
plot_cfc.savefig("cfc.png")
plot_cfc.show()

# TREG2A
plot_treg = display_calendar_for_gtfs("C:/Users/mathieu.rajerison/Desktop/TAFF_MAISON/A_WKSP/190410_TEMPUS/data_corse/3_aurelie/Transport-Regulier-Corse-du-Sud_Transport-regulier-Corse-du-Sud-v2_gtfs_2019-03-11_17-38-27/")

# save as png and show
plot_treg.savefig("treg2a.png")
plot_treg.show()
