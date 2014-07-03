#!/bin/bash

#FILENAME: homer_on_cluster.sh
#USAGE: ./homer_on_cluster.sh <cluster_file_with_path>
#EXAMPLE: ./homer_on_cluster.sh ./enhancher_cluster_bed_files/cluster_1.bed

#NOTES: This script assumes that you have homer installed (including hg19 genome)
#	If you don't have hg19, you can run
#	 "perl [path_to_homer]/configureHomer.pl -install hg19"
# It also assumes that the directory you point to has all of the other
# cluster files you need in it (the background files), and that they are
# all named "cluster_[#].bed". It also assumes that the cluster files are
# in the BED format (6-column) specified at http://homer.salk.edu/homer/ngs/formats.html

#add bedtools module
module add bedtools/2.19.1

#make sure to import paths to necessary scripts:
source ~/.bash_profile

#split up file and path names in order to dynamically create outputs
#cf is short for "cluster file"
cf_path=${1%/*}
cf_base=${1##*/}
cf_pref=${cf_base%.*}

if [[ -n "$2" ]]; then
	output_dir=$2
else
	output_dir="${cf_pref}_motifs"
fi

#create bed file with background enhancer regions
#and subsample from it
background_file="${output_dir}/${cf_pref}_background.bed"
create_background_file.sh $1 $background_file

bg_lines=$(wc -l < "$background_file")
fg_lines=$(wc -l < $1)
tenFG=$(($fg_lines * 10))
bg_sample_file="${output_dir}/${cf_pref}_background_sampled.bed"
if [[ "$tenFG" -gt "$bg_lines" ]]
	mv $background_file $bg_sample_file
else
	create_background_subsample.sh $1 $background_file
fi

rm $background_file

#run homer!
findMotifsGenome.pl $1 hg19 $output_dir -size given -bg $bg_sample_file -nlen 0 -noweight

rm $bg_sample_file
error_file="${output_dir}/${cf_pref}_error.log"
stdout_file="${output_dir}/${cf_pref}_stdout.txt"
#rm $error_file
#rm $stdout_file

