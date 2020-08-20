library(grid)
library(gridExtra)
library(png)
library(magick)

outPath <- 'D:/Users/ccampton/Dropbox/dukeInternInequalityOutputs/Writing/Main folder/Figures/'
countries <- c("Kenya","Uganda","DRC")
plot_list <- list()
for(i in 1:3){
  country <- countries[i]
  img <- readPNG(paste0(outPath,country,"OwnershipVsSesIndexBaseline.png"))
  plot_list[[i]] <- rasterGrob(img)
}

do.call(grid.arrange,c(plot_list,ncol=1,nrow=3,padding=10))
g <- do.call(arrangeGrob,c(plot_list,ncol=1,nrow=3,padding=10))

ggsave(file=paste0(outPath,"OwnershipVsSesIndexBaseline.pdf"),g,device="pdf", width=24,height=16,units="in",dpi='retina')
