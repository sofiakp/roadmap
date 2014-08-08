CompData<-read.table("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/core_15_enh_gene_c0.8_noCTCF_links.txt", header=F)
ExperData<-read.table("/home/azarf/mmc4.txt")
map<-read.table("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/segmentations/Oct13/core_15_mergedEnh_notOnProm_withDNase_names.bed")
print(ExperData)
ParseMatrix<-matrix( ,ncol=2, nrow=nrow(ExperData))

for( i in 1:nrow(ExperData)){
   for( j in 1:nrow(map)){
      if(ExperData[i,4]==map[j,2] & ExperData[i,5]==map[j,3]){
         ParseMatrix[i,1]<-map[j,4]
         print(ParseMatrix[i,1]<-map[j,4])
         ParseMatrix[i,2]<-gsub(".*?;(.*?);.*", "\\1", ExperData[i,13])
         print(ParseMatrix[i,2])
      }
   }
}

MatchData<-matrix( ,ncol=2, nrow=nrow(CompData))
for( i in 1:nrow(CompData)){
   for( j in 1:nrow(ParseMatrix)){
      if(CompData[i,1]==ParseData[j,1] & CompData[i,2]==ParseData[j,2]){
         MatchData[i, ]<-CompData[i, ]
      }
   }
}

print(MatchData)


