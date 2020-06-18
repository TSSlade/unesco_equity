# Application of analytical tools from economics to education outcomes data

Our goal is to deepen our understanding of the insights which can be gained by borrowing techniques for analyzing inequality of distributions that were developed within the discipline of economics and applying them to learning outcomes in lower- and middle-income countries. Initial proof-of-concept work has already been completed using datasets from Kenya (see [Crouch & Slade 2020](), hereafter CS) and South Asia, Eastern Africa, and Western Africa (see [Punjabi & Ryan 2020](), hereafter PR).

The Stata code used to develop the proof of concept using Kenya data can be found in this GitHub repository: https://github.com/TSSlade/unesco_equity

+ Please provide your GitHub username to Tim Slade (tslade@rti.org, `tsladeRTI` on Skype) to receive an invitation to contribute.
+ If you are unfamiliar with GitHub or the use of similar version-control platforms to collaborate on data analyses Tim can get you up to speed.
+ Please work primarily in Stata, R, or Python.
+ To the extent possible, consider using a [literate programming]() approach (e.g. Stata’s `dyndoc` workflow, R’s `Rmarkdown` workflow, `Jupyter notebooks` for Python) for your outputs, especially any exploratory data analysis.

The core of the Kenya analysis explored the viability of the following approaches to framing inequality using student-level early grade reading (EGR) outcomes:

+ The Gini coefficient and Lorenz curves
+ Ratio of 90th percentile scores to 10th percentile scores
+ Ratio of 75th percentile scores to 25th percentile scores
+ Proportion of zero scores
+ Generalized entropy measures with _alpha_ = 2

**To familiarize yourself with the codebase, the data, and the overall analytical approach, please start by attempting to replicate the findings of CS.**

Once you have done so, there are several areas of inquiry to pursue. The public use-format (“PUF”) datasets can be accessed from [this link](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data) when logged in to the RTI AWS virtual workspace.

