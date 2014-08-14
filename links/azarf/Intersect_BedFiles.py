from os import listdir
import subprocess
path="/home/azarf/permutations/"
files = [ f for f in listdir(path)]
c=1
for f in files:
    file_name="/home/azarf/permutations/overlaps/overlap_"+str(f)
    c+=1
    with open(file_name, 'w') as out:
          subprocess.call(['intersectBed', '-a', 'experimental_Data.bed', '-b', path+f, '-wb'], stdout=out)
           
