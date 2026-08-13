# One-row summary of a fitted detector

One-row summary of a fitted detector

## Usage

``` r
# S3 method for class 'drift_detector_fit'
glance(x, ...)
```

## Arguments

- x:

  A `drift_detector_fit`.

- ...:

  Not used.

## Value

A 1-row tibble: `method`, `n_obs`, `n_warning`, `n_drift`, `first_drift`
(NA if no drift detected).
