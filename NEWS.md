# deriva (development version)

* `.warning` and `.drift` now follow one contract across all 22 detectors:
  `NA` means the detector cannot judge that observation yet (warm-up), `FALSE`
  that it is active and has not flagged drift as of that observation.
  **Behaviour change:** `"kswin"`,
  `"adwin"`, `"seed"`, `"seqdrift2"`, `"fhddm"`, `"fhddms"` and the `"mddm_*"`
  detectors used to report `FALSE` while warming up and now report `NA`;
  `"fhddms"` and `"mddm_*"`, which have no warning level, now give
  `.warning = NA`. Detections themselves are unchanged.
* `"seed"` no longer has an `alpha` hyperparameter: the algorithm never read it.
* `fit()`, `advance()`, `augment()` and `detect_drift()` now refuse data that
  already has a `.warning`, `.drift` or `.phase` column instead of overwriting
  it, and `advance()` refuses a batch whose columns differ from the baseline's.
* `"wstd"`, `"ftdd"`, `"fpdd"` and `"fsdd"` are much faster: their per-observation
  tests use closed forms that give identical p-values.
* Hyperparameter values are now validated when the detector is specified.
  Out-of-range values, wrong types and impossible combinations (e.g. `"kswin"`
  with `window_size < stat_size + 2`) abort with a clear message instead of
  running and returning silently wrong flags. `drift_detector()` also rejects
  a `method` that is not a single string.
* `drift_detector()` gains `seed`: the stochastic detectors (`"kswin"`,
  `"seqdrift2"`) draw from a private random stream carried inside the fitted
  object. Results are reproducible, independent of batching, and the session's
  global RNG is no longer advanced.
* `drift_detector()` gains `keep` (default `10000`), the number of most recent
  rows retained in the history. This bounds memory and removes the quadratic
  cost of row-by-row `advance()`. **Behaviour change:** histories longer than
  10000 rows are now truncated, so `augment()` on a fitted detector returns
  at most the last `keep` rows; use `keep = Inf` for the previous behaviour.
  `keep = Inf` and `keep = 0` emit a warning when the detector is specified.
* `tidy()`, `glance()` and `print()` report running totals stored in the
  fitted object, so they stay exact when the history is truncated.
* Fitted detectors saved with deriva 0.1.0 must be refit.
* deriva now declares `Depends: R (>= 4.1)` and imports `utils`, which
  `"kswin"` already used.
* Two reference datasets ship with the package, `credit_monitoring` and
  `sensor_monitoring`, and the vignettes ("Getting Started with deriva",
  and the new "Distribution-Based Drift Detection") now walk through them
  instead of generating data inline.

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
