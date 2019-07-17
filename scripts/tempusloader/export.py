#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus data exporter

import provider

def export_road_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The road network name must be specified with --source-name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    subs["temp_schema"] = provider.config.TEMPSCHEMA
    roade = provider.ExportRoadTempus(path=args.path, dbstring=args.dbstring, sep=",", text_format = '.txt', encoding=args.encoding, copymode=args.copymode, logfile=args.logfile, subs=subs)
    return roade.run()


def export_pt_network(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The PT network name must be specified with --source_name !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    subs["temp_schema"] = provider.config.TEMPSCHEMA
    pte = provider.ExportPTGTFS(path=args.path, dbstring=args.dbstring, sep=",", text_format = '.txt', encoding=args.encoding, copymode=args.copymode, logfile=args.logfile, subs=subs)
    return pte.run()    

