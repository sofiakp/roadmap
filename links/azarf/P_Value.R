P_Value<-function(filePath){
         
         file<-read.table(filePath)
         vector<-unlist(file)
         SortedVector<-sort(vector, decreasing = FALSE)
         Pvalue<-quantile(SortedVector, c(.01, .05, .10)) 
         return(Pvalue)
}

filePath<-"/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Correlation_Aggregation/Promoter_Enhancer_Corr_Agg.txt"
Output<-P_Value(filePath)
write.table(Output,file="Promoter_Enhancer_Pvalue.txt",sep="\t")


filePath<-"/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Correlation_Aggregation/Promoter_H3K4me1_Corr_Agg.txt"
Output<-P_Value(filePath)
write.table(Output,file="Promoter_H3K4me1_Pvalue.txt",sep="\t")


filePath<-"/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Correlation_Aggregation/Promoter_H3K4me3_Corr_Agg.txt"
Output<-P_Value(filePath)
write.table(Output,file="Promoter_H3K4me3_Pvalue.txt",sep="\t")


filePath<-"/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Correlation_Aggregation/Enhancer_H3K4me1_Corr_Agg.txt"
Output<-P_Value(filePath)
write.table(Output,file="Enhancer_H3K4me1_Pvalue.txt",sep="\t")


filePath<-"/srv/gsfs0/projects/kundaje/users/azarf/roadmap/signal/Permutations/Correlation_Aggregation/Enhancer_H3K4me3_Corr_Agg.txt"
Output<-P_Value(filePath)
write.table(Output,file="Enhancer_H3K4me3_Pvalue.txt",sep="\t")
