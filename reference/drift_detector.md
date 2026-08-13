# Specify a drift detector

Creates an inert detector specification (analogous to a parsnip model
spec). Nothing is computed until
[`fit()`](https://generics.r-lib.org/reference/fit.html) is called on a
baseline period.

## Usage

``` r
drift_detector(method = "ddm", ...)
```

## Arguments

- method:

  Name of a registered detection method, e.g. `"ddm"`.

- ...:

  Method hyperparameters overriding the defaults (e.g.
  `min_instances = 50` for `"ddm"`). Unknown parameters error.

## Value

A `drift_detector` specification object.

## Examples

``` r
drift_detector("ddm", min_instances = 50)
#> Drift Detector Specification (ddm)
#>   min_instances: 50
#>   warning_level: 2
#>   out_control_level: 3
```
