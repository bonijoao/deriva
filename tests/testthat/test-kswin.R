run_kswin <- function(x, seed = 1, ...) {
  set.seed(seed)
  m <- drift_method("kswin")
  params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("kswin is registered as a distribution method", {
  m <- drift_method("kswin")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$alpha, 0.005)
  expect_identical(m$params$window_size, 100)
  expect_identical(m$params$stat_size, 30)
})

test_that("kswin stays FALSE while the window fills (no NA, matches reference)", {
  out <- run_kswin(stats::rnorm(100))
  expect_false(any(is.na(out$signals$.drift)))   # KSWIN returns FALSE, not NA, during warm-up
  expect_false(any(out$signals$.drift))          # first test only at element 101
})

test_that("kswin warning column is all NA (no warning level)", {
  out <- run_kswin(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))
})

test_that("kswin detects a distribution shift after the change point", {
  x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  out <- run_kswin(x, seed = 1)
  drifts <- which(out$signals$.drift)
  expect_true(any(drifts > 500))                 # detects the shift
})

test_that("kswin init validates window_size > stat_size", {
  m <- drift_method("kswin")
  expect_error(m$init(list(alpha = 0.005, window_size = 20, stat_size = 30)),
               "window_size")
})

test_that("kswin is reproducible under a fixed seed", {
  x <- c(stats::rnorm(300), stats::rnorm(300, 2))
  expect_identical(run_kswin(x, seed = 5)$signals, run_kswin(x, seed = 5)$signals)
})
