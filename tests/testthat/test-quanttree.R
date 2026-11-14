test_that("quanttree bins hold exactly L_k training values", {
  set.seed(1); tr <- stats::rnorm(512)
  cuts <- qt_cuts(tr, 16)
  expect_identical(qt_counts(tr, cuts), rep(32L, 16))
  expect_identical(qt_sizes(100, 3), c(33L, 33L, 34L))
  expect_identical(qt_counts(c(-Inf, Inf), cuts)[c(1, 16)], c(1L, 1L))
})

test_that("qt_pearson is Eq. 6", {
  expect_equal(qt_pearson(c(2, 2, 2, 2), rep(4L, 4), 16), 0)
  expect_equal(qt_pearson(c(8, 0, 0, 0), rep(4L, 4), 16), (6^2 + 3 * 2^2) / 2)
})

test_that("qt_threshold reproduces Table 1 of Boracchi et al. (2018)", {
  set.seed(2)
  expect_equal(qt_threshold(4096, 32, 64, 0.05, 2e5), 46)
  expect_equal(qt_threshold(4096, 32, 64, 0.01, 2e5), 54)
})

test_that("qt_threshold agrees with the literal Algorithm 2", {
  set.seed(3)
  lit <- replicate(20000, {
    tr <- stats::runif(256); cuts <- qt_cuts(tr, 8)
    qt_pearson(qt_counts(stats::runif(32), cuts), qt_sizes(256, 8), 256)
  })
  ts <- sort(lit); tau_lit <- min(ts[vapply(ts, function(s) sum(lit > s), 1) <= 0.05 * 20000])
  set.seed(4)
  expect_equal(qt_threshold(256, 8, 32, 0.05, 1e5), tau_lit, tolerance = 0.1)
})

run_qt <- function(x, ...) detect_drift(tibble::tibble(value = x), .col = value, method = "quanttree", seed = 1, ...)

test_that("quanttree is registered with its defaults", {
  m <- drift_method("quanttree")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params, list(train_size = 512, n_bins = 16, batch_size = 64, alpha = 0.01, n_sim = 1e5))
})

test_that("quanttree is NA until its first batch at observation 576", {
  set.seed(1); r <- run_qt(stats::rnorm(800))
  expect_true(all(is.na(r$.drift[1:575])))
  expect_false(is.na(r$.drift[576]))
  expect_true(all(is.na(r$.warning)))
})

test_that("quanttree detects a mean shift and a variance shift", {
  set.seed(2); r <- run_qt(c(stats::rnorm(700), stats::rnorm(400, 1)))
  expect_true(any(r$.drift[701:1100], na.rm = TRUE))
  set.seed(3); r <- run_qt(c(stats::rnorm(700), stats::rnorm(400, 0, 3)))
  expect_true(any(r$.drift[701:1100], na.rm = TRUE))
})

test_that("quanttree's per-batch false-positive rate is near alpha", {
  set.seed(4); r <- run_qt(stats::rnorm(512 + 64 * 400))
  tested <- r$.drift[seq(576, nrow(r), by = 64)]
  expect_lt(mean(tested, na.rm = TRUE), 0.03)                 # NA: re-warm after an alarm
})

test_that("quanttree re-warms for train_size + batch_size after a drift", {
  set.seed(5); r <- run_qt(c(stats::rnorm(700), stats::rnorm(1400, 4)))
  hit <- which(r$.drift)[1]
  expect_true(all(is.na(r$.drift[(hit + 1):(hit + 575)])))
  expect_false(is.na(r$.drift[hit + 576]))
})

test_that("quanttree is reproducible, batch-invariant, and copes with ties", {
  set.seed(6); s <- tibble::tibble(value = c(stats::rnorm(900), stats::rnorm(900, 1)))
  f0 <- fit(drift_detector("quanttree", seed = 9), s[1:300, ], signal = value)
  expect_identical(advance(f0, s[301:1800, ])$history,
                   advance(advance(f0, s[301:1000, ]), s[1001:1800, ])$history)
  expect_warning(run_qt(stats::rbinom(1200, 1, 0.2)), "tied")   # no error, one warning
})

test_that("quanttree rejects impossible settings", {
  expect_error(drift_detector("quanttree", n_bins = 600), "n_bins")
  expect_error(drift_detector("quanttree", n_sim = 100), "n_sim")
})

test_that("qt_sizes gives every bin at least one training value", {
  for (nk in list(c(1000, 64), c(286, 27), c(300, 40), c(2000, 128), c(16, 16))) {
    L <- qt_sizes(nk[1], nk[2])
    expect_identical(sum(L), as.integer(nk[1]))
    expect_true(all(L >= 1))
    expect_lte(max(L) - min(L), 1L)
  }
  set.seed(8)
  expect_no_error(run_qt(stats::rnorm(1200), train_size = 1000, n_bins = 64, n_sim = 2e4))
})

test_that("quanttree warns once when its training set has ties", {
  set.seed(9)
  expect_warning(r <- run_qt(stats::rbinom(3000, 1, 0.2)), "tied")
  expect_no_warning(run_qt(stats::rnorm(1200)))
  w <- 0
  withCallingHandlers(run_qt(stats::rbinom(3000, 1, 0.2)),
                      warning = function(cnd) { w <<- w + 1; invokeRestart("muffleWarning") })
  expect_identical(w, 1)
})

test_that("qt_threshold scales linearly in the number of bins", {
  skip_on_cran()
  set.seed(10)
  expect_lt(system.time(qt_threshold(4096, 1024, 64, 0.05, 1e4))[["elapsed"]], 5)
})
