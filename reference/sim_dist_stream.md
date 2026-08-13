# Simulate a continuous stream with a known distribution-shift point

Generates a numeric stream drawn from `N(mean_pre, sd_pre)` for the
first `n_pre` observations and `N(mean_post, sd_post)` afterwards.
Companion to
[`sim_drift_stream()`](https://bonijoao.github.io/deriva/reference/sim_drift_stream.md)
for distribution-based detectors (e.g. `"kswin"`).

## Usage

``` r
sim_dist_stream(
  n_pre = 500,
  n_post = 500,
  mean_pre = 0,
  mean_post = 3,
  sd_pre = 1,
  sd_post = 1,
  seed = NULL
)
```

## Arguments

- n_pre, n_post:

  Observations before / after the shift point.

- mean_pre, mean_post:

  Means before / after the shift.

- sd_pre, sd_post:

  Standard deviations before / after the shift.

- seed:

  Optional integer for
  [`set.seed()`](https://rdrr.io/r/base/Random.html).

## Value

A tibble with `t` (index), `value` (numeric) and `drift_true` (logical:
`TRUE` after the shift point).

## Examples

``` r
sim_dist_stream(n_pre = 100, n_post = 100, mean_post = 3, seed = 42)
#> # A tibble: 200 × 3
#>        t   value drift_true
#>    <int>   <dbl> <lgl>     
#>  1     1  1.37   FALSE     
#>  2     2 -0.565  FALSE     
#>  3     3  0.363  FALSE     
#>  4     4  0.633  FALSE     
#>  5     5  0.404  FALSE     
#>  6     6 -0.106  FALSE     
#>  7     7  1.51   FALSE     
#>  8     8 -0.0947 FALSE     
#>  9     9  2.02   FALSE     
#> 10    10 -0.0627 FALSE     
#> # ℹ 190 more rows
```
