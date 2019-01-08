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
    gtfsi = provider.ImportPTGTFS(path=args.path, dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding=args.encoding, copymode=args.copymode, doclean=not args.noclean, subs=subs)
    return gtfsi.load()

def import_pt_sncf(args, shape_options):
    """Load Public Transport from SNCF and IGN open-data into a Tempus database."""
    subs={}
    if args.source_name is None:
        sys.stderr.write("A PT network name must be supplied. Use --source-name\n")
        sys.exit(1)
    subs["source_name"] = "ter"
    teri = provider.ImportPTGTFSTemp(path=args.path[0], dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding='UTF8', copymode=args.copymode, doclean=not args.noclean, subs=subs)
    teri.load()
    subs["source_name"] = "ic"
    ici = provider.ImportPTGTFSTemp(path=args.path[1], dbstring=args.dbstring, logfile=args.logfile, sep=",", encoding='UTF8', copymode=args.copymode, doclean=not args.noclean, subs=subs)
    ici.load()
    subs["source_name"] = args.source_name
    sncfi = provider.ImportPTSNCF(args.path[2], args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs=subs) 
    return sncfi.load()
    
    
    