#!/bin/bash

# file: add_unique_ids.sh
# usage:$ add_unique_ids.hs <path_to_bed_files>
# =============================================
# This file reformats all of the .bed files in a given
# directory. It removes all but the first 3 columns, and 
# then adds a unique id ([filename_prefix]_[linenumber]),
# a "." (to ignore), and then a "+" to indicate positive 
# strand. This is so our .bed files can match the HOMER 
# format.  

for FILE in $1/*.bed
do
        OUTFILE="${FILE}.pos_strand.bed"
        cut -f1-3 $FILE > tmp.out
	xbase=${FILE##*/}
	xpref=${xbase%.*}
	awk -v file=${xpref} '{print $0 "\t" (file) "_" NR "\t.\t+";}' tmp.out > $OUTFILE
        #awk '{print $0"\t+"}' tmp.out > $OUTFILE
        mv $OUTFILE $FILE
        rm tmp.out
done



