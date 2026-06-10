run_ewma <- function(x, ...) {
  m <- drift_method("ewma"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("ewma registered with defaults; warning all NA; NA warm-up", {
  m <- drift_method("ewma")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$lambda, 0.2)
  expect_identical(m$params$L, 3.5)
  expect_identical(m$params$min_instances, 30)
  out <- run_ewma(stats::rbinom(200, 1, 0.1))
  expect_true(all(is.na(out$signals$.warning)))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

test_that("ewma detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_ewma(x)
  d <- which(out$signals$.drift)
  expect_true(any(d > 500))
  expect_lt(length(d), 60)
})
