run_hddm_w <- function(x, ...) {
  m <- drift_method("hddm_w"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("hddm_w registered as error method with defaults", {
  m <- drift_method("hddm_w")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$drift_confidence, 0.001)
  expect_identical(m$params$warning_confidence, 0.005)
  expect_identical(m$params$lambda_option, 0.05)
  expect_true(m$params$two_side_option)
})

test_that("hddm_w has no NA warm-up and detects an error jump", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_hddm_w(x)
  expect_false(any(is.na(out$signals$.drift)))
  expect_true(any(which(out$signals$.drift) > 500))
})
