"""
This script is used to fill tempus.sql's gtfs part
The SQL schema is extracted from gtfslib
"""
from __future__ import print_function
from gtfslib.orm import _Orm
import sqlalchemy
from sqlalchemy import create_engine
from sqlalchemy.schema import CreateTable

print("CREATE SCHEMA tempus_gtfs;")

# generate a SQL script for the creation of tables
# as well as indexes
engine = create_engine('sqlite:///:memory:')
o = _Orm(engine)
for t in o._metadata.sorted_tables:
    print("\nCREATE TABLE tempus_gtfs.{} (".format(t.name))
    createl = []
    for c in t.columns:
        l = "        " + c.name + " " + c.type.__str__()
        if not c.nullable:
            l += " NOT NULL"
        createl.append(l)
    createl.append("        PRIMARY KEY (" + ", ".join([c.name for c in t.primary_key.columns]) + ")")
    for fk in t.foreign_key_constraints:
        if fk.table.name == t.name:
            continue
        createl.append("        FOREIGN KEY (" + ", ".join([kc for kc in fk.column_keys]) + ") REFERENCES tempus_gtfs." + fk.table.name + "(" + ", ".join([kc.name for kc in fk.columns]) + ")")

    print(",\n".join(createl))
    print(");")

    for idx in t.indexes:
        print("CREATE INDEX {} ON tempus_gtfs.{}({});".format(idx.name, t.name, ",".join([c.name for c in idx.columns])))

