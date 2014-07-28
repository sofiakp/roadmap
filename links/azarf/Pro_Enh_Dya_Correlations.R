ComputeCorrealtion<- function(table_1, table_2,Matrix){
for(i in 1:nrow(table_1)){
    for(j in 1:nrow(table_2)){
        corr<-cor(as.numeric(table_2[j,]),as.numeric(table_1[i,]))
         Matrix[i,j]<-corr
       }
    }
 return(Matrix)
}



Dyadics_H3k4me3<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me3.txt", check.names=FALSE, header=T)
Dyadics_H3k4me1<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me1.txt", check.names=FALSE, header=T)
Promoters<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Promoter.txt", check.names=FALSE, header=T)
Enhancers<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Enhancer.txt", check.names=FALSE, header=T)




Corr_Matrix<-matrix( ,nrow=nrow(Enhancers),ncol=nrow(Promoters))
rownames(Corr_Matrix)<-rownames(Enhancers)
colnames(Corr_Matrix)<-rownames(Promoters)

Output<-ComputeCorrealtion(Enhancers, Promoters, Corr_Matrix)
write.table(Output,file="Promoter_Enhancer_Corr.txt",sep="\t")

print("Enhacer_Promoter complete")

Corr_Matrix<-matrix( ,nrow=nrow(Enhancers),ncol=nrow(Dyadics_H3k4me1))
rownames(Corr_Matrix)<-rownames(Enhancers)
colnames(Corr_Matrix)<-rownames(Dyadics_H3k4me1)

Output<-ComputeCorrealtion(Enhancers, Dyadics_H3k4me1, Corr_Matrix)
write.table(Output,file="Enhancer_Dyadics_H3k4me1_Corr.txt",sep="\t")
print("Enhacer_H3k4me1 complete") 

Output<-ComputeCorrealtion(Enhancers, Dyadics_H3k4me3, Corr_Matrix)
write.table(Output,file="Enhancer_Dyadics_H3k4me3_Corr.txt",sep="\t")
print("Enhacer_H3k4me3 complete") 

Corr_Matrix<-matrix( ,nrow=nrow*Promoters),ncol=nrow(Dyadics_H3k4me1))
rownames(Corr_Matrix)<-rownames(Promoters)
colnames(Corr_Matrix)<-rownames(Dyadics_H3k4me1)

Output<-ComputeCorrealtion(Promoters, Dyadics_H3k4me1, Corr_Matrix)
write.table(Output,file="Promoter_Dyadics_H3k4me1_Corr.txt",sep="\t")
print("Promoter_Hek4me1 complete") 

Output<-ComputeCorrealtion(Promoters, Dyadics_H3k4me3, Corr_Matrix)
write.table(Output,file="Promoter_Dyadics_H3k4me3_Corr.txt",sep="\t")
print("Promoter_Hek4me3 complete")
