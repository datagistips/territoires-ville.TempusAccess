#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus road data importer

import provider

def import_road_ign_route120(args, shape_options):
    """Load IGN (Route120) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    Importer = {
        '1.1': provider.ImportRoadIGNRoute120_1_1,
        None: provider.ImportRoadIGNRoute120_1_1
    }[args.model_version]
    rte120i = Importer(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return rte120i.load()


def import_road_ign_route500(args, shape_options):
    """Load IGN (Route500) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name    
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    Importer = {
        '2.1': provider.ImportRoadIGNRoute500_2_1,
        None: provider.ImportRoadIGNRoute500_2_1
    }[args.model_version]
    rte500i = Importer(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return rte500i.load()


def import_road_ign_bdtopo(args, shape_options):
    """Load IGN (BDTopo) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    Importer = {
        '2.2': provider.ImportRoadIGNBDTopo_2_2,
        None: provider.ImportRoadIGNBDTopo_2_2
    }[args.model_version]
    bdtopoi = Importer(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return bdtopoi.load()

    
def import_road_ign_bdcarto(args, shape_options):
    """Load IGN (BDCarto) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    Importer = {
        '3.2': provider.ImportRoadIGNBDCarto_3_2,
        None: provider.ImportRoadIGNBDCarto_3_2
    }[args.model_version]
    bdcartoi = Importer(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return bdcartoi.load()
    
    
def import_road_visum(args, shape_options):
    """Load a Visum-extracted Shapefile into a Tempus database; wait for 4
    distinct transportation modes (pedestrian, bike, private car, taxi)

    Parameters
    ----------
    args: list
        list of arguments passed to loader
    shape_options: dict
        geometry options passed to the ShapeLoader
    
    """
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    splitted_modes = args.visum_modes.split(',')
    if len(splitted_modes) != 4:
        sys.stderr.write(("Need 4 comma-separated strings "
                          "(command --visum-modes) for representing "
                          "pedestrians, bikes, private vehicles and taxis!\n"))
        sys.exit(1)
    visumi = provider.ImportRoadVisum(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs, splitted_modes)
    return visumi.load()

    
def import_road_osm(args, shape_options):
    """Load OpenStreetMap (as shapefile) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    osmi = provider.ImportRoadOSM(args.path, args.dbstring, args.logfile, subs)
    return osmi.load()


def import_road_tomtom(args, shape_options):
    """Load Tomtom (Multinet) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    Importer = {
        '1409': provider.ImportRoadMultinet_1409,
        None: provider.ImportRoadMultinet
    }[args.model_version]
    shape_options['I'] = False
    mni = Importer(args.path, args.speed_profile, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean)
    return mni.load()
    

def import_road_navteq(args, shape_options):
    """Load Navteq (Navstreets) road data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    ntqi = provider.ImportRoadNavstreets(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean)
    return ntqi.load()


def import_road_tempus(args, shape_options):
    """Load a Tempus format road file (as shapefile) into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A road network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_commentroadtempusi = provider.ImportRoadTempus(args.path, args.dbstring, args.logfile)
    return roadtempusi.load()

