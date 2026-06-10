run_fhddm <- function(x, ...) {
  m <- drift_method("fhddm"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("fhddm registered with defaults; FALSE while window fills", {
  m <- drift_method("fhddm")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 100)
  out <- run_fhddm(stats::rbinom(100, 1, 0.1))
  expect_false(any(is.na(out$signals$.drift)))   # window-fill -> FALSE (like KSWIN)
})

test_that("fhddm detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.02), stats::rbinom(500, 1, 0.5))
  out <- run_fhddm(x)
  expect_true(any(which(out$signals$.drift) > 500))
})
