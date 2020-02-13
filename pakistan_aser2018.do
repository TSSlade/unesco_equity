import excel "C:\Dropbox\BerkeleyMIDS\projects\unesco_chapter\data\aser\ASER2018 Rural Data\ITAASER2018Child.xlsx", firstrow clear

ren C010 local_reading_score
ren C013 eng_reading_score
ren C012 arithmetic_score


// "For downward-looking status inequality is higher when the distribution is skewed 
// towards the higher categories (Case 0); for upward-looking status inequality is 
// higher when the distribution is skewed towards the lower categories (Case 3)." (Cowell-Flachaire 2014, p. 22)

*djinn'seyeballs