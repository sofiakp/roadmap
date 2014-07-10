#Reading cell types
cellTypes<-read.table ("/home/azarf/cell_line_ids.txt",check.names=FALSE)

#Reading dyadics from their directory
DyadicFiles<-dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic",pattern=glob2rx("*.txt"))

#Create a matrix for dyadics and assign column and row names
Dyadic_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=193)
colnames(Dyadic_Mean_Signal) <- cellTypes[,1]
DSignalNames<-matrix( ,nrow=1,ncol=193)
index<-1
for(i in 1:193){
    name<-paste("cluster_",i,sep="")
    DSignalNames[1,index]<-name
   index<-index+1
}



rownames(Dyadic_Mean_Signal)<-DSignalNames[1, ]

#Computing average signal for dyadics and store them in matrix
print("start dyadics")
for(f in DyadicFiles) {
   file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic/",f)
   temp<-read.table(file,head=T)
   average<- mean(temp[ ,6])
   string<-toString(f)
   tmp<-gsub(".txt","",string)
   name<-gsub("E[0-9]{3}_H3K4me3_","",tmp)
   type<-gsub("_H3K4me3_cluster_[0-9]{1,3}.txt","",string)
   for( i in 1:nrow(Dyadic_Mean_Signal)){
      if(toString(rownames(Dyadic_Mean_Signal)[i])==toString(name)){
         for(j in 1:ncol(Dyadic_Mean_Signal)){
             if(toString(colnames(Dyadic_Mean_Signal)[j])==toString(type)){
                 Dyadic_Mean_Signal[i,j]<-average
             }
         }
      }
   }
}
write.table(Dyadic_Mean_Signal,file="D.txt",sep="\t")
