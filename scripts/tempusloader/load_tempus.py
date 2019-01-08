#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus data loader

import argparse
import sys

from import_road import *
from import_pt import *
from import_poi import *
from import_zoning import *
from export import *
from delete import *
from reset import *

def main():
    shape_options = {}
    parser = argparse.ArgumentParser(description='Tempus data loader')
    parser.add_argument('-a', '--action', required=True, help="The action to make (import, export, delete or reset)", default='import')
    parser.add_argument('-p', '--path', required=False, nargs='+', help='The source directory/file to import data from or to export data to')
    parser.add_argument('-t', '--data-type', required=False, help='The data type to import / export / delete (road, pt, poi or zoning)', dest='data_type')
    parser.add_argument('-f', '--data-format', required=False, help="The data format (for road data: ign_bdcarto, ign_bdtopo, ign_route120, ign_route500, navteq, osm, tomtom, visum, tempus, "
                        " for PT data: gtfs, gtfs2, sncf, for POI data: tempus, insee_bpe, for zoning data: tempus, ign_adminexpress)")
    parser.add_argument('-m', '--model-version', required=False, default=None, dest='model_version', help='The data model version')
    parser.add_argument('-d', '--dbstring', required=False, help='The PostgreSQL database connection string')
    parser.add_argument('--pglite', required=False, help='Use the internal cluster (PGLite) with the specified database name')
    parser.add_argument('--prefix', required=False, help='Prefix for file names', default="")
    parser.add_argument('-l', '--logfile', required=False, help='Log file for loading and SQL output')
    parser.add_argument('-s', '--source-name', required=False, help="Short name (used as an ID) of the source to import/delete", dest='source_name')
    parser.add_argument('--source-comment', required=False, help="Long name or comment about the source to import", dest='source_comment')
    parser.add_argument('-S', '--srid', required=False, help="Set the SRID for geometries. Default to 4326 (lat/lon)")
    parser.add_argument('-W', '--encoding', required=False, help="Specify the character encoding of the file(s)")
    parser.add_argument('--sep', required=False, default=",", help="Specify the column separator for text files")
    parser.add_argument('--filter', required=False, default="true", help="WHERE clause (default 'true', i.e. no filter)")
    parser.add_argument('-i', '--insert', required=False, action='store_false', dest='copymode', default=True,help='Use insert for SQL mode (default to COPY)')
    parser.add_argument('-n', '--noclean', required=False, action='store_true', default=False, help="Do not clean temporary SQL file after import")
    parser.add_argument('--name-field', required=False, default="name", help="Name of the field containing the name of each object (default 'name')", dest='name_field')
    parser.add_argument('--id-field', required=False, default="id", help="Name of the field containing the ID of each object (default 'id')", dest='id_field')
    parser.add_argument('--poi-type', required=False, default=5, help="Poi type (1: Car park, 2: shared car, 3: Cycle, 4:Shared cycle, 5:user)")
    parser.add_argument('--visum-modes', required=False, default="P,B,V,T",help=("Traffic rules for Visum data, under the format "
                              "'<mode_1>:<bitfield_value_1>,...,"
                              "<mode_n>:<bitfield_value_n>'"))
    parser.add_argument('--tempusaccess', required=False, action='store_true', default=False, help="Add this parameter if you want the reset action to also create 'tempus_access' and 'indic' schemas, otherwise only 'tempus' and 'tempus_gtfs' will be created.")
    args = parser.parse_args()
    
    if not args.srid and (args.action == 'import' or args.action == 'export') :
        sys.stderr.write("SRID needed for import or export. Assuming EPSG:4326.\n")
        shape_options['s'] = 4326
    else:
        shape_options['s'] = args.srid

    if args.copymode:
        shape_options['D'] = True
    if args.encoding:
        shape_options['W'] = args.encoding
    else:
        args.encoding = 'UTF8'
    
    # Default shp2pgsql options
    shape_options['I'] = True
    shape_options['g'] = 'geom'
    shape_options['S'] = True

    if args.pglite is not None:
        import pglite
        args.dbstring = pglite.cluster_params() + " dbname=" + args.pglite
        pglite.start_cluster()
	
	if args.dbstring is None:
		sys.stderr.write("Please provide a database connection string.\n")
		sys.exit(1)
	
    # Source deletion
    if args.action == 'delete':
        if args.data_type == 'pt':
            r = delete_pt_network(args)
            sys.exit(0)
        elif args.data_type == 'poi':
            r = delete_poi_source(args)
            sys.exit(0)
        elif args.data_type == 'road':
            r = delete_road_network(args)   
            sys.exit(0)
        elif args.data_type == 'zoning':
            r = delete_zoning(args)
            sys.exit(0)
        else:
            sys.stderr.write("Please provide a data type among 'pt', 'poi', 'road' or 'zoning'\n")
            sys.exit(1)
    
    # Source export
    if args.action == 'export':
        if args.path is None:
            sys.stderr.write("Please provide a destination file / directory.\n")
            sys.exit(1)
        if args.data_type == 'pt':
            r = export_pt_network(args)
            sys.exit(0)
        elif args.data_type == 'poi':
            r = export_poi_source(args)
            sys.exit(0)
        elif args.data_type == 'road':
            r = export_road_network(args)   
            sys.exit(0)
        elif args.data_type == 'zoning':
            r = export_zoning(args)
            sys.exit(0)
        else:
            sys.stderr.write("Please provide a data type among 'pt', 'poi', 'road' or 'zoning'\n")
            sys.exit(1)

    # Database reset
    if args.action == 'reset':
        reset_db(args)

    if args.action == 'import':
        if args.path is None:
            sys.stderr.write("Please provide a source file / directory.\n")
            sys.exit(1)
    
        r = None
        if args.data_type == 'road' and args.data_format == 'tomtom':
            r = import_road_tomtom(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'osm':
            args.path = args.path[0]
            r = import_road_osm(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'navteq':
            r = import_road_navteq(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'ign_route120':
            r = import_road_ign_route120(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'ign_route500':
            r = import_road_ign_route500(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'ign_bdtopo':
            r = import_road_ign_bdtopo(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'ign_bdcarto':
            r = import_road_ign_bdcarto(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'visum':
            r = import_road_visum(args, shape_options)
        elif args.data_type == 'road' and args.data_format == 'tempus':
            r = import_road_tempus(args, shape_options)
        elif args.data_type == 'pt' and args.data_format == 'gtfs':
            args.path = args.path[0]
            r = import_pt_gtfs(args)
        elif args.data_type == 'pt' and args.data_format == 'sncf':
            if (args.path[0] is None or args.path[1] is None or args.path[2] is None):
                sys.stderr.write("Please provide three path parameters: 2 paths to GTFS zip files (TER and IC) and 1 path to the shapefiles directory.\n")
                sys.exit(1)
            r = import_pt_sncf(args, shape_options)
        elif args.data_type == 'poi' and args.data_format == 'tempus':
            r = import_poi_tempus(args, shape_options)
        elif args.data_type == 'poi' and args.data_format == 'insee_bpe':
            r = import_poi_insee_bpe(args, shape_options)
        elif args.data_type == 'zoning' and args.data_format == 'ign_adminexpress':
            r = import_zoning_ign_adminexpress(args, shape_options)
        elif args.data_type == 'zoning' and args.data_format == 'tempus':
            r = import_zoning_tempus(args, shape_options)
        else:
            sys.stderr.write("Please provide coherent --data-type and --data-format parameters.\n")
            sys.exit(1)
        
        if not r:
            print "Error during import !"
            sys.exit(1)

    sys.exit(0)

if __name__ == '__main__':
    main()
