# Package index

## Specifying and fitting detectors

Choose a detector from the catalogue of 22 methods, fit it on a baseline
period, and advance it over new observations.

- [`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md)
  : Specify a drift detector
- [`fit(`*`<drift_detector>`*`)`](https://bonijoao.github.io/deriva/reference/fit.drift_detector.md)
  : Fit a drift detector on a baseline period
- [`advance()`](https://bonijoao.github.io/deriva/reference/advance.md)
  : Advance a fitted drift detector over a new batch
- [`detect_drift()`](https://bonijoao.github.io/deriva/reference/detect_drift.md)
  : Detect drift in a signal column (one-shot shortcut)

## Inspecting results

Tidy accessors for a fitted detector and its stream of flags.

- [`augment(`*`<drift_detector_fit>`*`)`](https://bonijoao.github.io/deriva/reference/augment.drift_detector_fit.md)
  : Annotated observations from a fitted drift detector
- [`tidy(`*`<drift_detector_fit>`*`)`](https://bonijoao.github.io/deriva/reference/tidy.drift_detector_fit.md)
  : Drift points of a fitted detector
- [`glance(`*`<drift_detector_fit>`*`)`](https://bonijoao.github.io/deriva/reference/glance.drift_detector_fit.md)
  : One-row summary of a fitted detector
- [`autoplot(`*`<drift_detector_fit>`*`)`](https://bonijoao.github.io/deriva/reference/autoplot.drift_detector_fit.md)
  : Plot the monitored signal with drift markings

## Working with tidymodels

Turn model predictions into the per-observation error signal detectors
consume.

- [`add_prediction_error()`](https://bonijoao.github.io/deriva/reference/add_prediction_error.md)
  : Build a drift signal from model predictions

## Simulating streams

Synthetic streams with known change points, for benchmarking and
teaching.

- [`sim_drift_stream()`](https://bonijoao.github.io/deriva/reference/sim_drift_stream.md)
  : Simulate a binary error stream with a known drift point
- [`sim_dist_stream()`](https://bonijoao.github.io/deriva/reference/sim_dist_stream.md)
  : Simulate a continuous stream with a known distribution-shift point

## Package

- [`deriva`](https://bonijoao.github.io/deriva/reference/deriva-package.md)
  [`deriva-package`](https://bonijoao.github.io/deriva/reference/deriva-package.md)
  : deriva: Tidy Drift Detection for Monitored Machine Learning Models
- [`reexports`](https://bonijoao.github.io/deriva/reference/reexports.md)
  [`augment`](https://bonijoao.github.io/deriva/reference/reexports.md)
  [`fit`](https://bonijoao.github.io/deriva/reference/reexports.md)
  [`tidy`](https://bonijoao.github.io/deriva/reference/reexports.md)
  [`glance`](https://bonijoao.github.io/deriva/reference/reexports.md) :
  Objects exported from other packages
