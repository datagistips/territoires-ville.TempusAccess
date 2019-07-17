#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Tempus database reseter

import provider
    
def reset_db(args):
    subs = {}
    subs["temp_schema"] = provider.config.TEMPSCHEMA
    if args.tempusaccess is not None:
        if args.path is None:
            sys.stderr.write("The path to initialization data must be specified with --path !\n")
            sys.exit(1)
        r = provider.ResetTempusAccess(path=args.path[0], dbstring=args.dbstring, logfile=args.logfile, subs = subs, encoding = args.encoding, sep=args.sep)
        return r.run()
    else:
        r = provider.ResetTempus(path='', dbstring=args.dbstring, logfile=args.logfile)
        return r.run()
        
    
    