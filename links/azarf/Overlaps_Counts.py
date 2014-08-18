import ntpath
import os
import glob

files=glob.glob("/home/azarf/permutations/Overlaps/*.bed")
OutFile="/home/azarf/permutations/Overlaps/Counts/Overlaps_Counts.txt"

with open(OutFile, 'w') as out:
     for f in files:
        fname=os.path.basename(f)
        num_lines = sum(1 for line in open(f))
        out.write("{0}\t{1}\n".format(fname,num_lines))
           
