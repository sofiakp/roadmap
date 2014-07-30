#!/bin/bash

module add bedtools/2.18.0

OUTFILE=$1
LISTDIR=/srv/gsfs0/projects/kundaje/commonRepository/encode/data/byDataType/peaks_spp/mar2012/distinct/idrOptimalBlackListFilt/

FIRSTFILE=`ls $LISTDIR/*Ctcf* | head -1`
cp $FIRSTFILE $OUTFILE
tmpfile=${OUTFILE}.tmp.bed.gz

for infile in `ls $LISTDIR/*Ctcf*`; do 
    intersectBed -a $OUTFILE -b $infile | awk 'BEGIN{OFS="\t"}{print $1,$2,$3}' | sort -u | sort -V | gzip > $tmpfile
    mv $tmpfile $OUTFILE
done