library("xlsx")
librart(openxlsx)
path = "D:/Users/ccampton/Dropbox/dukeInternInequalityOutputs/Cole/SEStables/"
ntiles = c(2,3,4)
out <- createWorkbook()
for(ns in 1:length(ntiles)){
  ntile = ntiles[ns]
  fileListing <- list.files(path,recursive=TRUE,pattern= paste0("*",ntile,"-percentiles.xlsx"),full.names=TRUE)
  for (i in 1:length(fileListing)){
    df <- read.xlsx(fileListing[i],sheetName=paste0(ntile,"-percentiles"))
    dfbn <- basename(fileListing[i])
    df <- rbind(c(substr(dfbn,1,nchar(dfbn)-18),rep("",ncol(df)-1)),df)
    if(i==1){
      D <- df
    }else{
      D <- cbind(D,df)
    }
  }
  addWorksheet(out,paste0(ntile,"-percentiles"))
  writeData(out, sheet= paste0(ntile,"-percentiles"), x= D)
}
saveWorkbook(out,paste0(path,"SES_joined.xlsx"))