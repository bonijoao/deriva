test_that("every method reproduces its frozen flags", {
  frozen <- readRDS(test_path("fixtures", "regression-flags.rds"))
  expect_setequal(names(frozen), names(the$methods))
  for (m in names(frozen)) {
    r <- run_on_bundled(m)
    expect_identical(which(r$.drift), frozen[[m]]$drift, label = paste(m, "drift rows"))
    expect_identical(which(r$.warning), frozen[[m]]$warning, label = paste(m, "warning rows"))
  }
})
