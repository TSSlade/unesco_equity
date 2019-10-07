# Methodological and other notes

## RISE: Crouch & Rolleston

+ `pure inequality`: difference in outcomes b/w 25th and 75th percentile performers
+ "...Students from disadvantaged backgrounds select into lower quality schools and _benefit less within a school that their more advantaged peers_." (p. 1) <-- What does this suggest re: clustering of our records before conducting our analyses, if anything?
+ "Policies to improve learning among lower performing schools and pupils (the left hand side of the distribution) are required to improve learning equitably and to reduce unfair inequality - _=a route up through the middle_." (p. 1) <-- what do we mean by the italicized?
+ Discussion of the `5-95 spread`: the difference in performance between the 5th and 95th percentile performers.
+ Discussion of $\sigma$ (standard deviation) as relevant unit of comparison.
    * "substantively important" <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\approx&space;\frac{1}{4}&space;\&space;\sigma" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\approx&space;\frac{1}{4}&space;\&space;\sigma" title="\approx \frac{1}{4} \ \sigma" /></a> a.k.a. "effect size" of 0.25
    * "one grade's difference in learning" $\approx \frac{1}{3}-\frac{1}{2} \ \sigma$
    * "rich" and "poor" glossed as $\uparrow 75_{th}$ percentile and $\downarrow 25{th}$ percentile on SES index respectively
+ `cognitive skill poverty`: proportion of children below a given (low) threshold
+ `cardinal measures`: ??

## RISE: Crouch & Gustafsson

+ Under discussion of _IRT-adjusted_ vs _classical_ scoring (pp. 18-19): classical to be preferred for measuring Gini coefficient b/c it has an absolute zero and the construction is a true metric.
+ Significant evidence that growth over time is by reducing the proportion of kids at the low end rather than increasing the proportion of kids at the high end.
+ **Table 4** (p. 31) has a note indicating the coefficients in question apply _pupil weights_ to the analysis. What is the nature of the weighting scheme we need to use for our work?
+ Measures of inequality deployed: (p. 31; see also Fig 13, p. 37)
    * `Theil T` a.k.a. `generalized entropy index with parameter 1.0`
    * `Generalized entropy index with parameter -1.0` <-- Verify sign; text wrapping in paper is ambiguous
    * `Gini coefficient`
    * $frac{90^{th} \text{percentile}}{10^{th} \text{percentile}}$
+ Dangerous to attempt to compare inequality measures for the same country across instruments (e.g., case of Botswana in **Figure 11**.)
+ Trend for a _drop_ in mean performance to be associated with _increased_ (worsening) inequality. (via Theil T)
+ `virtuous efficiency-equity link`: (p. 36) better average performance correlates with greater _equality_. (Freeman et al, 2011) (via Theil T)
+ Via Theil T and multiple regression, _magnitude_ of $\delta$ mean performance is correlated with the change in equality, not the initial level of performance.
+ `Kuznets effect`: ??
+ tl;dr: IRT-based scores prove superior to classical scores for calculating measures of inequality. Appears to be due to greater discrimination in the neighborhood of classical floor effects.
+ Contexts where significant proportions of children attend schools in which not even _one_ child reached the 'intermediate' threshold for reading in TIMSS (475) tend be ones where the fraction of children not even reaching a minimum of 400 on TIMSS. i.e., poorly-managed 
