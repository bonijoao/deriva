test_that("hdddm_distance is 0 for proportional histograms and sqrt(2) for disjoint ones", {
  expect_equal(hdddm_distance(c(1, 2, 3), c(2, 4, 6)), 0)
  expect_equal(hdddm_distance(c(5, 0), c(0, 7)), sqrt(2))
  expect_equal(hdddm_distance(c(1, 1), c(1, 0)),
               sqrt((sqrt(0.5) - 1)^2 + 0.5))
})

test_that("hdddm bins absorb out-of-range and infinite values", {
  e <- hdddm_edges(c(0, 10), 5)
  expect_equal(e, seq(0, 10, by = 2))
  expect_identical(hdddm_counts(c(-Inf, -3, 1, 9.9, 10, 50, Inf), e), c(3L, 0L, 0L, 0L, 4L))
  expect_equal(hdddm_edges(c(3, 3, 3), 4), seq(2.5, 3.5, length.out = 5))
})

test_that("hdddm_edges copes with a batch without finite values", {
  expect_equal(hdddm_edges(c(Inf, -Inf), 2), c(-0.5, 0, 0.5))
})

run_hd <- function(x, ...) detect_drift(tibble::tibble(value = x), .col = value, method = "hdddm", ...)

test_that("hdddm is registered with its defaults", {
  m <- drift_method("hdddm")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params, list(batch_size = 100, gamma = 1))
})

test_that("hdddm is NA until its first test at observation 400", {
  set.seed(1); r <- run_hd(stats::rnorm(600))
  expect_true(all(is.na(r$.drift[1:399])))
  expect_false(is.na(r$.drift[400]))
  expect_true(all(is.na(r$.warning)))
})

test_that("hdddm detects a mean shift and a variance shift", {
  set.seed(2); r <- run_hd(c(stats::rnorm(1000), stats::rnorm(600, 3)))
  expect_true(any(r$.drift[1001:1600], na.rm = TRUE))
  set.seed(3); r <- run_hd(c(stats::rnorm(1000), stats::rnorm(600, 0, 4)))
  expect_true(any(r$.drift[1001:1600], na.rm = TRUE))
})

test_that("hdddm re-warms for three batches after a drift", {
  set.seed(4); r <- run_hd(c(stats::rnorm(800), stats::rnorm(800, 5)))
  hit <- which(r$.drift)[1]
  expect_false(is.na(hit))
  expect_equal(hit %% 100, 0)                                   # flags change on batch ends
  expect_true(all(is.na(r$.drift[(hit + 1):(hit + 299)])))
  expect_false(is.na(r$.drift[hit + 300]))
})

test_that("hdddm survives a constant stream and infinite values", {
  expect_false(any(run_hd(rep(1, 1000))$.drift, na.rm = TRUE))
  set.seed(5); x <- stats::rnorm(1000); x[c(150, 650)] <- c(Inf, -Inf)
  expect_no_error(run_hd(x))
})

test_that("hdddm is batch-invariant", {
  set.seed(6); s <- tibble::tibble(value = c(stats::rnorm(900), stats::rnorm(900, 2)))
  f0 <- fit(drift_detector("hdddm"), s[1:250, ], signal = value)
  expect_identical(advance(f0, s[251:1800, ])$history,
                   advance(advance(f0, s[251:1111, ]), s[1112:1800, ])$history)
})

test_that("hdddm rebuilds its bins after a drift and sees a second shift", {
  # with bins fixed by the first batch the second shift was never seen (0 of 50 seeds)
  set.seed(4); r <- run_hd(c(stats::rnorm(1000), stats::rnorm(1050, 10), stats::rnorm(1000, 20)))
  expect_true(any(r$.drift[1001:2050], na.rm = TRUE))
  expect_true(any(r$.drift[2051:3050], na.rm = TRUE))
})
