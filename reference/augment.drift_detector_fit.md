# Annotated observations from a fitted drift detector

With `new_data = NULL`, returns the accumulated history (baseline +
advanced batches) annotated with `.warning`, `.drift` and `.phase`. With
`new_data`, returns a READ-ONLY preview: the batch annotated from the
current state, WITHOUT persisting it — use
[`advance()`](https://bonijoao.github.io/deriva/reference/advance.md) to
persist.

## Usage

``` r
# S3 method for class 'drift_detector_fit'
augment(x, new_data = NULL, ...)
```

## Arguments

- x:

  A `drift_detector_fit`.

- new_data:

  Optional data frame with a new batch to preview.

- ...:

  Not used.

## Value

A tibble.

## Examples

``` r
base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
f0 <- fit(drift_detector("ddm"), base, signal = error)
augment(f0)
#> # A tibble: 100 × 6
#>        t error drift_true .warning .drift .phase  
#>    <int> <int> <lgl>      <lgl>    <lgl>  <chr>   
#>  1     1     0 FALSE      NA       NA     baseline
#>  2     2     0 FALSE      NA       NA     baseline
#>  3     3     0 FALSE      NA       NA     baseline
#>  4     4     0 FALSE      NA       NA     baseline
#>  5     5     0 FALSE      NA       NA     baseline
#>  6     6     0 FALSE      NA       NA     baseline
#>  7     7     0 FALSE      NA       NA     baseline
#>  8     8     0 FALSE      NA       NA     baseline
#>  9     9     0 FALSE      NA       NA     baseline
#> 10    10     0 FALSE      NA       NA     baseline
#> # ℹ 90 more rows
```
