#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus data exporter

import provider

def export_poi_source(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The POI source name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    dbparams = ast.literal_eval("{'"+args.dbstring.replace('=', "':'").replace(" ", "','")+"'}")
    if not 'host' in dbparams.keys():
        dbparams['host'] = 'localhost'
    if not 'user' in dbparams.keys():
        dbparams['user'] = os.getenv("USERNAME")
    if not 'dbname' in dbparams.keys():
        dbparams['dbname'] = 'tempus_access_test'
    if not 'port' in dbparams.keys():
        dbparams['port'] = '55432'
    poie = provider.ExportPOITempus(args.dbstring, dbparams, args.path, args.logfile, subs)
    return poie.run()


def export_road_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The road network name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    roade = provider.ExportRoadTempus(args.dbstring, args.path, args.logfile, subs)
    return roade.run()


def export_pt_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The PT network name must be specified with --source_name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    pte = provider.ExportPTGTFS(args.dbstring, args.path, args.logfile, subs)
    return pte.run()    
