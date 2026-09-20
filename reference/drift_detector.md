# Specify a drift detector

Creates an inert detector specification (analogous to a parsnip model
spec). Nothing is computed until
[`fit()`](https://generics.r-lib.org/reference/fit.html) is called on a
baseline period.

## Usage

``` r
drift_detector(method = "ddm", ..., seed = NULL, keep = 10000)
```

## Arguments

- method:

  Name of a registered detection method, e.g. `"ddm"`.

- ...:

  Method hyperparameters overriding the defaults (e.g.
  `min_instances = 50` for `"ddm"`). Unknown parameters and values
  outside a parameter's valid range error. A few hyperparameters are
  thresholds on the signal's own scale rather than dimensionless,
  notably `epsilon_prime` for `"seed"`, whose default (`0.01`) suits a
  0/1 error stream; on a numeric stream of a different magnitude, scale
  it to match.

- seed:

  `NULL` (default) or a single whole number. When set, the detector
  draws from its own private random stream, carried inside the fitted
  object: results are reproducible, do not depend on how the stream is
  split into batches, and the session's global RNG is left untouched.
  Only `"kswin"` and `"seqdrift2"` are stochastic. With `NULL` they draw
  from the global RNG, so call
  [`set.seed()`](https://rdrr.io/r/base/Random.html) yourself for
  reproducibility.

- keep:

  Number of most recent annotated rows retained in the fitted object's
  history (default `10000`), bounding memory and the cost of each
  [`advance()`](https://bonijoao.github.io/deriva/reference/advance.md)
  on long-running streams. Totals in
  [`glance()`](https://generics.r-lib.org/reference/glance.html) and
  drift points in
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) are tracked
  separately and stay exact whatever `keep` is. `Inf` keeps everything
  and `0` keeps nothing; both warn.

## Value

A `drift_detector` specification object.

## Warning and drift flags

Every detector annotates each observation with `.warning` and `.drift`
under one contract. `NA`: the detector cannot judge this observation yet
— it is warming up, which also happens again right after a detected
drift resets it. `FALSE`: the detector is active and has not flagged
drift as of this observation; note that `"adwin"`, `"seed"` and
`"seqdrift2"` run their test only on a clock or at block boundaries, so
between tests they carry the previous verdict forward. `TRUE`: it
flagged drift here. Detectors with no warning level (`"ewma"`,
`"page_hinkley"`, `"cusum"`, `"kswin"`, `"adwin"`, `"seed"`,
`"seqdrift2"`, `"fhddms"`, `"mddm_a"`, `"mddm_g"`, `"mddm_e"`) always
give `.warning = NA`. Use `which(.drift)` or `dplyr::filter(.drift)`,
which skip `NA`; `any(.drift)` needs `na.rm = TRUE`.

## Examples

``` r
drift_detector("ddm", min_instances = 50)
#> Drift Detector Specification (ddm)
#>   min_instances: 50
#>   warning_level: 2
#>   out_control_level: 3
#>   keep: 10000
```
