# Simulated sensor monitoring stream

A synthetic numeric sensor-reading stream: 500 stable observations
centred at 0, then 500 after the sensor drifted out of calibration and
the mean shifted to 2. Frozen with a fixed seed.

## Usage

``` r
sensor_monitoring
```

## Format

A tibble with 1,000 rows and 3 columns:

- t:

  Observation index, 1 to 1000.

- value:

  Numeric sensor reading.

- drift_true:

  Ground truth: `TRUE` from observation 501 on, the point the sensor
  drifted.

## Source

Simulated with
[`sim_dist_stream()`](https://bonijoao.github.io/deriva/reference/sim_dist_stream.md):
`sim_dist_stream(n_pre = 500, n_post = 500, mean_pre = 0, mean_post = 2, seed = 2)`.
See `data-raw/sensor-monitoring.R`.

## Examples

``` r
sensor_monitoring
#> # A tibble: 1,000 × 3
#>        t   value drift_true
#>    <int>   <dbl> <lgl>     
#>  1     1 -0.897  FALSE     
#>  2     2  0.185  FALSE     
#>  3     3  1.59   FALSE     
#>  4     4 -1.13   FALSE     
#>  5     5 -0.0803 FALSE     
#>  6     6  0.132  FALSE     
#>  7     7  0.708  FALSE     
#>  8     8 -0.240  FALSE     
#>  9     9  1.98   FALSE     
#> 10    10 -0.139  FALSE     
#> # ℹ 990 more rows
detect_drift(sensor_monitoring, .col = value, method = "kswin", seed = 7)
#> # A tibble: 1,000 × 5
#>        t   value drift_true .warning .drift
#>    <int>   <dbl> <lgl>      <lgl>    <lgl> 
#>  1     1 -0.897  FALSE      NA       NA    
#>  2     2  0.185  FALSE      NA       NA    
#>  3     3  1.59   FALSE      NA       NA    
#>  4     4 -1.13   FALSE      NA       NA    
#>  5     5 -0.0803 FALSE      NA       NA    
#>  6     6  0.132  FALSE      NA       NA    
#>  7     7  0.708  FALSE      NA       NA    
#>  8     8 -0.240  FALSE      NA       NA    
#>  9     9  1.98   FALSE      NA       NA    
#> 10    10 -0.139  FALSE      NA       NA    
#> # ℹ 990 more rows
```
