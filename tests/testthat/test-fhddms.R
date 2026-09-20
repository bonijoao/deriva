run_fhddms <- function(x, ...) {
  m <- drift_method("fhddms"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("fhddms registered with defaults; NA while window fills", {
  m <- drift_method("fhddms")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 100)
  expect_identical(m$params$short_size, 25)
  out <- run_fhddms(stats::rbinom(100, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:99])))   # window-fill -> NA
})

test_that("fhddms detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.02), stats::rbinom(500, 1, 0.5))
  out <- run_fhddms(x)
  expect_true(any(which(out$signals$.drift) > 500))
})
