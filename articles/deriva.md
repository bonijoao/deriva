# Getting Started with deriva

``` r

library(deriva)
```

## What is concept drift?

A machine learning model trained on historical data operates under the
implicit assumption that the data-generating process remains stable over
time. When this assumption breaks down — because user behaviour shifts,
sensor calibration drifts, or the world simply changes — the model’s
predictions degrade without any obvious error being raised. This
phenomenon is called **concept drift**.

Monitoring for drift requires a *drift detector*: an algorithm that
reads a stream of per-observation signals (typically prediction errors)
and raises a flag when the signal’s distribution has changed
significantly. The `deriva` package provides a tidy interface to a
catalogue of 22 such detectors, designed to compose naturally with the
tidymodels ecosystem.

## The running example: a credit-approval model

This vignette works through `credit_monitoring`, a dataset shipped with
the package: the per-observation error stream of a credit-approval
classifier in production.

``` r

head(credit_monitoring)
#>   t error drift_true
#> 1 1     0      FALSE
#> 2 2     0      FALSE
#> 3 3     0      FALSE
#> 4 4     0      FALSE
#> 5 5     0      FALSE
#> 6 6     0      FALSE
```

For its first 500 observations the model runs at its expected 5% error
rate. After observation 500, a shift in the credit market raises the
error rate to 30% — `drift_true` records this ground truth, which a real
deployment would not have access to (`deriva`’s job is to infer it from
`error` alone).

## Quick start

