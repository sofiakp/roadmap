import ntpath
import os
import glob

bedFiles=glob.glob("/home/azarf/permutations/Overlaps/*.bed")
OutFile="/home/azarf/permutations/Overlaps/counts/Overlap_Counts.txt"

with open("exp_comp_overlap.tab", 'r') as file:
           fname=os.path.basename("exp_comp_overlap.tab")
           count=0
           lines = [line.strip() for line in file]
           for l in lines:
               if l.split('\t')[3].strip()==l.split('\t')[7].strip():
                  count=count+1
with open(OutFile, 'w') as out:
     out.write("{0}\t{1}\n".format(fname,count))

with open(OutFile, 'a') as out:
     for f in bedFiles:
        fname=os.path.basename(f)
        count=0
        with open(f, 'r') as file:
           lines = [line.strip() for line in file]
           for l in lines:
               if l.split('\t')[3].strip()==l.split('\t')[7].strip():
                  count=count+1
        out.write("{0}\t{1}\n".format(fname,count))
