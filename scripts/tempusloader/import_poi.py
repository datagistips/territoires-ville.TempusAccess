#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus points of interest data importer

import provider

def import_poi_tempus(args, shape_options):
    """Load a point shapefile into a Tempus database."""
    if args.source_name is None:
        sys.stderr.write("The service name of the POI must be specified with --source-name !\n")
        sys.exit(1)
    if args.prefix is None:
        args.prefix = ''
    
    subs = {}
    try:
        poi_type = int(args.poi_type)
        if poi_type not in range(1, 6):
            raise ValueError
    except ValueError:
        print "Wrong poi type. Assuming User type (5). Correct values are in range 1-5."
        poi_type = 5
    
    subs["poi_type"] = str(poi_type)
    subs["source_name"] = args.source_name
    subs["name_field"] = args.name_field
    subs["id_field"] = args.id_field
    subs["filter"] = args.filter
    if not 'name_field' in subs.keys():
        subs['name_field'] = 'name'
    if not 'id_field' in subs.keys():
        subs['id_field'] = 'id'
    if not 'filter' in subs.keys():
        subs['filter'] = 'true'
    poii = provider.ImportPOITempus(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return poii.load()
    
    
def import_poi_insee_bpe(args, shape_options):
    """Load INSEE BPE POI data into a Tempus database."""
    if args.source_name is None:
        sys.stderr.write("The service name of the POI must be specified with --source-name !\n")
        sys.exit(1)
    if args.prefix is None:
        args.prefix = ''
    
    subs = {}
    try:
        poi_type = int(args.poi_type)
        if poi_type not in range(1, 6):
            raise ValueError
    except ValueError:
        print "Wrong poi type. Assuming User type (5). Correct values are in range 1-5."
        poi_type = 5     
    subs["poi_type"] = str(poi_type)
       
    subs["poi_type"] = str(poi_type)
    subs["source_name"] = args.source_name
    subs["filter"] = args.filter
    if not 'filter' in subs.keys():
        subs['filter'] = 'true' 
    bpei = provider.ImportPOIINSEEBPE(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return bpei.load()