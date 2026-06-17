# deriva 0.1.0

* Initial CRAN release.
* 22 drift detectors: DDM, EDDM, HDDM_A, HDDM_W, EWMA, RDDM, STEPD, FHDDM,
  FHDDMS, MDDM_A/E/G, WSTD, FTDD, FPDD, FSDD, CUSUM, KSWIN, ADWIN,
  Page-Hinkley, SEED, SeqDrift2.
* Tidy interface: `drift_detector()` → `fit()` → `advance()` with
  `augment()`, `tidy()`, `glance()`, and `autoplot()` generics.
* `detect_drift()` one-shot shortcut.
* `add_prediction_error()` bridge from tidymodels workflows.
* `sim_drift_stream()` and `sim_dist_stream()` for synthetic benchmarking.
