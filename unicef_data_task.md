# Exploratory UNICEF data task

UNICEF now has early grade reading data on something like 15 countries using a simple assessment that is consistent across those countries. These data are nationally-valid random samples that span both the poor and the rich, already come with pre-calculated SES indices done on a similar basis, and have a few other powerful and relatively well-measured correlates such as whether and how much ECD the child received. These data would allow us to explore some of the same poverty-related issues as discussed earlier, rather than simply the “pure inequality” issues related to learning outcomes.

1. One key feature making this work more exploratory – beyond the SES perspective – is that the UNICEF data essentially generates a binary variable: the child can sort of read vs. the child pretty much can’t read. It is not yet clear whether we can execute the sorts of analyses we would like given that limitation in the data – the task would be to creatively explore it and figure out what can indeed be supported. It may be possible to get a cardinal variable out of it as the granular underlying data would certainly allow it.
2. But let’s assume that one has to just accept the binary variable of “the child reads” or “does not read”.  In that case we’d be interested in seeing:
    1. The differences between SES quartiles.
    2. Taking only the bottom tercile or quartile and the top, then calculate the total variance or sum of squared errors here and well as the variance or sum of squared errors within and between those extreme quartiles.
    3. For all countries in the dataset if possible.
    4. As before, let’s just tabulate and then see what conclusions we can come to.
