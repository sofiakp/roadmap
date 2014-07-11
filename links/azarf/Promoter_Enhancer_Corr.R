Promoters<-read.table("RoadMap/signal/Promoter.txt", check.names=FALSE, header=T)
Enhancers<-read.table("RoadMap/signal/Enhancer.txt", check.names=FALSE, header=T)
print(dim(Promoters))


Corr_Matrix<-matrix( ,nrow=240,ncol=85)
ERow_name<-matrix( ,nrow=1,ncol=240)
PCol_name<-matrix( ,nrow=1,ncol=85)



index<-1
for(i in 1:240){
    name<-paste("cluster_",i,sep="")
    ERow_name[1,index]<-name
    index<-index+1
}

index<-1
for(i in 1:85){
    name<-paste("cluster_",i,sep="")
    PCol_name[1,index]<-name
    index<-index+1
}

rownames(Corr_Matrix)<-ERow_name[1, ]
colnames(Corr_Matrix)<-PCol_name[1, ]

for(i in 1:nrow(Enhancers)){
    for(j in 1:nrow(Promoters)){
        corr<-cor(as.numeric(Promoters[j,]),as.numeric(Enhancers[i,]))
        print(corr)
        for(m in 1:nrow(Corr_Matrix)){
           for(n in 1:ncol(Corr_Matrix)){
              if(rownames(Corr_Matrix)[m]==rownames(Enhancers)[i] & colnames(Corr_Matrix)[n]==rownames(Promoters)[j]){
                 Corr_Matrix[m,n]<-corr
              }
           }
        }
    }
}

write.table(Corr_Matrix,file="Promoter_Enhancer_Corr.txt",sep="\t")
