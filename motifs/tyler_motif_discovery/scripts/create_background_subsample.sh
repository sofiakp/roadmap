#!/bin/sh

# send mail when job ends or aborts
# -m ea
#
# specify an email address
# -M tsdavis@stanford.edu
#
# check for errors in the job submission options
# -w e
#
# print error output to error.log
# -e error.log
#
# print standard output to stdout.txt
# -o stdout.txt

#usage: ./create_background_subsample.sh <foreground_file> <background_file>

fgfile=$1
bgfile=$2

fg_base=${1##*/}
fg_pref=${fg_base%.*}

bg_path=${2%/*}
bg_base=${2##*/}
bg_pref=${bg_base%.*}


numPeaksFG=$(wc -l < $fgfile ) 
tenFG=$(($numPeaksFG * 10))
linesToUse=50000 #50,000 lines as default, but we use at least 2x if larger
if [[ "$tenFG" -gt "$linesToUse" ]]
then
	linesToUse=$tenFG
fi

module add bedtools/2.19.1
sampled="${bg_path}/${bg_pref}_sampled.bed"

bedtools sample -n $linesToUse -i  $bgfile > $sampled

echo $sampled
