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

## Downstream dependencies

This is a new submission; there are no reverse dependencies.
