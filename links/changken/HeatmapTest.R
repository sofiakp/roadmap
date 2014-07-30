library(ggplot2)
library(reshape2)
library(RColorBrewer)

print("Libraries loaded")
d = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Promoter_Enhancer_Corr.txt"))
d2 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Enhancer_Dyadics_H3k4me1_Corr.txt"))
d3 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Enhancer_Dyadics_H3k4me3_Corr.txt"))
d4 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Promoters_Dyadics_H3k4me1_Corr.txt"))
d5 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Promoters_Dyadics_H3k4me3_Corr.txt"))
print("Data Loaded")



#myplot5 <- heatmap.2(d,col=topo.colors,dendrogram="both", hclustfun=function(x)hclust(x,method="ward.D2"),notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster", main="Dyadic_H3K4me1")
myplot5 <- heatmap.2(d,col=topo.colors,dendrogram="both", hclustfun=function(d)hclust(d,method="ward.D2"), notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster", main="Promoter_Enhancer_Corr")
myplot <- heatmap.2(d2,col=topo.colors,dendrogram="both", hclustfun=function(d)hclust(d,method="ward.D2"), notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster", main="Enhancer_Dyadics_H3k4me1_Corr")
myplot2 <- heatmap.2(d3,col=topo.colors,dendrogram="both", hclustfun=function(d)hclust(d,method="ward.D2"), notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster",main="Enhancer_Dyadics_H3k4me3_Corr")
myplot3 <- heatmap.2(d4,col=topo.colors,dendrogram="both", hclustfun=function(d)hclust(d,method="ward.D2"), notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster",main="Promoters_Dyadics_H3k4me1_Corr.txt")
myplot4 <- heatmap.2(d5,col=topo.colors,dendrogram="both", hclustfun=function(d)hclust(d,method="ward.D2"), notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster",main="Promoters_Dyadics_H3k4me3_Corr.txt")
#ggsave(myplot, file="/Users/Seioch/Documents/Stanford/AvgSignals/test.png", dpi = 800)
