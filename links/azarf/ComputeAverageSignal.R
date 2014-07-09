#Reading cell types
cellTypes<-read.table ("/home/azarf/cell_line_ids.txt",check.names=FALSE)

#Reading promoters from their directory
PromoterFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters",pattern=glob2rx("*.txt"))

#Create a matrix for promoters and assign column and row names
Promoter_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=10797)
colnames(Promoter_Mean_Signal) <- cellTypes[,1]
PSignalNames<-matrix( ,nrow=1,ncol=10797)

index<-1
for(f in PromoterFiles){
   string<-toString(f)
   name<-gsub(".txt","",string)
   PSignalNames[1,index]<-name
   index<-index+1
}
rownames(Promoter_Mean_Signal)<-PSignalNames[1, ]

#Reading dyadics from their directory
DyadicFiles<-dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic",pattern=glob2rx("*.txt"))

#Create a matrix for dyadics and assign column and row names
Dyadic_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=24513)
colnames(Dyadic_Mean_Signal) <- cellTypes[,1]
DSignalNames<-matrix( ,nrow=1,ncol=24513)

index<-1
for(f in DyadicFiles){
   string<-toString(f)
   name<-gsub(".txt","",string)
   DSignalNames[1,index]<-name
   index<-index+1
}
rownames(Dyadic_Mean_Signal)<-DSignalNames[1, ]


#Reading enhancers from their directory
EnhancerFiles<- dir("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers",pattern=glob2rx("*.txt"))

#Create a matrix for enhancers and assign column and row names
Enhancer_Mean_Signal<-matrix( ,ncol=nrow(cellTypes),nrow=30482)
colnames(Enhancer_Mean_Signal) <- cellTypes[,1]
ESignalNames<-matrix( ,nrow=1,ncol=30482)

index<-1
for(f in EnhancerFiles){
   string<-toString(f)
   name<-gsub(".txt","",string)
   ESignalNames[1,index]<-name
   index<-index+1
}
rownames(Enhancer_Mean_Signal)<-ESignalNames[1, ]



#Computing average signal for promoters and store them in matrix
Print("Start Promoters")
for(f in PromoterFiles) {
   file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/promoters/",f)
   temp<-read.table(file,head=T)
   average<- mean(temp[ ,6])
   string<-toString(f)
   name<-gsub(".txt","",string)
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

#Computing average signal for dyadics and store them in matrix
print("start dyadics")
for(f in DyadicFiles) {
   file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/dyadic/",f)
   temp<-read.table(file,head=T)
   average<- mean(temp[ ,6])
   string<-toString(f)
   name<-gsub(".txt","",string)
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

#Computing average signal for enhancers and store them in matrix
print("Start Enhancers")
for(f in EnhancerFiles) {
  file<-file.path("/srv/gsfs0/projects/kundaje/users/sofiakp/roadmap/links/signal/enhancers/",f)
  temp<-read.table(file,head=T)
  average<- mean(temp[ ,6])
  string<-toString(f)
  name<-gsub(".txt","",string)
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




