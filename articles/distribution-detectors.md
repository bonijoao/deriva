# Distribution-Based Drift Detection

``` r

library(deriva)
```

## Error-based vs. distribution-based

[`vignette("deriva")`](https://bonijoao.github.io/deriva/articles/deriva.md)
covers `signal_type = "error"` methods (DDM and friends): they need a
labelled 0/1 (or continuous) error signal, usually built from a model’s
predictions with
[`add_prediction_error()`](https://bonijoao.github.io/deriva/reference/add_prediction_error.md).

`signal_type = "distribution"` methods are different: they watch a raw
numeric stream directly — no labels, no baseline error rate — and flag a
change in the stream’s distribution itself. This is the right family
when you want to monitor an input feature or a sensor reading for drift,
not just a model’s error.

## The running example: a drifting sensor

`sensor_monitoring`, shipped with the package, is a numeric
sensor-reading stream: 500 stable observations centred at 0, then 500
after the sensor drifted out of calibration and the mean shifted to 2.

``` r

head(sensor_monitoring)
#>   t       value drift_true
#> 1 1 -0.89691455      FALSE
#> 2 2  0.18484918      FALSE
#> 3 3  1.58784533      FALSE
#> 4 4 -1.13037567      FALSE
#> 5 5 -0.08025176      FALSE
#> 6 6  0.13242028      FALSE
```

## Detecting the shift with KSWIN

`"kswin"` (Kolmogorov-Smirnov Windowing) is a
`signal_type = "distribution"` method: it repeatedly compares a recent
window of the stream against an older one with a Kolmogorov-Smirnov
test.

KSWIN is stochastic — it draws a random sub-sample from its window at
every test. Pass `seed` to
[`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md)
(or, as here, straight into
[`detect_drift()`](https://bonijoao.github.io/deriva/reference/detect_drift.md),
which forwards it) to get a result that is reproducible and does not
depend on the state of your session’s random number generator.

``` r

result <- detect_drift(sensor_monitoring, .col = value, method = "kswin", seed = 7)

subset(result, .drift)
#> # A tibble: 4 × 5
#>       t value drift_true .warning .drift
#>   <int> <dbl> <lgl>      <lgl>    <lgl> 
#> 1   517  3.82 TRUE       NA       TRUE  
#> 2   605  3.18 TRUE       NA       TRUE  
#> 3   723  3.46 TRUE       NA       TRUE  
#> 4   930  2.58 TRUE       NA       TRUE
```

No detection fires in the 500 stable observations. Unlike DDM, which
settles into a new stable state after one detection, KSWIN keeps
comparing windows as they slide past the change point — so it fires
**several times** while its window catches up to the new distribution,
not just once. That is expected behaviour for a windowed method, not
noise: every one of these detections comes after the true drift point,
as the window repeatedly re-compares against the now-shifted data.

## Other distribution-based methods

`"adwin"` (Adaptive Windowing) solves the same problem with an
adaptively-sized window instead of a fixed one, and is deterministic —
no `seed` needed:

``` r

detect_drift(sensor_monitoring, .col = value, method = "adwin") |>
  subset(.drift)
#> # A tibble: 1 × 5
#>       t value drift_true .warning .drift
#>   <int> <dbl> <lgl>      <lgl>    <lgl> 
#> 1   544  3.73 TRUE       NA       TRUE
```

On this stream ADWIN settles the way DDM did in
[`vignette("deriva")`](https://bonijoao.github.io/deriva/articles/deriva.md):
a single detection, no repeated firing while the window catches up.
Which method fires once versus several times is a property of the
algorithm, not of one being more “correct” than the other — see
`drift_detector("adwin")` for its hyperparameters, and
[`vignette("deriva")`](https://bonijoao.github.io/deriva/articles/deriva.md)
for the full tidy workflow
([`fit()`](https://generics.r-lib.org/reference/fit.html)/[`advance()`](https://bonijoao.github.io/deriva/reference/advance.md)/[`augment()`](https://generics.r-lib.org/reference/augment.html)/…),
which works identically for distribution-based methods.
