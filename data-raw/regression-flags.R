# Regenerates the frozen flags; rerun ONLY for a deliberate behaviour change.
source("tests/testthat/helper-bundled.R")
methods <- names(deriva:::the$methods)
regression_flags <- lapply(stats::setNames(methods, methods), function(m) {
  r <- run_on_bundled(m)
  list(drift = which(r$.drift), warning = which(r$.warning))
})
saveRDS(regression_flags, "tests/testthat/fixtures/regression-flags.rds", version = 2)
