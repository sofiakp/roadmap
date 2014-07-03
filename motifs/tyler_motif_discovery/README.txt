What's up, everybody?

Here is a brief tour of this directory, and an explanation of the files as they
currently exist (as of Saturday night, May 24th, 2014 at about 10:05pm).


DIRECTORY TOUR:
==============================================================
this directory is /srv/gsfs0/projects/kundaje/users/tsdavis/ .
Congratulations, you made it! Subfolders of this directory are:
==============================================================
 - data: This has the directory(ies) that contain the enhancer clusters.

 - scripts: these are all the scripts that I wrote
	
	- 

	* NOTE, they have to remain in the same directory as each other, 
	because they all call eachother and they assume this. See
	"calling scripts" below for deets. 
	** Also, the script "install_homer.sh" has never been tested. I ran
	those commands all separately, and then tried to document as best
	I could. So, it's maybe a good reference but don't try to run it 
	to actually install homer

 - bin: all of the downloaded executables (aka homer and its dependencies)
	-  ghostscript
	-  weblogo
	-  blat
	-  homer

 - motifs: the folder with all the output. Subfolders are:
	-  size_200: (has all default settings (aka -size 200 and nothing
	   else), with the exception of the background set. cluster outputs
	   in here are labelled with their background set, i.e.
	   "motifs_with_10x_background"
	-  size_given: everything run WITH A CUSTOM BACKGROUND SET uses size
	   given. however, the default background set control output uses size
	   200. 
		- different "olen" subdirs are in here.

CALLING SCRIPTS:
==============================================================
These are the steps you will want to take to successfully run the scripts
from this directory.
==============================================================
 - put the data files (clusters of enhancers) in some directory (currently in
   ./data/enhancer_clusters)

 - create a .txt file that has the paths to each cluster that we want to run
   motif discovery on. e.g. if we wanted to run homer on cluster_1 and
   cluster_2, our file would look like:
--------------------------------------------------------------------------------
	srv/gsfs0/projects/kundaje/users/tsdavis/data/enhancer_clusters/cluster_1.bed
	srv/gsfs0/projects/kundaje/users/tsdavis/data/enhancer_clusters/cluster_2.bed
--------------------------------------------------------------------------------

 - edit the files "homer_on_cluster.sh" and "homer_default_bg.sh".
	 - SPECIFICALLY, change the final line that runs homer to have the
	   parametes you want (size, olen, etc.)
	 - right now, homer_on_cluster.sh and homer_default_bg.sh are called
	   seaprately (i.e. from different scripts), and so you need to make
	   sure to edit both if you want to make sure the parameters are the same
	   (besides background, and probably -size.)
	 - NOTE: if you are using homer's default background, don't use "-size
	   given." For some reason it seems not to work.

 - run either "submit_batch" or "submit_batch_default" (for custom background
   or default background, respectively):
	 - $ submit_batch <batch_input_file> <batch_output_directory>
	 - [same for submit_batch_default]
	 - <batch_input_file> refers to the path of the txt file above, with the
	   list of clusters to analyze (e.g. test_batch.txt)
	 - <batch_output_directory> is the directory where each cluster
	   analysis will go. I have been describing them by their parameters 
	   (e.g. motifs/size_given/olen_2). Then, each clusters motif folder
	   for that run will be found in "<batch_ouput_dir>/cluster_[#]_motifs"
		- this directory does not have to exist yet. It can (and will
		  raise an error but continue), but make sure there aren't
		  other files that it will overwrite. 

 - wait. It will send an email to you (current user) when each job is finished
   (one job corresponds to one cluster's motifs). Jobs each generally run 15
   minutes to 3 hours.


