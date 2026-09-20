# Simulated credit monitoring stream

A synthetic per-observation error stream from a credit-approval
classifier in production: 500 stable observations (5% error rate), then
500 after a market shift raised the error rate to 30%. Frozen with a
fixed seed, so every example that loads it sees the same story —
including the single, correct DDM detection at `t = 542` with no false
positives before it.

## Usage

``` r
credit_monitoring
```

## Format

A tibble with 1,000 rows and 3 columns:

- t:

  Observation index, 1 to 1000.

- error:

  0/1 classifier error for that observation.

- drift_true:

  Ground truth: `TRUE` from observation 501 on, the point the market
  shift occurred.

## Source

Simulated with
[`sim_drift_stream()`](https://bonijoao.github.io/deriva/reference/sim_drift_stream.md):
`sim_drift_stream(n_pre = 500, n_post = 500, p_pre = 0.05, p_post = 0.30, seed = 2)`.
See `data-raw/credit-monitoring.R`.

## Examples

``` r
credit_monitoring
#> # A tibble: 1,000 × 3
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
#> # ℹ 990 more rows
detect_drift(credit_monitoring, .col = error, method = "ddm")
#> # A tibble: 1,000 × 5
#>        t error drift_true .warning .drift
#>    <int> <int> <lgl>      <lgl>    <lgl> 
#>  1     1     0 FALSE      NA       NA    
#>  2     2     0 FALSE      NA       NA    
#>  3     3     0 FALSE      NA       NA    
#>  4     4     0 FALSE      NA       NA    
#>  5     5     0 FALSE      NA       NA    
#>  6     6     0 FALSE      NA       NA    
#>  7     7     0 FALSE      NA       NA    
#>  8     8     0 FALSE      NA       NA    
#>  9     9     0 FALSE      NA       NA    
#> 10    10     0 FALSE      NA       NA    
#> # ℹ 990 more rows
```
