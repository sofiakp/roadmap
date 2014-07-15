Compute_Average_Signal<-function(files, filePath, fileType, Mean_Signal){
  for(f in files) {
   #print(toString(f))
   file<-file.path(filePath,f)
   temp<-read.table(file,head=T)
   average<- mean(temp[ ,6])
   string<-toString(f)
   tmp<-gsub(".txt","",string)
   if(fileType=="H3K4me3"){
   name<-gsub("E[0-9]{3}_H3K4me3_","",tmp)
   type<-gsub("_H3K4me3_cluster_[0-9]{1,3}.txt","",string)
   }

   if(fileType=="H3K4me1"){
   name<-gsub("E[0-9]{3}_H3K4me1_","",tmp)
   type<-gsub("_H3K4me1_cluster_[0-9]{1,3}.txt","",string)
   }
  
  for( i in 1:nrow(Mean_Signal)){
      if(toString(rownames(Mean_Signal)[i])==toString(name)){
        for(j in 1:ncol(Mean_Signal)){
            if(toString(colnames(Mean_Signal)[j])==toString(type)){
               Mean_Signal[i,j]<-average
            }
        }
      }
  }
  
}
 return(Mean_Signal)
}


cellTypes<-read.table ("/home/azarf/cell_line_ids.txt",check.names=FALSE)

PromoterFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters",pattern=glob2rx("*.txt"))

EnhancerFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers",pattern=glob2rx("*.txt"))

DyadicFiles<-dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic",pattern=glob2rx("*.txt"))


Promoter_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=85)
colnames(Promoter_Mean_Signal) <- cellTypes[,1]
PSignalNames<-matrix( ,nrow=1,ncol=85)

index<-1                                                              
for(i in 1:85){                                                       
    name<-paste("cluster_",i,sep="")                                  
    PSignalNames[1,index]<-name                                      
    index<-index+1                                                    
} 
rownames(Promoter_Mean_Signal)<-PSignalNames[1, ]
print(rownames(Promoter_Mean_Signal))

Enhancer_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=240)
colnames(Enhancer_Mean_Signal) <- cellTypes[,1]
ESignalNames<-matrix( ,nrow=1,ncol=240)

index<-1                                                              
for(i in 1:240){                                                     
    name<-paste("cluster_",i,sep="")                                  
    ESignalNames[1,index]<-name                                       
    index<-index+1                                                     
} 
rownames(Enhancer_Mean_Signal)<-ESignalNames[1, ]
print(rownames(Enhancer_Mean_Signal))
 
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
print(rownames(Dyadic_Mean_Signal)) 

filePath<-"/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters/"
fileType<-"H3K4me3"
Output<-Compute_Average_Signal(PromoterFiles, filePath,fileType,Promoter_Mean_Signal)
write.table(Output,file="Promoters.txt",sep="\t")
print("Promoter complete")

filePath<-"/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers/"
fileType<-"H3K4me1" 
Output<-Compute_Average_Signal(EnhancerFiles, filePath,fileType, Enhancer_Mean_Signal)
write.table(Output,file="Enhancers.txt",sep="\t")
print("Enhancer complete")

filePath<-"/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic/"
fileType<-"H3K4me3" 
Output<-Compute_Average_Signal(DyadicFiles, filePath,fileType, Dyadic_Mean_Signal)
write.table(Output,file="Dyadic_H3K4me3.txt",sep="\t")
print("Dyadic_H3K4me3 complete")

fileType<-"H3K4me1" 
Output<-Compute_Average_Signal(DyadicFiles, filePath,fileType, Dyadic_Mean_Signal)
write.table(Output,file="Dyadic_H3K4me1.txt",sep="\t")
print("Dyadic_H3K4me1 complete") 
