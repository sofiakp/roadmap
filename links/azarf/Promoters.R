#Reading cell types
cellTypes<-read.table ("/home/azarf/cell_line_ids.txt",check.names=FALSE)

#Reading promoters from their directory
PromoterFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters",pattern=glob2rx("*.txt"))

#Create a matrix for promoters and assign column and row names
Promoter_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=85)
colnames(Promoter_Mean_Signal) <- cellTypes[,1]
PSignalNames<-matrix( ,nrow=1,ncol=85)

index<-1
for(f in PromoterFiles){
   string<-toString(f)
   temp<-gsub(".txt","",string)
   name<-gsub("E[0-9]{3}_H3K4me3_","",temp)
   PSignalNames[1,index]<-name
   index<-index+1
}
rownames(Promoter_Mean_Signal)<-PSignalNames[1, ]

#Computing average signal for promoters and store them in matrix
Print("Start Promoters")
for(f in PromoterFiles) {
   file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters/",f)
   temp<-read.table(file,head=T)
   average<- mean(temp[ ,6])
   string<-toString(f)
   tmp<-gsub(".txt","",string)
   name<-gsub("E[0-9]{3}_H3K4me3_","",tmp)
   type<-gsub("_H3K4me3_cluster_[0-9]{1,3}.txt","",string)
  
  for( i in 1:nrow(Promoter_Mean_Signal)){
      if(toString(rownames(Promoter_Mean_Signal)[i])==toString(name)){
        for(j in 1:ncol(Promoter_Mean_Signal)){
            if(toString(colnames(Promoter_Mean_Signal)[j])==toString(type)){
               Promoter_Mean_Signal[i,j]<-average
            }
        }
      }
  }
  
}
write.table(Promoter_Mean_Signal,file="P.txt",sep="\t")
