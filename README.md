## Description

`ggqic2` converts a `qicharts2` plot into a `ggplot2` object, with an
option to show it as a `plotly` graphic, it also more clearly visualises
four other special cause rules (Murray and Provost, 2022) than
`qicharts2`. To use, just copy the code from `ggqic2.r`.

## Usage

    ggqic2(qiplot,
        use.plotly = FALSE,
        xlab = "X", ylab = "Y",
        p = FALSE,
        rules = c("outer", "stable", "trend", "shift", "sigma"),
        shift.rule = 8, trend.rule = 6, stable.rule = 15,
        show.nearcentre = TRUE, show.nearcl = TRUE,
        show.u95 = TRUE, show.l95 = TRUE)

## Arguments

`qiplot`

A `qicharts2` object to convert. The function does not yet work with a
faceted plot and likely not with a parted plot.

`use.plotly`

logical; if `TRUE` it will pass the `ggplot2` object through
`ggplotly()` to create an interactive plot.

`xlab`, `ylab`

character string; the titles of the x and y axes and the tooltip text
for `use.plotly`.

`p`

logical; if `TRUE` will add percentages to the y-axis. To be used for a
P Chart.

`rules`

character vector: the special cause rules to use. `"outer"` enables
special cause detection if 2 from 3 points are within the outer range
`(ucl95/lcl95)` of the normal common cause scope. `"stable"` enables
special cause detection if a number of points are detected within the
inner bound of the centre line. `"trend"` enables special cause
detection if a number of consecutive descending or ascending points are
observed. `"shift"` enables special cause detection if a number of
consecutive points are above or below the centre-line. `"sigma"` should
almost always be used and enables special cause detection for points
outside the 3 *σ* common cause range.

`shift.rule`, `trend.rule`, `stable.rule`

integer; determines the number of consecutive points for
`"shift", "trend", "outer"` to be triggered. Defaults based on Murray
and Provost (2022).

`show.nearcentre`, `show.nearcl`

logical; if `TRUE` display dotted and dashed lines that are used to
evalute the `"stable"` and `"outer"` special cause rules respectively.

`show.u95`, `show.l95`

logical; if `FALSE` will hide the upper or lower lines for
`show.nearcl`. Usually only needed for charts with no negative *y*
values, but centre line near 0, or for P charts with centre line near
100%.

## References

Provost, L.P. and Murray, S.K., 2022. *The Health Care Data Guide:
Learning from data for improvement*. John Wiley & Sons.

## Example

    library(qicharts2)
    set.seed(19)
    y <- rnorm(24)
    y[22] <- 4
    plt <- qic(y, chart = 'i')
    ggqic2(plt, use.plotly=TRUE, xlab = "Subgroup", ylab = "Value")

![](ggqic2_files/figure-markdown_strict/example-1.png)
