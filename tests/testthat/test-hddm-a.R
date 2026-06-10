run_hddm_a <- function(x, ...) {
  m <- drift_method("hddm_a"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("hddm_a registered as error method with defaults", {
  m <- drift_method("hddm_a")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$drift_confidence, 0.001)
  expect_identical(m$params$warning_confidence, 0.005)
  expect_true(m$params$two_side_option)
})

test_that("hddm_a has no NA warm-up and detects an error jump", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_hddm_a(x)
  expect_false(any(is.na(out$signals$.drift)))   # Hoeffding bounds, no warm-up
  expect_true(any(which(out$signals$.drift) > 500))
})
