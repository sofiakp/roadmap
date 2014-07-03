#!/bin/bash

#FILENAME: homer_default_bg.sh
#USAGE: ./homer_default_bg.sh <cluster_file_with_path>
#EXAMPLE: ./homer_default_bg.sh ./enhancher_cluster_bed_files/cluster_1.bed

#NOTES: This script assumes that you have homer installed (including hg19 genome)
#	If you don't have hg19, you can run
#	 "perl [path_to_homer]/configureHomer.pl -install hg19"
# It also assumes that the directory you point to has all of the other
# cluster files you need in it (the background files), and that they are
# all named "cluster_[#].bed". It also assumes that the cluster files are
# in the BED format (6-column) specified at http://homer.salk.edu/homer/ngs/formats.html

#SETTING OPTIONS FOR SCRIPT (######DISABLED#########)
#================================
# set the name of the job (NOT CURRENTLY USED)
# -N $USER_homer_enhancers
#
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
# -e hoc_dbg_error.log
#
# print standard output to stdout.txt
# -o hoc_dbg_stdout.txt
#
# Set the working directory for the job
# -wd /home/tsdavis
#
# Request more memory
# -l h_vmem=30G
#

#make sure we've added scripts to path
source ~/.bash_profile

#split up file and path names in order to dynamically create outputs
xpath=${1%/*}
xbase=${1##*/}
xpref=${xbase%.*}

if [[ -n "$2" ]]; then
	output_dir=$2
else    
	output_dir="${xpref}_motifs_default_bg"
fi     

#run homer!
findMotifsGenome.pl $1 hg19 $output_dir -size 200 -olen 2

