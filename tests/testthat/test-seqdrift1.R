test_that("seqdrift1_epsilon is Theorem 1 of Pears et al. (2014)", {
  L <- log(4 / (0.01 / (2 * (1 - 0.5^1))))
  expect_equal(seqdrift1_epsilon(200, 0.25, 0.01, 1),
               2 / (3 * 200) * (L + sqrt(L^2 + 18 * 0.25 * 200 * L)))
  L3 <- log(4 / (0.1 / (2 * (1 - 0.5^3))))
  expect_equal(seqdrift1_epsilon(400, 0.05, 0.1, 3),
               2 / (3 * 400) * (L3 + sqrt(L3^2 + 18 * 0.05 * 400 * L3)))
})

test_that("seqdrift1_epsilon is finite and positive at zero variance", {
  e <- seqdrift1_epsilon(200, 0, 0.01, 1)
  expect_true(is.finite(e) && e > 0)
})

run_sd1 <- function(x, ...) detect_drift(tibble::tibble(value = x), .col = value,
                                         method = "seqdrift1", ...)

test_that("seqdrift1 is registered with MOA's defaults", {
  m <- drift_method("seqdrift1")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params, list(delta = 0.01, delta_warning = 0.1, block_size = 200))
})

test_that("seqdrift1 is NA until its first test at observation 400", {
  set.seed(1); r <- run_sd1(stats::rbinom(600, 1, 0.05))
  expect_true(all(is.na(r$.drift[1:399])) && all(is.na(r$.warning[1:399])))
  expect_false(is.na(r$.drift[400]) || is.na(r$.warning[400]))
})

test_that("seqdrift1 detects an error-rate jump and stays quiet before it", {
  set.seed(2); x <- c(stats::rbinom(1000, 1, 0.05), stats::rbinom(1000, 1, 0.30))
  r <- run_sd1(x)
  expect_false(any(r$.drift[1:1000], na.rm = TRUE))
  expect_true(any(r$.drift[1001:1400], na.rm = TRUE))
})

test_that("seqdrift1 raises a warning on a gradual ramp before its first drift", {
  set.seed(4); p <- c(rep(0.05, 800), seq(0.05, 0.35, length.out = 1200))
  r <- run_sd1(stats::rbinom(length(p), 1, p))
  d <- which(r$.drift)[1]; w <- which(r$.warning)[1]
  expect_false(is.na(w))
  expect_false(is.na(d))
  expect_true(w <= d)
})

test_that("seqdrift1 re-warms for one block after a drift", {
  set.seed(4); r <- run_sd1(c(stats::rbinom(600, 1, 0.05), stats::rbinom(600, 1, 0.6)))
  hit <- which(r$.drift)[1]
  expect_false(is.na(hit))
  expect_true(all(is.na(r$.drift[(hit + 1):(hit + 199)])))
  expect_true(all(is.na(r$.warning[(hit + 1):(hit + 199)])))
  expect_false(is.na(r$.drift[hit + 200]))
})

test_that("a never-resolving warning keeps the windows bounded and testing", {
  m <- drift_method("seqdrift1"); p <- m$params
  p$delta <- 0.01; p$delta_warning <- 0.5; p$block_size <- 10
  cap <- floor(1 / p$delta) * p$block_size                     # 1000
  left <- rep(c(rep(1, 3), rep(0, 7)), cap / 10)               # mean 0.30
  feed <- rep(c(rep(1, 39), rep(0, 61)), 60)                   # mean 0.39
  # precondition: a 0.09 gap at the cap sits between the two thresholds
  v <- stats::var(c(left, feed[seq_len(cap)]))
  expect_gt(0.09, seqdrift1_epsilon(cap, v, p$delta_warning, 1e6))
  expect_lt(0.09, seqdrift1_epsilon(cap, v, p$delta, 1))
  s <- m$init(p)
  s$left <- left; s$sample_size <- cap; s$warning <- TRUE; s$judging <- TRUE
  w <- d <- logical(length(feed))
  for (i in seq_along(feed)) {
    o <- m$step(s, feed[i]); s <- o$state
    w[i] <- o$signal$warning; d[i] <- o$signal$drift
  }
  expect_true(all(w))
  expect_false(any(d))
  expect_identical(s$sample_size, cap)
  expect_lte(length(s$right), cap)
  expect_gt(s$num_tests, 100)                                  # still testing every block
})

test_that("seqdrift1 stays quiet on a constant stream", {
  r <- run_sd1(rep(0, 1000))
  expect_false(any(r$.drift, na.rm = TRUE))
  expect_false(any(r$.warning, na.rm = TRUE))
})

test_that("seqdrift1 is batch-invariant", {
  set.seed(6)
  s <- tibble::tibble(value = c(stats::rbinom(700, 1, 0.05), stats::rbinom(700, 1, 0.4)))
  f0 <- fit(drift_detector("seqdrift1"), s[1:300, ], signal = value)
  expect_identical(advance(f0, s[301:1400, ])$history,
                   advance(advance(f0, s[301:777, ]), s[778:1400, ])$history)
})

test_that("delta must be below delta_warning", {
  expect_error(drift_detector("seqdrift1", delta = 0.2), "delta_warning")
  expect_no_error(drift_detector("seqdrift1", delta = 0.05))
})

test_that("seqdrift1 ignores infinite values in its means instead of failing", {
  set.seed(7); x <- stats::rbinom(1200, 1, 0.1); x[c(100, 300)] <- c(Inf, -Inf)
  r <- expect_no_error(run_sd1(x))
  expect_false(any(r$.drift, na.rm = TRUE))
  expect_false(is.na(r$.drift[400]))
})
