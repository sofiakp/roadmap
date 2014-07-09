# Discovering and scoring motifs
### Hello!

This readme explains the steps taken to discover and score motifs across various regulator sequence clusters, and also explains the scripts in this directory. There are a couple other readme files (also in this directory and referenced below)

### This ReadMe contains:
  - Installing Pacakges/Dependencies
  - Data Sources
  - Setup
  - Overview of Scripts
  - Motif Discovery
  - Motif extraction and filtering
  - Motif scoring

### Installing Packages/Dependencies
##### What you need:
  - bedtools (included with scg cluster) 
  - homer *(see "Installing Homer.md")*
(I think that's it)

### Data Sources

Motif discovery was performed on three sets of sequence clusters, each corresponding to different types of regulatory regions. The three types of region clusters are:
  - dyadic
  - promoters
  - enhancers
The BED files for each regulatory group were obtained from the Roadmap/Encode project. I copied them from files in professor Kundaje's lab directory. The clusters files were found in `/srv/gsfs0/projects/kundaje/commonRepository/epigenomeRoadmap/integrative/regulatoryRegions/ENCODERoadmap/WM20140519_DNaseI_region_clustering_<regulator_type>/BED_files/` and copied locally.

### Setup
###### These are additional miscellaneous steps taken to run everything correctly
  - symlinked /home/tsdavis/mylab to /srv/gsfs0/projects/kundaje/users/tsdavis/ for ease of use.
  - add scripts directory to PATH. Edited ~/.bash_profile to include /home/tsdavis/mylab/scripts so they could be run from any of my directories
    - This also means I had to `source ~/.bash_profile` in a few scripts. This should probably be changed to directly reference /home/tsdavis/.bash_profile. It might cause problems if other users try to run it; but I don't know because I am not someone else.
  - copied and unzipped BED files into  /home/tsdavis/mylab/data/<regulator_type>/BED_files
  - created all_sequences.BED (by using a simple `cat` command) to score motifs after discovery.

### Overview of Scripts

#### Modules
There are 6 basic functionalities of the scripts included in this directory (in rough operational order):
  - **adding unique ids** to the sequences of each cluster
  - **discovering enriched motifs** in a cluster versus other clusters of sequences
  - **extracting discovered motifs** into single motif files, organized by cluster
  - **filtering nonsignificant motifs** based on HOMER's assigned p-value
  - **scoring single motifs** across all sequences
  - **combining the scores** into a single large motif file.

#### Adding unique ids:
###### **File:** add_unique_ids.sh
This adds unique ids to the BED files in a directory. HOMER needs unique_ids to run properly. usage:
```
add_unique_ids.sh ~/mylab/data/promoters/BED_files.
```
NOTE: This will ERASE everything but the first 3 columns, then add the unique id as the 4th. This was fine for the purposes of HOMER but if we ever want to store additional data in the other columns, we should refactor the code.

#### Discovering enriched motifs in a cluster:
###### **Files:** create_background_file, create_background_subsample, homer_on_cluster, homer_default_bg, qsub_homer, submit_batch, submit_batch_default.
Basically, the only 2 scripts that you need to run (which call the others) would be (the brilliantly ambiguously-named) **submit_batch**, or **submit_batch_default**. The former uses a sample of sequences from the other clusters (all non-current clusters) as the background set to test for enrichment, whereas the latter uses the default background (a subsample across the entire hg19 genome, with some normalization).
usage:
`submit_batch <batch_input_directory> <batch_output_directory>`, OR `submit_batch <batch_input_file> <batch_output_directory>`
The first option lets you specify the input directory. This iterates through the bed files in a directory, and discovers motifs on the clusters therein, vs. the other clusters. The second option allows you to create a file, specifying paths to bed files for which you want motifs discovered. for example, a file that reads:
```
/home/tsdavis/mylab/data/promoters/BED_files/cluster_1.bed
/home/tsdavis/mylab/data/promoters/BED_files/cluster_10.bed
/home/tsdavis/mylab/data/promoters/BED_files/cluster_42.bed
```
would do motif discovery on each of those 3 clusters (but still use all sequences in the other files in the same directory as the background set). Both submit_batch and submit_batch_default can take either of these formats as the first argument.
These scripts call all of the other scripts listed in this section (for example, `submit_batch` calls `qsub_homer` for each cluster, which submits the job `homer_on_cluster`, which includes a call to `create_background_subsample`). 

#### Extracting Discovered Motifs
###### **Files:** extract_motifs
This script is a little confusing. The current usage is `extract_motifs <path_to_clusters_directory>`. **HOWEVER**, the *output directory* is hard coded into the first line of the script. So, for different groups (i.e. dyadic vs. promoter vs. enahcner), it is important to make sure that the path is changed to be the correct place that you want the single motifs to live (they currently reside in /home/tsdavis/mylab/data/<group_type>/single_motifs). 
With this script (as with all others in this directory), if the specified output directory does not exist, it will create it for you.

#### Filtering Non-Significant Motifs
###### **Files:** remove_nonsignificant_motifs, remove_nonsig_motif_scores
**Removing motifs**: Ideally, we do this step, right after motif extraction. the usage is simply:
```
remove_nonsignificant_motifs <path_to_motif_files_directory>
```
The path need not contain the motif files directly (i.e. you can use data/promoters/single_motifs, which contains subdirectories for each cluster). However each file must contain exactly one motif.

**Removing motif scores**: If we did not remove motifs at the previous step, and have instead scored all the motifs (including the nonsignificant ones), we would want to run the other script,
```
remove_nonsig_motif_scores <motifs_dir> <motifs_scores_dir>
```
We need to include both these arguments so that we can determine "nonsignificance" from the motifs directory, and then remove the corresponding score from the motifs_scores_dir. (Note that if you've already scored all motifs before filtering, you DO NOT want to run `remove_nonsignificant_motifs`, as this will delete the motifs but not the scores, and then you're SOL.).

#### Scoring Single Motifs
###### **Files:** submit_scan_motifs, submit_scan_motifs_batch, write_scan_motifs, write_scan_motifs_batch
NOTE: To do this step, you need a file that has all of the sequences in it. This can easily be done by running a command such as:
```
cat data/promoters/BED_files/* > data/promoters/all_sequences.bed
```
To score all motifs, run `submit_scan_motifs_batch <path_to_motif_files> <all_sequences_file> <output_dir>`
ALSO NOTE: This script works by submitting a job for each motif. If there are a total of more than 4000 motifs in total, this will cause you to run into issues because you'll max out your jobs. To address this, use `write_scan_motifs_batch` in the exact same way (however, instead of executing each job submission, it writes them all to a file). Then, you can `head/tail` the file, and run it as a bash script (4000 lines at a time). 

#### Combining the scores
###### **Files:** paste_files (you do not need to use submit_paste_files, as pasting is relatively fast).
usage: `paste_files <cluster_motif_score_dir>`
This will paste files (that each have the scores for an individual motif across all sequences) into one file. That way, you are left with a single file containing the scores for all of the motifs in a cluster.

**A NICE TODO** would be to write a quick script that calls `paste_files` for each cluster in a group directory. Because doing one for each cluster would be tedious.

