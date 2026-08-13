# Simulate a binary error stream with a known drift point

Generates a stream of 0/1 classifier errors whose error rate jumps from
`p_pre` to `p_post` after `n_pre` observations. Useful for testing and
validating drift detectors against a known ground truth.

## Usage

``` r
sim_drift_stream(
  n_pre = 500,
  n_post = 500,
  p_pre = 0.05,
  p_post = 0.3,
  seed = NULL
)
```

## Arguments

- n_pre, n_post:

  Number of observations before / after the drift point.

- p_pre, p_post:

  Error probability before / after the drift point.

- seed:

  Optional integer; if supplied,
  [`set.seed()`](https://rdrr.io/r/base/Random.html) is called for
  reproducibility.

## Value

A tibble with columns `t` (index), `error` (0/1) and `drift_true`
(logical ground truth: `TRUE` after the drift point).

## Examples

``` r
sim_drift_stream(n_pre = 100, n_post = 100, seed = 42)
#> # A tibble: 200 × 3
#>        t error drift_true
#>    <int> <int> <lgl>     
#>  1     1     0 FALSE     
#>  2     2     0 FALSE     
#>  3     3     0 FALSE     
#>  4     4     0 FALSE     
#>  5     5     0 FALSE     
#>  6     6     0 FALSE     
#>  7     7     0 FALSE     
#>  8     8     0 FALSE     
#>  9     9     0 FALSE     
#> 10    10     0 FALSE     
#> # ℹ 190 more rows
```