The one-shot shortcut
[`detect_drift()`](https://bonijoao.github.io/deriva/reference/detect_drift.md)
runs a detector over an existing column and returns the data annotated
with `.warning` and `.drift` flags.

``` r

result <- detect_drift(credit_monitoring, .col = error, method = "ddm")

# Where was drift flagged?
subset(result, .drift)
#> # A tibble: 1 × 5
#>       t error drift_true .warning .drift
#>   <int> <int> <lgl>      <lgl>    <lgl> 
#> 1   542     1 TRUE       FALSE    TRUE
```

The detector correctly identifies the distributional change shortly
after the known drift point (observation 500), with no false drift
detections in the 500 stable observations before it.

## The deriva interface

`deriva` follows the same three-verb pattern as tidymodels: **specify →
fit → advance**.

### 1. Specify a detector

[`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md)
creates an inert specification — no computation happens here.

``` r

spec <- drift_detector("ddm", min_instances = 30)
spec
#> Drift Detector Specification (ddm)
#>   min_instances: 30
#>   warning_level: 2
#>   out_control_level: 3
#>   keep: 10000
```

Pass method hyperparameters as named arguments. Unknown parameters, and
values outside a parameter’s valid range, raise an informative error.

### 2. Fit on a baseline

[`fit()`](https://generics.r-lib.org/reference/fit.html) runs the
detector over the **baseline period** — the stable window against which
future observations are compared. Here, that is the first 500
observations, before the market shift.

``` r

baseline <- credit_monitoring[credit_monitoring$t <= 500, ]

fitted <- fit(spec, baseline, signal = error)
fitted
#> Fitted Drift Detector (ddm)
#>   observations: 500 (500 baseline)
#>   warnings: 6 | drifts: 0
```

The fitted object is **immutable**: it stores the internal engine state
after processing the baseline, ready to receive new data.

### 3. Advance over new batches

[`advance()`](https://bonijoao.github.io/deriva/reference/advance.md)
feeds a new batch to the detector and returns a **new** fitted object
with the state updated and the annotated batch appended to the history.
The original object is not modified.

``` r

batch1 <- credit_monitoring[credit_monitoring$t >= 501 & credit_monitoring$t <= 700, ]
batch2 <- credit_monitoring[credit_monitoring$t >= 701, ]

fitted2 <- advance(fitted,  batch1)
fitted3 <- advance(fitted2, batch2)
fitted3
#> Fitted Drift Detector (ddm)
#>   observations: 1000 (500 baseline)
#>   warnings: 24 | drifts: 1
```

Batches can be any size — including a single observation for true
streaming use. The market shift (observation 501) falls inside `batch1`;
`deriva` flags it there, and `batch2` confirms the model has settled
into its new, worse error rate with no further alarms.

### 4. Inspect results

**[`augment()`](https://generics.r-lib.org/reference/augment.html)**
returns the retained history as a tibble (the last `keep` rows of the
fitted object — see
[`?drift_detector`](https://bonijoao.github.io/deriva/reference/drift_detector.md)).

``` r

history <- augment(fitted3)
tail(history[, c("t", "error", ".phase", ".warning", ".drift")], 10)
#> # A tibble: 10 × 5
#>        t error .phase .warning .drift
#>    <int> <int> <chr>  <lgl>    <lgl> 
#>  1   991     0 stream FALSE    FALSE 
#>  2   992     1 stream FALSE    FALSE 
#>  3   993     0 stream FALSE    FALSE 
#>  4   994     0 stream FALSE    FALSE 
#>  5   995     0 stream FALSE    FALSE 
#>  6   996     0 stream FALSE    FALSE 
#>  7   997     0 stream FALSE    FALSE 
#>  8   998     1 stream FALSE    FALSE 
#>  9   999     0 stream FALSE    FALSE 
#> 10  1000     0 stream FALSE    FALSE
```

**[`tidy()`](https://generics.r-lib.org/reference/tidy.html)** extracts
the detected drift points.

``` r

tidy(fitted3)
#> # A tibble: 1 × 2
#>   index phase 
#>   <int> <chr> 
#> 1   542 stream
```

**[`glance()`](https://generics.r-lib.org/reference/glance.html)** gives
a one-row summary.

``` r

glance(fitted3)
#> # A tibble: 1 × 5
#>   method n_obs n_warning n_drift first_drift
#>   <chr>  <int>     <int>   <int>       <int>
#> 1 ddm     1000        24       1         542
```

**[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)**
plots the running mean of the signal with warning (orange) and drift
(red) markers, and a dotted line separating baseline from stream.

``` r

library(ggplot2)
autoplot(fitted3)
```

![](deriva_files/figure-html/autoplot-1.png)

## Bridging from tidymodels

In a real workflow, the signal column comes from model predictions, not
a shipped dataset.
[`add_prediction_error()`](https://bonijoao.github.io/deriva/reference/add_prediction_error.md)
converts the output of tidymodels’
[`augment()`](https://generics.r-lib.org/reference/augment.html) (which
contains truth and estimate columns) into a `.error` column that drift
detectors can consume.

``` r

# Simulate tidymodels augment() output for a classifier
predictions <- data.frame(
  time     = 1:8,
  truth    = factor(c("yes","no","yes","yes","no","yes","no","yes")),
  .pred_class = factor(c("yes","no","yes","no" ,"no","no" ,"no","yes"))
)

add_prediction_error(predictions, truth = truth)
#> # A tibble: 8 × 4
#>    time truth .pred_class .error
#>   <int> <fct> <fct>        <int>
#> 1     1 yes   yes              0
#> 2     2 no    no               0
#> 3     3 yes   yes              0
#> 4     4 yes   no               1
#> 5     5 no    no               0
#> 6     6 yes   no               1
#> 7     7 no    no               0
#> 8     8 yes   yes              0
```

For regression problems, `.error` is the absolute prediction error; for
classification it is a 0/1 mismatch indicator. Chaining straight into
[`fit()`](https://generics.r-lib.org/reference/fit.html) needs care:
[`fit()`](https://generics.r-lib.org/reference/fit.html)’s first
argument is the *spec*, not the data, so build the annotated data first
and pass the spec and data to
[`fit()`](https://generics.r-lib.org/reference/fit.html) explicitly:

``` r

monitoring_data <- model |>
  augment(new_data = production_data) |>
  add_prediction_error(truth = y)

fit(drift_detector("page_hinkley"), monitoring_data, signal = .error)
```

## Distribution-based detectors

Some detectors monitor the distribution of a numeric stream directly,
without requiring labelled errors — see
[`vignette("distribution-detectors")`](https://bonijoao.github.io/deriva/articles/distribution-detectors.md)
for a worked example with `"kswin"`.

## Available methods

`deriva` ships with 22 drift detectors across two signal types.

| Signal type | Methods |
|----|----|
| `"error"` (0/1 errors) | `ddm`, `eddm`, `hddm_a`, `hddm_w`, `ewma`, `rddm`, `stepd`, `fhddm`, `fhddms`, `mddm_a`, `mddm_e`, `mddm_g`, `wstd`, `ftdd`, `fpdd`, `fsdd` |
| `"distribution"` (numeric stream) | `kswin`, `adwin`, `page_hinkley`, `cusum`, `seed`, `seqdrift2` |

Use `drift_detector("<method>")` to inspect default hyperparameters for
any method.

## Summary

The core `deriva` workflow is:

``` r

drift_detector("ddm") |>          # specify
  fit(baseline, signal = error) |> # learn reference level
  advance(new_batch)               # update state, persist flags
```

Supplementary verbs —
[`augment()`](https://generics.r-lib.org/reference/augment.html),
[`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html) —
follow the tidymodels convention and make it straightforward to inspect,
summarise, and plot detection results at any point in the stream.
