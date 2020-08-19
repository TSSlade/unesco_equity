library(grid)
library(gridExtra)
library(png)
library(magick)

pngPath <- 'D:/Users/ccampton/Dropbox/dukeInternInequalityOutputs/Writing/Main folder/Figures/ORFphasechange_files/'
countries <- c("Malawi","Kenya","DRC")
grades <- c(1,2,6)
plot_list <- list()
for(i in 1:3){
  country <- countries[i]
  g <- grades[i]
  den <- readPNG(paste0(pngPath,country,"Gr",g,"Density.png"))
  plot_list[[2*(i-1)+1]] <- rasterGrob(den)
  pct <- readPNG(paste0(pngPath,country,"Gr",g,"Percentiles.png"))
  plot_list[[2*i]] <- rasterGrob(pct)
}

do.call(grid.arrange,c(plot_list,ncol=2,nrow=3,padding=10))
g <- do.call(arrangeGrob,c(plot_list,ncol=2,nrow=3,padding=10))

ggsave(file=paste0(pngPath,"joinedORFphasechange.pdf"),g,device="pdf", width=24,height=16,units="in",dpi='retina')