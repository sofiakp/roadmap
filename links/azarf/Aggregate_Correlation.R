Aggregate_Correlation<-function(files,filepath){
      n<-1
      mylist<-list()
     for(f in files) {
        mylist[[n]]<-file.path(filePath,f)
        n<-n+1
     }
     listOfMatrices<-lapply(mylist, function(x) read.table(x,header=T))
     Aggregate_Matrix<-do.call(rbind, listOfMatrices)
return(Aggregate_Matrix)
}



Promoter_Enhancer<-list.files("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_Enhancer",pattern=glob2rx("*.txt"))
filePath="/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_Enhancer"
Output<-Aggregate_Correlation(Promoter_Enhancer,filePath)
write.table(Output,file="Promoter_Enhancer_Corr_Agg.txt",sep="\t"row.names=F , col.names=F)

Promoter_H3K4me1<-list.files("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_H3K4me1",pattern=glob2rx("*.txt"))
filePath="/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_H3K4me1"
Output<-Aggregate_Correlation(Promoter_H3K4me1,filePath)
write.table(Output,file="Promoter_H3K4me1_Corr_Agg.txt",sep="\t"row.names=F , col.names=F)

Promoter_H3K4me3<-list.files("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_H3K4me3",pattern=glob2rx("*.txt"))
filePath="/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Promoter_H3K4me3"
Output<-Aggregate_Correlation(Promoter_H3K4me3,filePath)
write.table(Output,file="Promoter_H3K4me3_Corr_Agg.txt",sep="\t"row.names=F , col.names=F)

Enhancer_H3K4me1<-list.files("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Enhancer_H3K4me1",pattern=glob2rx("*.txt"))
filePath="/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Enhancer_H3K4me1"
Output<-Aggregate_Correlation(Enhancer_H3K4me1,filePath)
write.table(Output,file="Enhancer_H3K4me1_Corr_Agg.txt",sep="\t"row.names=F , col.names=F)

Enhancer_H3K4me3<-list.files("/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Enhancer_H3K4me3",pattern=glob2rx("*.txt"))
filePath="/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Enhancer_H3K4me3"
Output<-Aggregate_Correlation(Enhancer_H3K4me3,filePath)
write.table(Output,file="Enhancer_H3K4me3_Corr_Agg.txt",sep="\t"row.names=F , col.names=F)

