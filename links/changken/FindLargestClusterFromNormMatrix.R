d = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Dyadic_H3K4me1.txt"))
d2 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Dyadic_H3K4me3.txt"))
d3 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Enhancer.txt"))
d4 = as.matrix(read.table("/Users/Seioch/Documents/Stanford/AvgSignals/Promoter.txt"))

print("Data Loaded")

#Find the max value of every column in d, then divide that column by the maximum value. Use a for loop though the columns then interate up though the rows. DO this for the non corr files. 
normalizeMatrix <- function(x)
{
  for(i in 1:ncol(x)){
    Tmax <- max(x[,i])
    x[,i] = x[,i] / Tmax
  }
  return(x)
}

d1 <- normalizeMatrix(d)
d2 <- normalizeMatrix(d2)
d3 <- normalizeMatrix(d3)
d4 <- normalizeMatrix(d4)

AbsMax <- 0
Tmax <- 0
#print(paste("New AbsMax: ",AbsMax, sep=" "))

doHighValCalc <- function(x, name)
{
  sink(paste("Analysis", name, sep="_"))
  for(i in 1:ncol(x)){
    Tmax <- max(x[,i])
    #Do file print here
    cat(paste("Largest number for cluster ",i," : ", Tmax ,"\n"))
  }
  #return(AbsMax)
  sink()
}

doHighValCalc(d,"Dyadic_H3k4me1.txt")
doHighValCalc(d2,"Dyadic_H3k4me3.txt")
doHighValCalc(d3,"Enhancer.txt")
doHighValCalc(d4,"Promoter.txt")
#print(AbsMax)

