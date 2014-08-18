#!/bin/bash

MYDIR=/home/azarf/permutations/*
EXPData=/home/azarf/experimental_Data.bed
c=0
for f in $MYDIR
do
  c=$((c+1))
  echo $c
  filename=$(basename "$f")
  extension="${filename##*.}"
  filename="${filename%.*}"
  temp="_overlap.bed"
  name=$filename$temp
  echo $name
  intersectBed -a $EXPData -b $f > $name
done
