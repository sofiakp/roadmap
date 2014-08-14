import numpy as np

with open('Computational_Data.bed', 'rb') as f:
     table = [row.strip().split('\t') for row in f]
c=1
for p in range(1,101):
    shuffle=np.random.permutation([row[3] for row in table])
    
    for i in range(0,len(shuffle)):
        table[i][3]=shuffle[i]
    file_name="/home/azarf/permutations/Per_"+str(c)+".bed"
    c+=1
    with open(file_name, "w") as f:
         for row in table:     
             chr_name=((str(row).split(',')[0].strip()).replace("['","")).replace("'","")
             start=(str(row).split(',')[1].strip()).replace("'","")
             end=(str(row).split(',')[2].strip()).replace("'","")
             gene_name=((str(row).split(',')[3].strip()).replace("']","")).replace("'","")
             f.write('{0}\t{1}\t{2}\t{3}\n'.format(chr_name,start,end,gene_name))
