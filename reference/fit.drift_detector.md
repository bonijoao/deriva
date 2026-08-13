# Fit a drift detector on a baseline period

Runs the detector over the baseline data — the period where the
monitored model is considered stable — so it learns the reference
("normal") level. The returned object is immutable: feed new batches
with
[`advance()`](https://bonijoao.github.io/deriva/reference/advance.md).

## Usage

``` r
# S3 method for class 'drift_detector'
fit(object, data, signal, ...)
```

## Arguments

- object:

  A
  [`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md)
  specification.

- data:

  A data frame with the baseline period, in temporal order.

- signal:

  Unquoted name of the signal column (0/1 errors for error-based methods
  such as `"ddm"`).

- ...:

  Not used.

## Value

A `drift_detector_fit` object.

## Examples

``` r
base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
fit(drift_detector("ddm"), base, signal = error)
#> Fitted Drift Detector (ddm)
#>   observations: 100 (100 baseline)
#>   warnings: 10 | drifts: 0
```
