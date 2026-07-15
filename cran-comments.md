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

This is a second resubmission. Uwe Ligges reported invalid file URIs in
`README.md` pointing to `LICENSE.md` and `README.pt-BR.md` — both are excluded
from the built package (only `LICENSE` ships, and `README.pt-BR.md` is a
GitHub-only Portuguese translation, excluded via `.Rbuildignore`), so links to
them from `README.md` resolved to nothing inside the installed package.

Fixed by checking the actual built tarball's `README.md`: the license badge and
license link now point to `LICENSE` (which does ship), and the language-switch
link now points to the absolute GitHub URL
(`https://github.com/bonijoao/deriva/blob/main/README.pt-BR.md`) instead of a
local relative path, since `README.pt-BR.md` is never part of the package.
Verified with `tar -tzf` / extracting `README.md` from the freshly built
tarball that no remaining link resolves to an excluded file.

## Downstream dependencies

This is a new submission; there are no reverse dependencies.
