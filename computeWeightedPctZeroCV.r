
library(haven)
library(DescTools)
library(tidyverse)
library("xlsx")
library(Weighted.Desc.Stat)
library(reldist)

# Two data types, PUF and final. Find the 'best' dataset for each file; if there is a `final' version, use that instead.
path = "C:/Users/Cole/Documents/unesco_equity/data"
fileListingPUF <- list.files(path ,recursive=TRUE,pattern= "^PUF.*.dta$",full.names=TRUE)
fileListingFinal <- list.files(path ,recursive=TRUE,pattern= "^4.*.dta$",full.names=TRUE)
mask = unlist(lapply(fileListingPUF, function(x) dirname(x) %in% dirname(fileListingFinal)))
fileListingPUF <- fileListingPUF[!mask]
fileListing <- c(fileListingPUF, fileListingFinal)
# These Strings are searched for as sub-strings in filenames to label the results. 
countryNames <- c("Malawi", "DRC","Philippines","Egypt","KenyaTusome","Kenya PRIMR","Uganda")
# This is hierarchial list to define the orf variable when "orf" is not available.
orfnames <- c("orf","mt_orf","ph_orf","e_orf_a","k_orf","r_orf")
# List of factors to consider
out <- data.frame(matrix(nrow=0,ncol=12))
weightNames <- c("wt_final","wt_stage3","wt_stage2")
for(i in 1:length(fileListing)){
  data <- read_dta(fileListing[i])
  country <- stringr::str_extract(basename(fileListing[i]) ,paste(countryNames,collapse="|"))
  # Defines treat_phase as either included, year, or month based on hierarchy
  if (!"treat_phase"%in% colnames(data)){
    if ("year"%in% colnames(data)){
      if(length(unique(data$year))>1){
        data$treat_phase <- data$year
      }else{
        data$treat_phase <- data$month
      }
    }
  }
  # Use school_id
  if (! "school_id" %in% colnames(data)){
    data$school_id <- data$school_code
  }
  # Language defined
  if(!"language"%in% colnames(data)){
    data$language <- rep("Unspecified",nrow(data))
  }else if(is.numeric(data$language)){
    languageLabels <- attributes(data$language)$labels
    if(country=="Uganda"){languageLabels["English"] =1}
    if(all(unique(data$language) %in% languageLabels)){
      data$language <- unlist(lapply(data$language,function(x) names(languageLabels[languageLabels==x])))
    }
  }
  if(!"treatment" %in% colnames(data)){
    data$treatment <- rep(0, nrow(data))
    includeTreat <- FALSE
  }else if(length(unique(data$treatment))==1){
    includeTreat <- FALSE
  }else{
    includeTreat <- TRUE
  }
  # Convert each of the factors into factors
  data$grade <- as.factor(data$grade)
  data$treat_phase <- as.factor(data$treat_phase)
  data$school_id <- as.factor(data$school_id)
  #data$language <- as.factor(data$language)
  cat(paste0("Analysis of variance for ",country,"\n"))
  orfnamesMask <- orfnames %in% colnames(data)
  for(l in which(orfnamesMask==1)){
    cat(paste0("Oral fluency measure: ",orfnames[l]),"\n")
    if(orfnames[l]=="r_orf"){
      #dataSub <- na.omit(data[,c(orfnames[l], "school_id","treat_phase","grade","r_language","treatment")])
      dataSub <- data[!is.na(data[,orfnames[l]]),]
      rorfLabels <- attributes(dataSub$r_language)$labels
      if(all(unique(dataSub$r_language) %in% rorfLabels)){
        dataSub$language <- unlist(lapply(dataSub$r_language,function(x) names(rorfLabels[rorfLabels==x])))
      }else{
        dataSub$language <- dataSub$r_language
      }
    }else{
      #dataSub <- na.omit(data[,c(orfnames[l], factorList)])
      dataSub <- data[!is.na(data[,orfnames[l]]),]
      orfLabels <- attributes(dataSub$language)$labels
      if(all(unique(dataSub$language) %in% orfLabels)){
        dataSub$language <- unlist(lapply(dataSub$language,function(x) names(orfLabels[orfLabels==x])))
      }
    }
    langs <- unlist(unique(dataSub[,"language"]))
    grades <- sort(unlist(unique(dataSub[,"grade"])))
    for(lang in langs){
      for(g in grades){
        phases <- sort(unlist(unique(dataSub[dataSub$grade==g,"treat_phase"])))
        treatgroups <- sort(unlist(unique(dataSub[dataSub$grade==g,"treatment"])))
        for(p in phases){
          # for( t in treatgroups){
          #   if(includeTreat){
          #     countryGroup <- paste0(country,", Treat Group ",t)
          #   }else{
          #     countryGroup <- country
          #   }
            gpdata <-  dataSub[dataSub$grade == g & dataSub$treat_phase ==p & dataSub$language ==lang, ]# & dataSub$treatment==t,]
            gpdata <- gpdata[!is.na(orfnames[l]),]
            if(nrow(gpdata)>0){
            wttypes <- weightNames %in% colnames(gpdata)
            if(sum(wttypes)>0){
              weightType <- weightNames[which(wttypes)[1]]
              gpWeight <- unlist(gpdata[, weightType])
              gpWeight <- gpWeight
            }else{
              gpWeight <-  rep(1, nrow(gpdata))
              weightType <- "Uniform"
            }
            wmu <- w.mean(gpdata[,orfnames[l]],gpWeight)
            wpctzero <- w.mean(gpdata[,orfnames[l]]==0,gpWeight)
            wcv <- w.cv(gpdata[,orfnames[l]],gpWeight)
            p90p10 <- wtd.quantile(unlist(gpdata[,orfnames[l]]),q=.9,weight=gpWeight)/wtd.quantile(unlist(gpdata[,orfnames[l]]),q=.1,weight=gpWeight)
            p75p25 <- wtd.quantile(unlist(gpdata[,orfnames[l]]),q=.75,weight=gpWeight)/wtd.quantile(unlist(gpdata[,orfnames[l]]),q=.25,weight=gpWeight)
            wgini <- gini(unlist(gpdata[,orfnames[l]]),weight=gpWeight)
            
            row <- c(country, weightType,orfnames[l], lang, g, p, wgini, wcv,p90p10,p75p25, wpctzero, wmu)
            out <- rbind(out,row)
          #  }
          }
        }
      }
    }
  }
}
colnames(out) <- c("Country", "Weight Type","Measure", "Language", "Grade","Phase","Gini", "CV" ,"p90/p10","p75/p25", "Pct Zero", "Mean")
xlsxpath = "C:/Users/Cole/Documents/unesco_equity_outputs/"
write.xlsx(x = out, file = paste0(xlsxpath,"PctZeroCVWeighted.xlsx"),sheetName = "Weighted", row.names = FALSE, col.names=TRUE)
out$Language <- paste(out$Measure,out$Language)
out <- out[,setdiff(colnames(out),"Measure")]
mostPhases = 5
table = data.frame(matrix(ncol = mostPhases*6+4,nrow=0))
countries <- unique(out[,"Country"])
for(c in countries){
  cdata <- rbind(out[out[,"Country"]==c,],data.frame(matrix(nrow=0,ncol=ncol(out))))
  colnames(cdata) <- colnames(out)
  clangs <- unique(cdata[,"Language"])
  for(l in clangs){
    ldata <- rbind(cdata[cdata[,"Language"]==l,],data.frame(matrix(nrow=0,ncol=ncol(out))))
    colnames(ldata) <- colnames(out)
    ldata <- ldata[order(as.numeric(ldata[,"Grade"])),]
    grades <-  as.numeric(unique(ldata[,"Grade"]))
    for(g in grades){
      gdata <- rbind(ldata[ldata[,"Grade"]==g,],data.frame(matrix(nrow=0,ncol=ncol(out))))
      colnames(gdata) <- colnames(out)
      phaseOrder <- order(as.numeric(gdata[,"Phase"]))
      clgdata <- reshape(gdata[phaseOrder,], idvar=c("Country", "Weight Type", "Language", "Grade"), timevar = "Phase", direction="wide")
      clgdata <- cbind(clgdata, matrix(NA,nrow=1,ncol=6*(mostPhases-nrow(gdata))))
      colnames(clgdata) <- colnames(table)
      table <- rbind(table,clgdata)
    }
  }
}
colnames(table) <- c("Country","Weight Type", "Language", "Grade",paste0(c("Gini", "CV" ,"p90/p10","p75/p25", "Pct Zero", "Mean"),", Phase ",rep(t(1:mostPhases),each=6)))
table <- table[,colSums(is.na(table))!=nrow(table)]
print(table,row.names=FALSE)
write.xlsx(x = table, file = paste0(xlsxpath,"PctZeroCVWeightedPhases.xlsx"),sheetName = "Weighted", row.names = FALSE, col.names=TRUE)
