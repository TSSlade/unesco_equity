# Analysis To-Do list for UNESCO chapter

## Calculations/Derivations
Ensuring that survey weights are appropriately applied, calculate for each subpopulation:

1. Fluency
    + Entropy class inequality estimators
    + Gini coefficient
    + Coefficient of variation (a.k.a. relative SD)<sup>[1](#coefficientOfVariation)</sup>
    + % below/above certain cut-points
    + Mean fluency
1. Zero-scores
    + % of zero-scores

## Analyses
Using the statistics generated above, explore the following questions:

1. How does the magnitude of the measure vary
    + Over time (assesment phases) within treatment groups (e.g., Tusome Gr 1 at `Baseline` and `Midline`: consider clustered column graph)
    + Between treatment groups at the same assessment phase (e.g., PRIMR Gr 1 Tx vs. Control at `Midline`: consider clustered column graph)
    + Across datasets (e.g., Tusome vs. PRIMR: consider small-multiples of scatterplots)

## Subpopulations of interest
There are different sub_pops we care about based on the various datasets. At a minimum, though, we want to be sure we're breaking up our analyses by

1. Grade
1. Treatment phase (baseline, midline, endline)
1. Treatment status (tx, control)

While not a sub_pop, note that we need to treat _language_ distinctly as well.

## _Tusome_ data
The features of the _Tusome_ data are as follows:

+ T. Phase: Baseline, Midline
+ Grades: 1, 2
+ T. Status: N/A

Therefore our subpopulations are:

|            SubPop            | T. Phase | Grade | T. Status |
|------------------------------|----------|-------|-----------|
| <p style="color: blue">1</p> | Baseline |     1 | N/A       |
| <p style="color: blue">2</p> | Baseline |     2 | N/A       |
| <p style="color: blue">3</p> | Midline  |     1 | N/A       |
| <p style="color: blue">4</p> | Midline  |     2 | N/A       |

+ Languages: English, Kiswahili

## _PRIMR_ data
The features of the PRIMR data are as follows:

+ T. Phase: Baseline, Midline A, Endline
+ Cohort: 1, 2, 3
+ T. Status: Treatment, Control
+ Grades: 1, 2

**Cohort 1** was the first group of schools to receive the intervention, and they received it throughout the lifetime of the project. The intervention began after the baseline assessment, therefore all **Cohort 1** schools have the status of "Control" at `Baseline`. **Cohort 1** schools all have the status of _Treatment_ at `Midline` and again at `Endline`.

**Cohort 2** was the second group of schools to receive the intervention. Their intervention began after the `Midline` assessment, therefore all **Cohort 2** schools have the status of _Control_ at both `Baseline` and `Midline`. **Cohort 2** schools all have the status of _Treatment_ at `Endline`.

**Cohort 3** schools never received the intervention. Therefore all **Cohort 3** schools have the status of _Control_ at `Baseline`, `Midline`, and `Endline`.

The design is as indicated below. Superscripted numbers indicate the subpopulation groups; there are 2 groups per cell because of grades 1 and 2.

| Cohort |                  Baseline                 |  Intervention Pd 1  |                   Midline                   |  Intervention Pd 2  |                   Endline                    |
|--------|-------------------------------------------|---------------------|---------------------------------------------|---------------------|----------------------------------------------|
|      1 | Control <sup style="color:red">1, 2</sup> | Intervention Active | Tx      <sup style="color:blue">7, 8</sup>  | Intervention Active | Tx      <sup style="color:blue">13, 14</sup> |
|      2 | Control <sup style="color:red">3, 4</sup> | [none]              | Control <sup style="color:red">9, 10</sup>  | Intervention Active | Tx      <sup style="color:blue">15, 16</sup> |
|      3 | Control <sup style="color:red">5, 6</sup> | [none]              | Control <sup style="color:red">11, 12</sup> | [none]              | Control <sup style="color:red">17, 18</sup>  |
|        |                                           |                     |                                             |                     |                                              |

Reshaped to match Stata output:

|             SubPop             | T.Phase  | Cohort |  T.Status | Grade | Notes |
|--------------------------------|----------|--------|-----------|-------|-------|
| <p style="color:red"> 1 </p>   | Baseline |      1 | Control   |     1 |       |
| <p style="color:red"> 2 </p>   | Baseline |      1 | Control   |     2 |       |
| <p style="color:red"> 3 </p>   | Baseline |      2 | Control   |     1 |       |
| <p style="color:red"> 4 </p>   | Baseline |      2 | Control   |     2 |       |
| <p style="color:red"> 5 </p>   | Baseline |      3 | Control   |     1 |       |
| <p style="color:red"> 6 </p>   | Baseline |      3 | Control   |     2 |       |
| <p style="color:blue"> 7 </p>  | Midline  |      1 | Treatment |     1 |       |
| <p style="color:blue"> 8 </p>  | Midline  |      1 | Treatment |     2 |       |
| <p style="color:red"> 9 </p>   | Midline  |      2 | Control   |     1 |       |
| <p style="color:red"> 10 </p>  | Midline  |      2 | Control   |     2 |       |
| <p style="color:red"> 11 </p>  | Midline  |      3 | Control   |     1 |       |
| <p style="color:red"> 12 </p>  | Midline  |      3 | Control   |     2 |       |
| <p style="color:blue"> 13 </p> | Endline  |      1 | Treatment |     1 |       |
| <p style="color:blue"> 14 </p> | Endline  |      1 | Treatment |     2 |       |
| <p style="color:blue"> 15 </p> | Endline  |      2 | Treatment |     1 |       |
| <p style="color:blue"> 16 </p> | Endline  |      2 | Treatment |     2 |       |
| <p style="color:red"> 17 </p>  | Endline  |      3 | Control   |     1 |       |
| <p style="color:red"> 18 </p>  | Endline  |      3 | Control   |     2 |       |

# Checklist
Progress to date on calculating and exporting the necessary data:

<table>
    <tr><td>Project</td><td colspan=4 align="center">Tusome</td><td colspan=18 align="center">PRIMR</td></tr>
    <tr><td>Subpopulation</td><td style="color:blue">1</td><td style="color:blue">2</td><td style="color:blue">3</td><td style="color:blue">4</td><td style="color:red">1</td><td style="color:red">2</td><td style="color:red">3</td><td style="color:red">4</td><td style="color:red">5</td><td style="color:red">6</td><td style="color:blue">7</td><td style="color:blue">8</td><td style="color:red">9</td><td style="color:red">10</td><td style="color:red">11</td><td style="color:red">12</td><td style="color:blue">13</td><td style="color:blue">14</td><td style="color:blue">15</td><td style="color:blue">16</td><td style="color:red">17</td><td style="color:red">18</td></tr>
    <tr><td>Measure</td><td colspan=0></tr>
    <tr><td>Entropy Class Inequality Estimators</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
    <tr><td>Gini Coefficient</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
    <tr><td>Coefficient of Variation</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
    <tr><td>% below/above cut-point</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
    <tr><td>Mean fluency</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
    <tr><td>% of zero-scores</td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td><td><input type="checkbox" /></td></tr>
</table>

### Notes
<a name="coefficientOfVariation">1</a>: N.B., per [Wikipedia](https://en.wikipedia.org/wiki/Coefficient_of_variation): only for use on data with a ratio scale. On an interval scale it is meaningless. Therefore usable for cwpm, but not usable for (e.g.) Uwezo-type data (which is categorical).
> As a measure of economic inequality  
The coefficient of variation fulfills the requirements for a measure of economic inequality.[18][19][20] If x (with entries xi) is a list of the values of an economic indicator (e.g. wealth), with xi being the wealth of agent i, then the following requirements are met:
+ Anonymity – cv is independent of the ordering of the list x. This follows from the fact that the variance and mean are independent of the ordering of x.
+ Scale invariance: cv(x)=cv(αx) where α is a real number.
+ Population independence – If {x,x} is the list x appended to itself, then cv({x,x})=cv(x). This follows from the fact that the variance and mean both obey this principle.
+ Pigou-Dalton transfer principle: when wealth is transferred from a wealthier agent i to a poorer agent j (i.e. xi > xj) without altering their rank, then cv decreases and vice versa.
cv assumes its minimum value of zero for complete equality (all xi are equal). Its most notable drawback is that it is not bounded from above, so it cannot be normalized to be within a fixed range (e.g. like the Gini coefficient which is constrained to be between 0 and 1). It is, however, more mathematically tractable than the Gini Coefficient.
