library(ggplot2)
library(reshape2)
library(RColorBrewer)
library(gplots)

print("Libraries loaded")
d = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Dyadic_H3K4me1.txt"))
d2 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Dyadic_H3K4me3.txt"))
print("Data Loaded")

#Find the max value of every column in d, then divide that column by the maximum value. Use a for loop though the columns then interate up though the rows. DO this for the non corr files. 
AbsMax <- 0
Tmax <- 0
normalizeMatrix <- function(x)
{
  for(i in 1:ncol(x)){
    Tmax <- max(x[,i])
    x[,i] = x[,i] / Tmax
  }
  return(x)
}

doHeatmapRender <- function(m, name)
{
  png(name.png,width=4000,height=4000, res=120)
  heatmap.2(d,col=topo.colors,dendrogram="both", hclustfun=function(x)hclust(x,method="ward.D2"),notecol="black",scale="none",key=TRUE, symkey=TRUE,breaks=seq,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster", main=name)
  dev.off()
}

d <- normalizeMatrix(d)
d2 <- normalizeMatrix(d2)
dTemp <- d - d2
seq <- seq(0,1,by=0.05)
print(seq)

myplot <- heatmap.2(dTemp,col=topo.colors,dendrogram="both", hclustfun=function(x)hclust(x,method="ward.D2"), notecol="black",scale="none",breaks=seq, key=TRUE, symkey=FALSE,keysize=1.5, density.info="none", trace="none", cexRow=0.7,cexCol=1.2, xlab="Signal",ylab="Cluster", main="Dyadic_Difference_Map")
