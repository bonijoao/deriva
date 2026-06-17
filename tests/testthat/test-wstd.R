run_wstd <- function(x, ...) {
  m <- drift_method("wstd"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("wstd registered as error method with stepd defaults plus capped old window", {
  m <- drift_method("wstd")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 30)
  expect_identical(m$params$warning_level, 0.05)
  expect_identical(m$params$out_control_level, 0.003)
  expect_identical(m$params$max_old, 4000)
})

test_that("wstd detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_wstd(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("wstd keeps a low false-alarm rate on a stationary stream", {
  set.seed(7); x <- stats::rbinom(1000, 1, 0.1)
  out <- run_wstd(x)
  expect_lt(mean(out$signals$.drift, na.rm = TRUE), 0.05)
})

test_that("wstd emits NA during warm-up", {
  out <- run_wstd(stats::rbinom(40, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

# --- the rank-sum statistic itself ---

test_that("wstd_pvalue is tiny when recent is all errors over an all-correct past", {
  expect_lt(wstd_pvalue(recent = rep(1, 30), older = rep(0, 200)), 0.003)
})

test_that("wstd_pvalue does not flag a stationary (equal) split", {
  set.seed(1); v <- stats::rbinom(230, 1, 0.2)
  expect_gt(wstd_pvalue(recent = v[1:30], older = v[31:230]), 0.05)
})

test_that("wstd_pvalue refuses to flag a DROP in error rate", {
  # recent cleaner than the past -> one-sided (increase) test must not fire
  expect_identical(wstd_pvalue(recent = rep(0, 30), older = rep(1, 200)), 1)
})

test_that("wstd caps the older window at max_old", {
  set.seed(2); x <- stats::rbinom(200, 1, 0.2)
  out <- run_wstd(x, max_old = 50)
  # buffer holds at most window_size + max_old observations
  expect_lte(length(out$state$buf), 30 + 50)
})
