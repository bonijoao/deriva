# Advance a fitted drift detector over a new batch

Feeds a new batch of observations (any size, including 1 — stream mode)
to the detector and returns a NEW fitted object with the engine state
advanced and the annotated batch appended to the history. The original
object is not modified. This is the only way to persist state; see
[`augment()`](https://generics.r-lib.org/reference/augment.html) for a
read-only preview.

## Usage

``` r
advance(object, ...)

# S3 method for class 'drift_detector_fit'
advance(object, new_data, ...)
```

## Arguments

- object:

  A `drift_detector_fit`.

- ...:

  Passed to methods.

- new_data:

  A data frame with the new batch, in temporal order, containing the
  same signal column used in
  [`fit()`](https://generics.r-lib.org/reference/fit.html).

## Value

A new `drift_detector_fit`.

## Details

Why not [`update()`](https://rdrr.io/r/stats/update.html): in the
tidymodels ecosystem [`update()`](https://rdrr.io/r/stats/update.html)
on a spec means "change hyperparameters", so deriva defines its own
verb.

## Examples

``` r
base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
f0 <- fit(drift_detector("ddm"), base, signal = error)
f1 <- advance(f0, sim_drift_stream(n_pre = 0, n_post = 50, seed = 2))
```
