# cran-comments.md

## Test environments

* Local: Windows 11 x64, R 4.5.3 (`devtools::check(cran = TRUE)`)
* GitHub Actions: Ubuntu and Windows on R-release; Ubuntu on R-devel and on
  R-oldrel-1
* win-builder: R-devel (2026-09-19 r90572 ucrt) and R-release (4.6.1)

## R CMD check results

0 errors | 0 warnings | 0 notes

Clean on every environment above. The spelling note that 0.1.0 drew on
win-builder no longer appears: the acronyms, author surnames and eponyms it
listed are in `inst/WORDLIST`.

## This submission

This is an update from 0.1.0 to 0.2.0. It fixes correctness and
reproducibility problems found by a systematic audit of the 22 detectors
after the first release, and it introduces four intentional changes in
behaviour, all documented in NEWS.md:

* **One `.warning`/`.drift` contract across all detectors.** `NA` now
  means the detector cannot yet judge that observation (warm-up) and
  `FALSE` that it is active and has not flagged drift. Seven detectors
  previously reported `FALSE` while warming up, and the detectors with no
  warning level previously reported `FALSE` rather than `NA` for
  `.warning`. The detections themselves are unchanged: a frozen
  regression fixture over the bundled datasets pins the flagged indices
  of all 22 detectors and confirms none of them moved.

* **The stored history is bounded.** `drift_detector()` gains
  `keep` (default `10000`), the number of most recent rows retained.
  Histories longer than that are now truncated, so `augment()` on a
  fitted detector returns at most the last `keep` rows; `keep = Inf`
  restores the previous behaviour. This bounds memory (the history
  previously grew without limit, ~1.8 GB for 10 million observations) and
  removes the quadratic cost of row-by-row `advance()`. `tidy()`,
  `glance()` and `print()` now read running totals stored in the fitted
  object, so they remain exact when the history is truncated.

* **Invalid input now aborts instead of returning silently wrong
  results.** Hyperparameter values are validated when the detector is
  specified; previously only parameter *names* were checked, so e.g.
  `min_instances = "abc"` ran to completion and returned `NA` flags for
  the whole stream. `fit()`, `advance()`, `augment()` and
  `detect_drift()` also refuse data that already has a `.warning`,
  `.drift` or `.phase` column instead of overwriting it, and `advance()`
  refuses a batch whose columns differ from the baseline's.

* **Fitted detectors saved with 0.1.0 must be refit.** Such objects lack
  the running totals introduced here; they raise a clear error asking for
  a refit rather than being migrated silently.

Also in this release: a `seed` argument giving the stochastic detectors a
private random stream (the session's global RNG is no longer advanced),
closed-form p-values for `"wstd"` and the Fisher detectors (about 45x and
19x faster respectively), removal of the unused `alpha` hyperparameter of
`"seed"`, two bundled reference datasets with rewritten vignettes, and a
declared `Depends: R (>= 4.1)` and `utils` import.

## Downstream dependencies

There are no reverse dependencies on CRAN.
