# Detect drift in a signal column (one-shot shortcut)

Layer-3 convenience: runs a detector over an existing signal column and
returns the data annotated with `.warning` / `.drift`. For an explicit
baseline and persistent state, use the full object path:
[`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md) +
[`fit()`](https://generics.r-lib.org/reference/fit.html) +
[`advance()`](https://bonijoao.github.io/deriva/reference/advance.md).

## Usage

``` r
detect_drift(data, .col, method = "ddm", ...)
```

## Arguments

- data:

  A data frame in temporal order.

- .col:

  Unquoted name of the signal column.

- method:

  Name of a registered method (default `"ddm"`).

- ...:

  Hyperparameters forwarded to
  [`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md).

## Value

`data` as a tibble with `.warning` and `.drift` columns added.

## Details

For `"ddm"`, the warm-up is governed by `min_instances`: the first
`min_instances - 1` observations get `NA` flags.

## Examples

``` r
s <- sim_drift_stream(seed = 42)
detect_drift(s, .col = error, method = "ddm")
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
