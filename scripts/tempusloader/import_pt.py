#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus public transport data importer

import provider

def import_pt_gtfs(args):
    """Load Public Transport from GTFS data into a Tempus database."""    
    subs={}
    if args.source_name is None:
        sys.stderr.write("A PT network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    subs['max_dist'] = str(args.max_dist)
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    gtfsi = provider.ImportPTGTFS(path=args.path, prefix="", dbstring=args.dbstring, logfile=args.logfile, options={'g':'geom', 'D':True, 'I':True, 'S':True}, sep=",", encoding=args.encoding, copymode=args.copymode, doclean=not args.noclean, subs=subs)
    r = gtfsi.run()
    return r
    
def import_pt_sncf(args, shape_options):
    """Load Public Transport from SNCF and IGN open-data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A PT network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs["source_name"] = "ter"
    subs['max_dist'] = str(args.max_dist)
    teri = provider.ImportPTGTFSTemp(path=args.path[0], dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding='UTF8', copymode=args.copymode, doclean=not args.noclean, subs=subs)
    teri.run()
    subs["source_name"] = "ic"
    subs['max_dist'] = str(args.max_dist)
    ici = provider.ImportPTGTFSTemp(path=args.path[1], dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding='UTF8', copymode=args.copymode, doclean=not args.noclean, subs=subs)
    ici.run()
    subs["source_name"] = args.source_name
    subs['max_dist'] = str(args.max_dist)
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    sncfi = provider.ImportPTSNCF(args.path[2], args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs=subs) 
    return sncfi.run()
    
def import_pt_tempus(args):
    subs={}
    print args.path
    if args.source_name is None:
        sys.stderr.write("A PT network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    subs['max_dist'] = str(args.max_dist)
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    tempusi = provider.ImportPTTempus(path=args.path, dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding=args.encoding, copymode=args.copymode, doclean=not args.noclean, subs=subs)
    return tempusi.run()
    
def import_pt_ntfs(args):    
    subs={}
    if args.source_name is None:
        sys.stderr.write("A PT network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs['source_name'] = args.source_name
    subs['max_dist'] = str(args.max_dist)
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    ntfsi = provider.ImportPTNTFS(path=args.path, dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding=args.encoding, copymode=args.copymode, doclean=not args.noclean, subs=subs)
    return ntfsi.run()


    