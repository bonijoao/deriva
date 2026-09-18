drifted_fit <- function(...) {
  base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
  f0 <- fit(drift_detector("ddm", ...), base, signal = error)
  advance(f0, sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.5, seed = 2))
}

test_that("the fit carries running totals that match its full history", {
  f <- drifted_fit()
  h <- f$history
  expect_identical(f$counts$n_obs, 600L)
  expect_identical(f$counts$n_baseline, 200L)
  expect_identical(f$counts$n_warning, sum(h$.warning, na.rm = TRUE))
  idx <- which(!is.na(h$.drift) & h$.drift)
  expect_identical(f$drifts, tibble::tibble(index = idx, phase = h$.phase[idx]))
})

test_that("tidy() and glance() read the totals, not the history", {
  f <- drifted_fit()
  expected_tidy <- tidy(f)
  expected_glance <- glance(f)
  f$history <- f$history[0, ]
  expect_identical(tidy(f), expected_tidy)
  expect_identical(glance(f), expected_glance)
  expect_output(print(f), "observations: 600 \\(200 baseline\\)")
})

test_that("a fit serialised by deriva 0.1.0 fails loudly", {
  f <- drifted_fit()
  f$counts <- NULL
  expect_error(advance(f, sim_drift_stream(n_pre = 0, n_post = 5, seed = 1)), "Refit")
  expect_error(glance(f), "Refit")
})
