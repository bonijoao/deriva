# Changelog

## deriva 0.1.0

CRAN release: 2026-08-03

- Initial CRAN release.
- 22 drift detectors: DDM, EDDM, HDDM_A, HDDM_W, EWMA, RDDM, STEPD,
  FHDDM, FHDDMS, MDDM_A/E/G, WSTD, FTDD, FPDD, FSDD, CUSUM, KSWIN,
  ADWIN, Page-Hinkley, SEED, SeqDrift2.
- Tidy interface:
  [`drift_detector()`](https://bonijoao.github.io/deriva/reference/drift_detector.md)
  → [`fit()`](https://generics.r-lib.org/reference/fit.html) →
  [`advance()`](https://bonijoao.github.io/deriva/reference/advance.md)
  with [`augment()`](https://generics.r-lib.org/reference/augment.html),
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
  [`glance()`](https://generics.r-lib.org/reference/glance.html), and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  generics.
- [`detect_drift()`](https://bonijoao.github.io/deriva/reference/detect_drift.md)
  one-shot shortcut.
- [`add_prediction_error()`](https://bonijoao.github.io/deriva/reference/add_prediction_error.md)
  bridge from tidymodels workflows.
- [`sim_drift_stream()`](https://bonijoao.github.io/deriva/reference/sim_drift_stream.md)
  and
  [`sim_dist_stream()`](https://bonijoao.github.io/deriva/reference/sim_dist_stream.md)
  for synthetic benchmarking.
