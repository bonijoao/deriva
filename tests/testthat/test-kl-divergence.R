test_that("kl_cells bisects the reference range like a 1-D kdq-tree", {
  ref <- c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 2^-10), c(-Inf, 0.25, 0.5, Inf))
})

test_that("kl_cells works on the original scale", {
  ref <- 10 + 2 * c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 2^-10), c(-Inf, 10.5, 11, Inf))
})

test_that("kl_cells stops splitting at the minimum cell width", {
  ref <- c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 0.6), c(-Inf, 0.5, Inf))
})

test_that("a constant reference gets a cell of its own", {
  b <- kl_cells(rep(3, 5), 4, 2^-10)
  expect_length(b, 4)
  expect_identical(kl_counts(3, b), c(0L, 1L, 0L))
  expect_identical(kl_counts(c(2.9, 3.1), b), c(1L, 0L, 1L))
})

test_that("values outside the reference range land in the outer cells", {
  b <- kl_cells(c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0), 4, 2^-10)
  expect_identical(kl_counts(c(-100, 100), b), c(1L, 0L, 1L))
})

test_that("kl_kt_divergence matches a hand computation", {
  expect_equal(kl_kt_divergence(c(2L, 0L), c(0L, 2L)), (2 / 3) * log2(5))
  expect_equal(kl_kt_divergence(c(3L, 1L), c(3L, 1L)), 0)
})

test_that("kl_bootstrap returns a positive threshold on a continuous reference", {
  set.seed(1); ref <- stats::rnorm(200)
  b <- kl_cells(ref, 20, 2^-10)
  set.seed(2); d <- kl_bootstrap(ref, b, 500, 0.01)
  expect_true(is.numeric(d) && length(d) == 1 && d > 0)
})

run_kl <- function(x, seed = 1, ...) {
  detect_drift(tibble::tibble(value = x), .col = value, method = "kl_divergence",
               seed = seed, ...)
}

test_that("kl_divergence is registered with the paper's defaults", {
  m <- drift_method("kl_divergence")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params, list(window_size = 200, max_cell_points = 20,
    min_cell_width = 2^-10, alpha = 0.01, persistence = 0.05, n_boot = 500))
})

test_that("kl_divergence is NA until both windows are full", {
  set.seed(3); r <- run_kl(stats::rnorm(600))
  expect_true(all(is.na(r$.drift[1:399])))
  expect_false(is.na(r$.drift[400]))
  expect_true(all(is.na(r$.warning)))
})

test_that("kl_divergence detects a mean shift and a variance shift", {
  set.seed(4); r <- run_kl(c(stats::rnorm(600), stats::rnorm(600, 2)))
  expect_true(any(r$.drift[601:900], na.rm = TRUE))
  set.seed(5); r <- run_kl(c(stats::rnorm(600), stats::rnorm(600, sd = 3)))
  expect_true(any(r$.drift[601:1000], na.rm = TRUE))
})

test_that("kl_divergence stays quiet on a stationary stream", {
  set.seed(6); r <- run_kl(stats::rnorm(800), seed = 6)
  expect_false(any(r$.drift, na.rm = TRUE))
})

test_that("kl_divergence re-warms after a drift and survives a short tail", {
  set.seed(7); x <- c(stats::rnorm(600), stats::rnorm(150, 3))
  r <- run_kl(x)
  hit <- which(r$.drift)[1]
  expect_false(is.na(hit))
  expect_true(all(is.na(r$.drift[(hit + 1):length(x)])))
})

test_that("kl_divergence is reproducible and batch-invariant under a seed", {
  set.seed(8); s <- tibble::tibble(value = c(stats::rnorm(500), stats::rnorm(500, 1.5)))
  expect_identical(run_kl(s$value, seed = 9)$.drift, run_kl(s$value, seed = 9)$.drift)
  f0 <- fit(drift_detector("kl_divergence", seed = 9), s[1:300, ], signal = value)
  one <- advance(f0, s[301:1000, ])
  two <- advance(advance(f0, s[301:650, ]), s[651:1000, ])
  expect_identical(one$history, two$history)
  expect_identical(one$rng, two$rng)
})

test_that("kl_divergence needs at least 1 / alpha bootstrap samples", {
  expect_error(drift_detector("kl_divergence", n_boot = 50), "n_boot")
  expect_no_error(drift_detector("kl_divergence", n_boot = 100))
})

test_that("an infinite value in the sliding window does not abort the run", {
  set.seed(10); x <- stats::rnorm(500); x[450] <- Inf
  expect_no_error(run_kl(x))
})

test_that("an infinite value in the reference keeps the detector alive", {
  set.seed(11); x <- c(stats::rnorm(500), stats::rnorm(500, 5))
  x[50] <- Inf
  expect_true(any(run_kl(x)$.drift[501:800], na.rm = TRUE))
  x[50] <- -Inf
  expect_true(any(run_kl(x)$.drift[501:800], na.rm = TRUE))
})

test_that("kl_cells survives a reference range that overflows", {
  b <- kl_cells(c(-1e308, -1, 0, 1, 1e308), 2, 2^-10)
  inner <- b[-c(1, length(b))]
  expect_gt(length(inner), 0)
  expect_true(all(is.finite(inner)))
})

test_that("max_cell_points above window_size is refused, since no cell could split", {
  expect_error(drift_detector("kl_divergence", max_cell_points = 500), "max_cell_points")
  expect_error(drift_detector("kl_divergence", window_size = 15), "max_cell_points")
  expect_no_error(drift_detector("kl_divergence", max_cell_points = 200))
})
