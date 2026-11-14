# deriva (development version)

* New detector `"kl_divergence"`, the Kullback-Leibler change detector of
  Dasu, Krishnan, Venkatasubramanian and Yi (2006) in one dimension. A fixed
  reference window is compared with a sliding window over cells built from the
  reference (a 1-D kdq-tree), with Krichevsky-Trofimov smoothing; drift is
  flagged when the distance stays above a bootstrap critical value for
  `persistence * window_size` consecutive observations. It is stochastic (the
  bootstrap) and honours `seed`, and has no warning level. Defaults follow the
  paper's Table 1, except `window_size` and `max_cell_points`, which are scaled
  down from the paper's 10000-point windows. In simulation, about 3 in 10
  stationary streams of 2000 observations raise a false alarm. On the bundled
  `sensor_monitoring` stream it raises one around row 432; the restart then
  takes a reference that straddles the true change at row 501, so the real
  shift is reported only at row 841. The paper's own one-dimensional
  experiments used a much stricter `alpha`; lower it (raising `n_boot` to at
  least `1 / alpha`) for fewer false alarms at the cost of a longer delay.
* New detector `"seqdrift1"`, SeqDrift1 of Sakthithasan, Pears and Koh (2013),
  the sliding-window predecessor of `"seqdrift2"`. At every block boundary the
  mean of the recent values is compared with that of a left window of older
  blocks (at most `1 / delta` of them) using the Bernstein bound of Theorem 1
  in Pears, Sakthithasan and Koh (2014). Unlike `"seqdrift2"` it is
  deterministic and has a warning level: while the difference sits between
  the `delta_warning` and `delta` thresholds, `.warning` is `TRUE` and the
  recent window keeps growing. Defaults (`delta = 0.01`,
  `delta_warning = 0.1`, `block_size = 200`) follow the author's MOA
  implementation. As for `"seqdrift2"`, the bound's guarantee assumes values
  in [0, 1], such as 0/1 errors.
* New detector `"hdddm"`, the Hellinger Distance Drift Detection Method of
  Ditzler and Polikar (2011) in one dimension. Observations are taken in
  batches of `batch_size`; each batch becomes a histogram with
  `floor(sqrt(batch_size))` bins, and drift is flagged when the change in its
  Hellinger distance to the reference histogram exceeds the adaptive threshold
  of the paper's Eq. (2), the mean plus `gamma` standard deviations of the past
  changes. Without drift the batch joins the reference; on drift it replaces
  it. Flags change only when a batch completes, the first test is at
  observation `4 * batch_size`, and there is no warning level. Our choices: bin
  edges are equal-width over the reference batch and are rebuilt from the
  drift batch when it becomes the new reference (the paper assumes a known
  support and keeps them), with values outside them counted in the outer bins; `batch_size = 100`, since the paper does not
  report one; the t-statistic threshold of Eq. (3) is not included. The
  adaptive threshold makes HDDDM alarm-prone on stationary data: in simulation
  98 in 100 stationary normal streams of 2000 observations raised at least one
  alarm (2.9 per stream on average), many at the first test, where only one
  past change sets the threshold. Raising `gamma` helps only a little (72 in
  100 at `gamma = 3`). On the bundled `sensor_monitoring` stream it raises one
  such alarm at row 400; the true shift at row 501 then falls in the second
  batch after the restart, whose change in distance is the first one recorded
  and only sets the scale of the threshold, so it is never reported. In
  general, a change during the first three batches after a start or a drift
  is absorbed this way.
* New detector `"quanttree"`, QuantTree of Boracchi, Carrera, Cervellera and
  Macciò (2018) in one dimension. The first `train_size` observations are cut
  at their order statistics into `n_bins` bins of equal training counts; each
  following batch of `batch_size` values is tested with the Pearson statistic
  against a threshold that, by the paper's Theorem 1, does not depend on the
  data. The threshold is simulated once from the exact null law (Algorithm 2),
  which makes the method stochastic, so it honours `seed`. It has no warning
  level, and flags change only when a batch completes; the first test is at
  observation 576 at the defaults. `alpha` is a false-positive rate per batch:
  at the defaults a stationary stream raises a false alarm about once every
  6400 observations (once every 8600 in simulation). Our choices: on drift the
  detector restarts and the next `train_size` values form a new training set
  (the paper defines only the single-batch test); defaults smaller than the
  paper's (`train_size = 512`, `n_bins = 16`, `alpha = 0.01` instead of 4096,
  32 and 0.05), so the warm-up stays short and false alarms rare; only the
  Pearson statistic. The guarantee assumes continuous data: tied values, such
  as 0/1 errors or counts, break the equal-count bins and make nearly every
  batch alarm, so the detector warns once when its training set has ties. The
  paper adds a little noise to such data; deriva does not. When `train_size`
  is not a multiple of `n_bins`, the remainder is spread over the last bins
  (the paper's rounding can leave the last bin empty).
* New detector `"iks"`, the drift detector of dos Reis, Flach, Matwin and
  Batista (2016) built on their incremental Kolmogorov-Smirnov test, in one
  dimension. A fixed reference of `window_size` values is compared with a
  sliding window of the last `window_size` values by a two-sample KS test
  after every observation; drift is flagged when the statistic exceeds
  `c(alpha) * sqrt(2 / window_size)`, and the current window then becomes the
  reference. The statistic is computed exactly rather than with the paper's
  treap, which only speeds it up. Unlike `"kswin"`, the reference stays fixed
  until a drift and both windows are used whole, so `"iks"` is deterministic,
  and a slow ramp keeps moving away from the reference instead of with it. It
  has no warning level; the first test is at observation 200 at the
  defaults, and after a drift the next one comes `window_size` observations
  later. Defaults are the paper's (`window_size = 100`, `alpha = 0.001`); the
  small `alpha` is the paper's remedy for testing on every observation, and
  in simulation 4 in 100 stationary streams of 2000 observations raised a
  false alarm. Our choices: the initial reference is the first `window_size`
  observations, and the two windows never overlap. On the bundled
  `sensor_monitoring` stream it flags the shift at row 542 and again at row
  642, because the new reference is the window that straddles the change.

# deriva 0.2.0

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
