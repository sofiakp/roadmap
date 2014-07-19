ComputeCorrealtion<- function(table_1, table_2,Matrix){
for(i in 1:nrow(table_1)){
    for(j in 1:nrow(table_2)){
        corr<-cor(as.numeric(table_2[j,]),as.numeric(table_1[i,]))
        for(m in 1:nrow(Matrix)){
            if(rownames(Matrix)[m]==rownames(table_1)[i])
               for(n in 1:ncol(Matrix)){
                    if(colnames(Matrix)[n]==rownames(table_2)[j]){
                       Matrix[m,n]<-corr
                    }
               }
           }
       }
    }
 return(Matrix)
}


Promoters<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Promoter.txt", check.names=FALSE, header=T)
Enhancers<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Enhancer.txt", check.names=FALSE, header=T)
Dyadics_H3k4me3<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me3.txt", check.names=FALSE, header=T)
Dyadics_H3k4me1<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me1.txt", check.names=FALSE, header=T)


ERow_name<-matrix( ,nrow=1,ncol=240)
PRow_name<-matrix( ,nrow=1,ncol=85)
PCol_name<-matrix( ,nrow=1,ncol=85)
DCol_name<-matrix( ,nrow=1,ncol=193)

index<-1
for(i in 1:240){
    name<-paste("cluster_",i,sep="")
    ERow_name[1,index]<-name
    if( i<=85){
       PCol_name[1,index]<-name
       PRow_name[1,index]<-name
    }
    if(i<=193){
      DCol_name[1,index]<-name
    }
    index<-index+1
}

Corr_Matrix<-matrix( ,nrow=240,ncol=85)
rownames(Corr_Matrix)<-ERow_name[1, ]
colnames(Corr_Matrix)<-PCol_name[1, ]

for( p in 1:100){
   Promoter_permutation<-Promoters[,sample(ncol(Promoters))]
   Output<-ComputeCorrealtion(Enhancers,Promoter_permutation, Corr_Matrix)
   write.table(Output,file=paste("Promoter_Enhancer_Corr_P_",p,".txt", sep=""),sep="\t")
   print(paste(p,"_permutation", sep=""))
}

Corr_Matrix<-matrix( ,nrow=85,ncol=193)
rownames(Corr_Matrix)<-PRow_name[1, ]
colnames(Corr_Matrix)<-DCol_name[1, ]

for( p in 1:100){
   permutation<-Dyadics_H3k4me1[,sample(ncol(Dyadics_H3k4me1))]
   Output<-ComputeCorrealtion(Promoters,permutation, Corr_Matrix)
   write.table(Output,file=paste("Promoters_Dyadics_H3k4me1_Corr_P_",p,".txt", sep=""),sep="\t")
   print(paste(p,"_permutation", sep=""))
}

Corr_Matrix<-matrix( ,nrow=85,ncol=193)
rownames(Corr_Matrix)<-PRow_name[1, ]
colnames(Corr_Matrix)<-DCol_name[1, ]

for( p in 1:100){
   permutation<-Dyadics_H3k4me3[,sample(ncol(Dyadics_H3k4me3))]
   Output<-ComputeCorrealtion(Promoters,permutation, Corr_Matrix)
   write.table(Output,file=paste("Promoters_Dyadics_H3k4me3_Corr_P_",p,".txt", sep=""),sep="\t")
   print(paste(p,"_permutation", sep=""))
}

Corr_Matrix<-matrix( ,nrow=240,ncol=193)
rownames(Corr_Matrix)<-ERow_name[1, ]
colnames(Corr_Matrix)<-DCol_name[1, ]

for( p in 1:100){
   permutation<-Dyadics_H3k4me3[,sample(ncol(Dyadics_H3k4me3))]
   Output<-ComputeCorrealtion(Enhancers,permutation, Corr_Matrix)
   write.table(Output,file=paste("Enhancer_Dyadics_H3k4me3_Corr_P_",p,".txt", sep=""),sep="\t")
   print(paste(p,"_permutation", sep=""))
}

for( p in 1:100){
   permutation<-Dyadics_H3k4me1[,sample(ncol(Dyadics_H3k4me1))]
   Output<-ComputeCorrealtion(Enhancers,permutation, Corr_Matrix)
   write.table(Output,file=paste("Enhancer_Dyadics_H3k4me1_Corr_P_",p,".txt", sep=""),sep="\t")
   print(paste(p,"_permutation", sep=""))
}
