#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus data merging

import provider

def merge_pt_networks(args):
    subs = {}
    if args.source_name is None:
        sys.stderr.write("The PT network name must be specified with --source-name ! \n")
        sys.exit(1)
    if args.source_list is None:
        sys.stderr.write("A PT network list must be specified with --source-list !\n")
        sys.exit(1)
    subs["source_name"] = args.source_name
    subs["source_list"] = args.source_list
    subs["max_dist"] = str(args.max_dist)
    splitted_options = args.pt_merge_options.split(',')
    if len(splitted_options) != 7:
        sys.stderr.write(("Need 7 comma-separated strings "
                          "(command --pt-merge-options) for representing if stops, agencies, services, routes, trips, fares and shapes (in this order) are merged when having the same name.\n"))
        sys.exit(1)
    ptm = provider.MergePT(dbstring = args.dbstring, logfile = args.logfile, subs = subs, pt_merge_options = splitted_options)
    return ptm.run()


