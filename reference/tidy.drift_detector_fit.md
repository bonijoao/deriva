# Drift points of a fitted detector

Drift points of a fitted detector

## Usage

``` r
# S3 method for class 'drift_detector_fit'
tidy(x, ...)
```

## Arguments

- x:

  A `drift_detector_fit`.

- ...:

  Not used.

## Value

A tibble with one row per detected drift: `index` (position since the
start of the baseline, exact even when the history is truncated by
`keep`) and `phase`.
