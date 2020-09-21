
cd "D:\Users\mturaeva\Desktop\ASER2018 Rural Data"
import excel "data/ITAASER2018Child.xlsx", sheet("Ch_HH_VMAP") firstrow clear



ineqord reading_local, ustatusvar(CFul) dstatusvar(CFdl) catvals(distinct_values) catprops(cat_prop) catsprops(cum_prop) gldvar(LorCFdl) gluvar(LorCFul)

/*
      alpha(#)             calculate additional Cowell-Flachaire index with parameter #
      nlevels(#)           specify total number of levels of response varname: see below
      minlevel(#)          specify minimum level of response varname: see below
      ustatusvar(string)   save Cowell-Flachaire upward-looking status variable after calculation
      dstatusvar(string)   save Cowell-Flachaire downward-looking status variable after calculation
      catvals(string)      save distinct values of the response in a new variable
      catprops(string)     save sample category proportions in a new variable
      catcprops(string)    save sample cumulative proportions in a new variable
      catsprops(string)    save sample cumulative survivor proportions in a new variable
      gldvar(string)       save Generalized Lorenz ordinates for Cowell-Flachaire downward-looking status in a new variable
      gluvar(string)       save Generalized Lorenz ordinates for Cowell-Flachaire upward-looking status in a new variable
      hplus(string)        save H+ ordinates in a new variable
      hminus(string)       save H- ordinates in a new variable

*/



lorenz estimate CFul, over(WINDEX) gini t graph(aspectratio(1) noci legend(order(1 "equality line" 2 "Lorenz curve")) ytitle(Cumulative proportion of CFul status ) )
graph save "bins/ASER-mt-S01-V01-lrz_CFul", replace
graph export "bins/ASER-mt-S01-V01-lrz_CFul.png",replace

lorenz estimate CFdl, over(WINDEX) gini t graph(aspectratio(1) noci legend(order(1 "equality line" 2 "Lorenz curve")) ytitle(Cumulative proportion of CFdl status ) )
graph save "bins/ASER-mt-S01-V01-lrz_CFdl", replace
graph export "bins/ASER-mt-S01-V01-lrz_CFdl.png",replace



drop if WINDEX==.
sort WINDEX reading_local
by WINDEX (reading_local): ineqord reading_local

