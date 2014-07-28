SignalNormalization<-function(table){
  for(c in 1:ncol(table)){
      maxElement<-max(table[ ,c])
      for (r in 1:nrow(table)){
           table[r,c]<-table[r,c]/maxElement
      }
  }
  return(table)
}



Dyadics_H3k4me3<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me3.txt", check.names=FALSE, header=T)
Dyadics_H3k4me1<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Dyadic_H3K4me1.txt", check.names=FALSE, header=T)
Promoters<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Promoter.txt", check.names=FALSE, header=T)
Enhancers<-read.table("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Enhancer.txt", check.names=FALSE, header=T)


Output<-SignalNormalization(Promoters)
write.table(Output,file="Promoter_Norm.txt",sep="\t")

Output<-SignalNormalization(Enhancers)
write.table(Output,file="Enhancers_Norm.txt",sep="\t")

Output<-SignalNormalization(Dyadics_H3k4me1)
write.table(Output,file="Dyadics_H3k4me1_Norm.txt",sep="\t")

Output<-SignalNormalization(Dyadics_H3k4me3)
write.table(Output,file="Dyadics_H3k4me3_Norm.txt",sep="\t")

