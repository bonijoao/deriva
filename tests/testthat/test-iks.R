test_that("iks_c reproduces the Smirnov table", {
  expect_equal(round(iks_c(c(0.10, 0.05, 0.01, 0.001)), 2), c(1.22, 1.36, 1.63, 1.95))
})

test_that("iks_d is the two-sample KS statistic, ties included", {
  set.seed(1); a <- round(stats::rnorm(100), 1); b <- round(stats::rnorm(100, 0.3), 1)
  expect_equal(iks_d(sort(a), b), unname(suppressWarnings(stats::ks.test(a, b))$statistic))
  expect_equal(iks_d(sort(c(1, 2, 3)), c(1, 2, 3)), 0)
  expect_equal(iks_d(sort(c(-Inf, 0, 1)), c(2, 3, Inf)), 1)
})

run_iks <- function(x, ...) detect_drift(tibble::tibble(value = x), .col = value, method = "iks", ...)

test_that("iks is registered with the paper's settings", {
  m <- drift_method("iks")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params, list(window_size = 100, alpha = 0.001))
})

test_that("iks is NA until observation 200", {
  set.seed(1); r <- run_iks(stats::rnorm(400))
  expect_true(all(is.na(r$.drift[1:199])))
  expect_false(is.na(r$.drift[200]))
  expect_true(all(is.na(r$.warning)))
})

test_that("iks detects a mean shift and stays quiet before it", {
  set.seed(2); r <- run_iks(c(stats::rnorm(1000), stats::rnorm(400, 1)))
  expect_false(any(r$.drift[1:1000], na.rm = TRUE))
  expect_true(any(r$.drift[1001:1200], na.rm = TRUE))
})

test_that("iks catches a slow ramp against its fixed reference", {
  set.seed(3); x <- stats::rnorm(3000) + c(rep(0, 500), seq(0, 2, length.out = 2500))
  expect_true(any(run_iks(x)$.drift, na.rm = TRUE))
})

test_that("iks re-warms for one window after a drift", {
  set.seed(4); r <- run_iks(c(stats::rnorm(300), stats::rnorm(500, 3)))
  hit <- which(r$.drift)[1]
  expect_true(all(is.na(r$.drift[(hit + 1):(hit + 99)])))
  expect_false(is.na(r$.drift[hit + 100]))
})

test_that("iks copes with constant streams and infinite values", {
  expect_false(any(run_iks(rep(2, 500))$.drift, na.rm = TRUE))
  set.seed(5); x <- stats::rnorm(500); x[c(50, 250)] <- c(Inf, -Inf)
  expect_no_error(run_iks(x))
})

test_that("iks is batch-invariant", {
  set.seed(6); s <- tibble::tibble(value = c(stats::rnorm(600), stats::rnorm(600, 1)))
  f0 <- fit(drift_detector("iks"), s[1:150, ], signal = value)
  expect_identical(advance(f0, s[151:1200, ])$history,
                   advance(advance(f0, s[151:555, ]), s[556:1200, ])$history)
})

test_that("iks rejects a window too small to ever reject", {
  expect_error(drift_detector("iks", window_size = 7), "window_size")
  expect_no_error(drift_detector("iks", window_size = 8))
})