1.  The Kenya analysis focused on EGR outcomes using a continuous measure. Do **CS**’ findings regarding the utility and behavior of these economic measures hold when applied to
    1. ...a broader set of countries where EGR outcomes are differently distributed than in Kenya?
        1. Replicate the analysis using heavily right-skewed data, such as
            1. [the Malawi EGRA external evaluation (pending)](TBD)
            2. [Malawi EGRA internal LAT data (pending)](TBD)
            3. [Malawi MERIT](file://///rtifile02/cidprojectshares/09354 EdData II/Task 3 EGRA/Final Databases/_Public Use Data/PUF_3.Malawi2016-2017-2018-MERIT_grade1-2-3_EGRA-SSME_Chichewa.zip)
            4. [DRC PAQUED (Gr 2,4,6 Baseline-Endline)](rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_DRC_Baseline_Endline Grade 2-4-6 French Sample A.zip), [DRC PAQUED IRI Plus](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_DRC_Midline_Endline Grade 2-4 French IRI Plus.zip)
            5. [DRC EdData II](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.DRC2015-4Regions_grade3-5_EGRA-EGMA-SSME_French-Lingala-Tshiluba-Kiswahili.zip)
        1. ...as well as with more-normally distributed data, such as
            1. [the Philippines 4-region dataset](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Philippines2014-2015-4-Regions_grade1-2_EGRA-SSME_Cebuano-Hiligaynon-Ilokano-Maguindanaoan.zip)
            1. [Egypt GILO (2009-2011)](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Egypt2009_2011-GILO_grade2_EGRA_Arabic.zip), [Egypt National 2013](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Egypt2013-National_grade3_EGRA_Arabic.zip), [Egypt National 2014](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Egypt2014-National_grade3_EGRA_Arabic.zip)
    1. ...EGR outcomes recorded using an ordinal measure?
        1. Replicate the analysis using ASER data [from Pakistan](https://www.dropbox.com/s/2pa5ztrnxntqzfh/ASER2018%20Rural%20Data.zip?dl=0). (Other PAL/ASER-type datasets are publicly available [here](https://palnetwork.org/datasets/).)
    1. ...early grade mathematics (EGM) outcomes?
        1. Replicate the analysis using EGM outcomes from
            1. [Kenya PRIMR](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Kenya PRIMR2012-2013-Endline_grade1 2_EGRA EGMA ENG HT T TAC COR COM CIN_Eng Kis.zip)
            1. [Jordan EdData II intervention (2012)](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Jordan2012-National_grade2-3_EGRA-EGMA-SSME_Arabic.zip) and [(2014)](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Jordan2014-National_grade2-3_EGRA-EGMA-TeacherMonitor_Arabic.zip)
            1. [Jordan RAMP](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Jordan-RAMP2017-National_grade2-3_EGRA-EGMA-SSME_Arabic.zip)
            2. [Liberia LTTP2](\\rtifile02\cidprojectshares\09354 EdData II\Task 3 EGRA\Final Databases\_Public Use Data\PUF_3.Liberia LTTP22011-15-Base-Mid-End_grade1-3_EGRA EGMA HT Sch_Eng.zip)
2.  One of the Kenya datasets (the PRIMR clustered RCT intervention) contains both a treatment group and a control group. The behavior of the Gini coefficient and Lorenz curves are very (and unexpectedly) similar across treatment and control groups despite the large effect size of the PRIMR intervention.
    1. In the pattern similar in other contexts where both treatment and control data are available? For this purpose, consider analyzing data from
        1. DRC PAQUED
        2. Malawi EGRA external evaluation
1. Examining the relationship between inequality of learning outcomes and inequality of socio-economic status (SES). In some cases (e.g., Kenya PRIMR) it appears that the wealthy gain more from the intervention than do the poor. (This statement is based on a comparison of difference-in-differences by wealth quintile.) To sort out whether this is a contradiction or not we could do the following with (e.g.) the PRIMR data:
    1. Analyze the changes in reading levels by SES quintile.
        1. **N.B.**: these data were not following the same children longitudinally, so the quintiles have to be created and measured at both baseline and endline.
        1. **N.B.**: If an SES indicator variable already exists, go ahead and use it. Otherwise we may need to create it using principal components analysis.
        1. Describe reading fluency (_oral reading fluency_, or ORF) outcomes by quintile. (If quintiles are too granular, we may want to look at the extremes to get more contrast. In that case, we would do the analysis using bottom/top terciles or quartiles.)
        2. Study and tabulate these contrasts in terms of averages, variances, sums of squared errors, SDs, etc.
    1. For each tercile or quartile extreme, calculate at both baseline and endline, the
        1. total sum of squared errors
        1. the sum of squared errors within and between the two extremes
    1. What do we see? Tabulate that and posit an interpretation.
    1. Does this duality of changing inequality happen in other datasets, too? If so, what seems to be driving it? (We can analyze this together once you have the results.)

There are two additional avenues of inquiry that are a little further afield and thus more experimental or exploratory.

1. Reading is a multifaceted construct. It is often condensed down to “oral reading fluency” or “reading comprehension” for ease of exposition, but there are multiple component skills that are highly correlated with those outcomes. And they are often captured in other subtasks of the EGRA battery: listening comprehension, letter recognition, familiar word recognition, non-word decoding, etc.
    1. Collectively, these subtasks could be used to situate each child in an n-dimensional space that characterizes their reading ability. We could apply techniques from machine learning to explore pupil learning outcomes in this higher-dimensional space.  How do ideas of educational outcome inequality apply given a richer, more multi-dimensional view of children’s reading abilities?
1.  UNICEF now has early grade reading data on something like 15 countries using a simple assessment that is consistent across those countries. These data are nationally-valid random samples that span both the poor and the rich, already come with pre-calculated SES indices done on a similar basis, and have a few other powerful and relatively well-measured correlates such as whether and how much ECD the child received. These data would allow us to explore some of the same poverty-related issues as discussed earlier, rather than simply the “pure inequality” issues related to learning outcomes .
    1. One key feature making this work more exploratory – beyond the SES perspective – is that the UNICEF data essentially generates a binary variable: the child can sort of read vs. the child pretty much can’t read. It is not yet clear whether we can execute the sorts of analyses we would like given that limitation in the data – the task would be to creatively explore it and figure out what can indeed be supported. It may be possible to get a cardinal variable out of it as the granular underlying data would certainly allow it.
    1. But let’s assume that one has to just accept the binary variable of “the child reads” or “does not read”.  In that case we’d be interested in seeing:
        1. The differences between SES quartiles.
        1. Taking only the bottom tercile or quartile and the top, then calculate the total variance or sum of squared errors here and well as the variance or sum of squared errors within and between those extreme quartiles.
        1. For all countries in the dataset if possible.
        1. As before, let’s just tabulate and then see what conclusions we can come to.
