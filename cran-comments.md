# cran-comments.md

## Test environments

* Local: Windows 11 x64, R 4.5.3 (`devtools::check(cran = TRUE)`)
* win-builder (R-devel, 2026-07-13 r90246 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

```
Possibly misspelled words in DESCRIPTION:
  ADWIN, DDM, EDDM, EWMA, HDDM, Hinkley, KSWIN, tibbles
```

These are established names/acronyms for drift-detection methods (e.g. ADWIN, DDM,
EDDM, EWMA, HDDM, Page-Hinkley, KSWIN) and the 'tibbles' data structure from the
tidyverse, not misspellings.

## Resubmission

This is a resubmission. The CRAN incoming pretest flagged two additional NOTEs on
2026-07-14, both now fixed:

* "Invalid file URI" pointing to `LICENSE.md` from `README.md` — `LICENSE.md` is
  excluded from the built package (only the CRAN-required `LICENSE` stub ships);
  the README now links to `LICENSE` instead.
* "Non-standard file/directory found at top level: 'README.pt-BR.md'" — this
  Portuguese-language README is now excluded from the built package via
  `.Rbuildignore` (it remains in the GitHub repository only).

## Downstream dependencies

This is a new submission; there are no reverse dependencies.
