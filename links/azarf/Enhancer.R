#Reading cell types
cellTypes<-read.table ("/home/azarf/cell_line_ids.txt",check.names=FALSE)

#Reading enhancers from their directory
EnhancerFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers",pattern=glob2rx("*.txt"))

#Create a matrix for enhancers and assign column and row names
Enhancer_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=240)
colnames(Enhancer_Mean_Signal) <- cellTypes[,1]
ESignalNames<-matrix( ,nrow=1,ncol=240)

index<-1
for(f in EnhancerFiles){
   string<-toString(f)
   temp<-gsub(".txt","",string)
   name<-gsub("E[0-9]{3}_H3K4me3_","",temp)
   ESignalNames[1,index]<-name
   index<-index+1
}
rownames(Enhancer_Mean_Signal)<-ESignalNames[1, ]

#Computing average signal for enhancers and store them in matrix
print("Start Enhancers")
for(f in EnhancerFiles) {
  file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers/",f)
  temp<-read.table(file,head=T)
  average<- mean(temp[ ,6])
  string<-toString(f)
  tmp<-gsub(".txt","",string)
  name<-gsub("E[0-9]{3}_H3K4me1_","",tmp)
  type<-gsub("_H3K4me1_cluster_[0-9]{1,3}.txt","",string)
  for( i in 1:nrow(Enhancer_Mean_Signal)){
     if(toString(rownames(Enhancer_Mean_Signal)[i])==toString(name)){
        for(j in 1:ncol(Enhancer_Mean_Signal)){
            if(toString(colnames(Enhancer_Mean_Signal)[j])==toString(type)){
               Enhancer_Mean_Signal[i,j]<-average
            }
        }
     }
  }
}
write.table(Enhancer_Mean_Signal,file="E.txt",sep="\t")
