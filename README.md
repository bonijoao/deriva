<!-- README.md is generated from the package sources. Please edit vignettes/README content in the R source and this file together. -->

# deriva

<!-- badges: start -->
[![R-CMD-check](https://github.com/bonijoao/deriva/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bonijoao/deriva/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
<!-- badges: end -->

**Read this in other languages:** [Português](README.pt-BR.md)

`deriva` detects **concept drift** and **data drift** in streams produced by deployed
machine learning models, through a tidy interface that composes naturally with the
`tidymodels` ecosystem. Detectors are specified, fitted on a baseline period, and
advanced over new batches of observations, returning tibbles annotated with warning
and drift flags.

A machine learning model trained on historical data implicitly assumes the
data-generating process stays stable over time. When that assumption breaks —
user behaviour shifts, a sensor drifts out of calibration, the market changes —
predictions degrade silently, with no obvious error raised. `deriva` watches a
stream of per-observation signals (typically prediction errors) and flags the
moment the underlying distribution changed.

The package ships a catalogue of **22 sequential drift detectors**, covering both
error-based methods (DDM, EDDM, HDDM, EWMA, ...) and distribution-based methods
(ADWIN, KSWIN, Page-Hinkley, ...).

## Installation

```r
# From GitHub (development version)
# install.packages("pak")
pak::pak("bonijoao/deriva")
```

Once accepted on CRAN:

```r
install.packages("deriva")
```

## Quick start

```r
library(deriva)

# Simulate a stream: 500 stable observations, then 500 with higher error rate
stream <- sim_drift_stream(
  n_pre = 500, n_post = 500,
  p_pre = 0.05, p_post = 0.30,
  seed = 42
)

result <- detect_drift(stream, .col = error, method = "ddm")

# Where was drift flagged?
subset(result, .drift)
```

## The deriva interface

`deriva` follows the same three-verb pattern as tidymodels: **specify → fit → advance**.

```r
drift_detector("ddm") |>           # specify: an inert spec, no computation yet
  fit(baseline, signal = error) |> # fit: learn the reference (baseline) level
  advance(new_batch)               # advance: update state, flag drift, keep history
```

The fitted object is immutable — `advance()` returns a *new* object with the
updated engine state and the annotated batch appended to the history; the
original is left untouched, so a stream can be replayed or forked freely.

Supplementary verbs, following the `broom`/tidymodels convention, make it
straightforward to inspect results at any point:

* `augment()` — the full annotated history as a tibble
* `tidy()` — the detected drift points
* `glance()` — a one-row summary
* `autoplot()` — a ready-made plot of the signal with warning/drift markers

## Bridging from tidymodels

`add_prediction_error()` converts the output of a tidymodels `augment()` call
(which holds truth and estimate columns) into an `.error` column that drift
detectors can consume directly — the absolute error for regression, a 0/1
mismatch indicator for classification.

```r
model |>
  augment(new_data = production_data) |>
  add_prediction_error(truth = y) |>
  drift_detector("page_hinkley") |>
  fit(., signal = .error)
```

## Available methods

| Signal type | Methods |
|---|---|
| `"error"` (0/1 or continuous error) | `ddm`, `eddm`, `hddm_a`, `hddm_w`, `ewma`, `rddm`, `stepd`, `fhddm`, `fhddms`, `mddm_a`, `mddm_e`, `mddm_g`, `wstd`, `ftdd`, `fpdd`, `fsdd`, `cusum` |
| `"distribution"` (numeric stream) | `kswin`, `adwin`, `page_hinkley`, `seed`, `seqdrift2` |

Use `drift_detector("<method>")` to inspect the default hyperparameters for any method.

See `vignette("deriva")` for a complete walkthrough.

## License

MIT © deriva authors — see [LICENSE.md](LICENSE.md).
