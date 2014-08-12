f=open("core_15_enh_gene_c0.8_noCTCF_links.bed","r")
file=open("enh_name.txt","a")

for line in f:
    word=line.split('\t')[0]
    file.write(word.strip()+'\n')

lines=open("enh_name.txt","r").readlines()
lines_set = set(lines)

out= open('enh_list.txt', 'w')

for line in lines_set:
    out.write(line.strip()+'\n')

f1=open("enh_list.txt", "r")
f2=open("core_15_enh_gene_c0.8_noCTCF_links.txt","r").readlines()
out= open('enh_gene_map.txt', 'w')
c=0
for line1 in f1:
    string=""
    word1=line1.split('\t')[0]
    string+=word1.strip()+"	"
  
    for line2 in f2:
        word2=line2.split('\t')[0]

        if word1.strip()==word2.strip():
           gene_name=line2.split('\t')[1]
           string+=gene_name.strip()+" "
           

    out.write(string+"\n")
    
    
