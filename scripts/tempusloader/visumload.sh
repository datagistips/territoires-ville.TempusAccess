#!/bin/bash
# Run tempus_loader program main command with arguments dedicated to Visum loader

echo Run tempus loader...

python load_tempus.py -d "dbname=visum_tempus" -R -t visum -s data_driea/180130_ReseauVP_DRIEA/ -p reseau_vp_ -W LATIN1 --visum-modes P,B,V,T
