#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus zoning data importer

import provider

def import_zoning_tempus(args, shape_options):
    """ Load areas data into a TempusAccess database with a generic method."""
    subs = {}
    subs["source_name"] = args.source_name
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    if args.id_field is None:
        sys.stderr.write("An ID field name must be supplied. Use --id-field\n")
        sys.exit(1)
    subs["id_field"]=args.id_field
    if args.name_field is None:
        sys.stderr.write("A name field name must be supplied. Use --name-field\n")
        sys.exit(1)
    subs["name_field"] = args.name_field
    if args.source_comment is None:
        subs["source_comment"] = ''
    else:
        subs["source_comment"] = args.source_comment
    shape_options['S'] = False # There are multipolygons with two parts, so, the -S option (which converts multi geometries to simple ones) cannot be used
    tempusi = provider.ImportZoningTempus(args.path, args.prefix, args.dbstring, args.logfile, shape_options, not args.noclean, subs)
    return tempusi.run()

def import_zoning_ign_adminexpress(args, shape_options):
    """ Load IGN AdminExpress areas data into a TempusAccess database."""
    subs = {}
    subs["source_name"] = args.source_name
    subs["temp_schema"]=provider.config.TEMPSCHEMA
    shape_options['S'] = False # There are multipolygons with two parts, so, the -S option (which converts multi geometries to simple ones) cannot be used
    adminexpi = provider.ImportZoningIGNAdminExpress(path=args.path, prefix=args.prefix, dbstring=args.dbstring, \
    logfile=args.logfile, options=shape_options, doclean=not args.noclean, subs=subs)
    return adminexpi.run() 


