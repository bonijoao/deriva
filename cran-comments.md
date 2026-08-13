# cran-comments.md

## Test environments

* Local: Windows 11 x64, R 4.5.3 (`devtools::check(cran = TRUE)`)
* win-builder (R-devel, 2026-07-22 r90289 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

```
Possibly misspelled words in DESCRIPTION:
  ADWIN, DDM, EDDM, EWMA, HDDM, Hinkley, KSWIN, tibbles, ...
```

These are established acronyms for drift-detection methods (now expanded on
first use in the Description), surnames of the cited authors (Gama,
Baena-Garcia, Frias-Blanco, Bifet, Gavalda, Raab), mathematical eponyms
(Hoeffding, Kolmogorov-Smirnov, Page-Hinkley), and the 'tibbles' data
structure from the tidyverse — not misspellings.

## Resubmission

This is a third resubmission, addressing the three points raised by
Konstanze Lauseker:

* **Acronyms explained**: every acronym in the Description (DDM, EDDM,
  HDDM, EWMA, ADWIN, KSWIN) is now expanded on first use, e.g. "the Drift
  Detection Method (DDM)".

* **References added**: the methods named in the Description are now cited
  in the requested `authors (year) <doi:...>` form (Gama et al. 2004;
  Frias-Blanco et al. 2015; Ross et al. 2012; Bifet and Gavalda 2007;
  Raab et al. 2020; Page 1954). All six DOIs were verified to resolve to
  the correct articles. The EDDM paper (Baena-Garcia et al. 2006, IWKDDS
  workshop) has no DOI or stable publisher URL, so it is cited by authors
  and year only.

* **User options restored**: the vignette (source of `inst/doc/deriva.R`)
  changed `options(width = 70)` without restoring it. The setup chunk now
  saves the previous value (`old_options <- options(width = 70)`) and a
  final chunk restores it (`options(old_options)`). Verified in the
  freshly built tarball's `inst/doc/deriva.R`.

Additionally in this resubmission: a third package author was added to
`Authors@R`, and minor documentation inconsistencies were corrected. No
changes to package code or API.

## Downstream dependencies

This is a new submission; there are no reverse dependencies.
