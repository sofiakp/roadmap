Dyadics_H3k4me3<-read.table("RoadMap/signal/Dyadic_H3K4me3.txt", check.names=FALSE, header=T)
Promoters<-read.table("RoadMap/signal/Promoter.txt", check.names=FALSE, header=T)

Corr_Matrix<-matrix( ,nrow=85,ncol=193)
PRow_name<-matrix( ,nrow=1,ncol=85)
DCol_name<-matrix( ,nrow=1,ncol=193)



index<-1
for(i in 1:85){
    name<-paste("cluster_",i,sep="")
    PRow_name[1,index]<-name
    index<-index+1
}

index<-1
for(i in 1:193){
    name<-paste("cluster_",i,sep="")
    DCol_name[1,index]<-name
    index<-index+1
}

rownames(Corr_Matrix)<-PRow_name[1, ]
colnames(Corr_Matrix)<-DCol_name[1, ]


for(i in 1:nrow(Promoters)){
    for(j in 1:nrow(Dyadics_H3k4me3)){
        corr<-cor(as.numeric(Dyadics_H3k4me3[j, ]),as.numeric(Promoters[i, ]))
        for(m in 1:nrow(Corr_Matrix)){
           for(n in 1:ncol(Corr_Matrix)){
              if(rownames(Corr_Matrix)[m]==rownames(Promoters)[i] & colnames(Corr_Matrix)[n]==rownames(Dyadics_H3k4me3)[j])
                 Corr_Matrix[m,n]<-corr
           }
        }
    }
}

write.table(Corr_Matrix,file="Promoters_Dyadics_H3k4me3_Corr.txt",sep="\t")
