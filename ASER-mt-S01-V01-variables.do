
cd "D:\Users\mturaeva\Desktop\ASER2018 Rural Data"
import excel "data/ITAASER2018Child.xlsx", sheet("Ch_HH_VMAP") firstrow clear


*** Renaming variables
ren C010 reading_local
ren C013 reading_eng



*** Labeling

label define reading_local 1 "Beginner/Nothing" 2 "letters" 3 "words" 4 "sentences" 5 "story"
label val reading_local reading_local

label define reading_eng 1 "Beginner/Nothing" 2 "capital Letters" 3 "small letters" 4 "words" 
label val reading_eng reading_eng

label define WINDEX 1 "poorest" 2 "poor" 3 "rich" 4 "richest"
label val WINDEX WINDEX 



*** New var/recoding

gen grade=.
replace grade=0 if C005=="ECE" | C005=="KG" | C005=="Kachi" | C005=="Nursery" | C005=="PG" | C005=="Prep".
replace grade=1 if C005=="1".
replace grade=2 if C005=="2".


