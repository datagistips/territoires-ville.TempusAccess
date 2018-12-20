#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus data deleter

import provider

def delete_poi_source(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The service name of the POI must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    poid = provider.DeletePOI(args.dbstring, args.logfile, subs)
    return poid.run()
    
    
def delete_road_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The road network name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    roadd = provider.DeleteRoad(args.dbstring, args.logfile, subs)
    return roadd.run()
    
    
def delete_pt_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The PT network name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    ptd = provider.DeletePT(args.dbstring, args.logfile, subs)
    return ptd.run()


def delete_zoning(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The zoning name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    zd = provider.DeleteZoning(args.dbstring, args.logfile, subs)
    return zd.run()
    
    
    