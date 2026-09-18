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

test_that("keep defaults to 10000 and is validated", {
  expect_identical(drift_detector("ddm")$keep, 10000)
  for (bad in list(-1, 2.5, "a", NA_real_, c(1, 2), NULL)) {
    expect_error(drift_detector("ddm", keep = bad), class = "deriva_error_invalid_param")
  }
})

test_that("keep = Inf and keep = 0 warn once, when the spec is created", {
  expect_warning(spec_inf <- drift_detector("ddm", keep = Inf), class = "deriva_warning_keep_inf")
  expect_warning(spec_zero <- drift_detector("ddm", keep = 0), class = "deriva_warning_keep_zero")
  expect_no_warning(drift_detector("ddm", keep = 500))
  base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
  expect_no_warning(f <- fit(spec_inf, base, signal = error))
  expect_no_warning(advance(f, base))
})

test_that("history holds only the last `keep` rows; totals stay exact", {
  full <- suppressWarnings(drifted_fit(keep = Inf))
  short <- drifted_fit(keep = 50)
  expect_identical(nrow(short$history), 50L)
  expect_identical(short$history, full$history[551:600, ])
  expect_identical(tidy(short), tidy(full))
  expect_identical(glance(short), glance(full))
  expect_identical(short$state, full$state)
})

test_that("keep also bounds the baseline stored by fit()", {
  base <- sim_drift_stream(n_pre = 200, n_post = 0, seed = 2)
  f <- fit(drift_detector("ddm", keep = 30), base, signal = error)
  expect_identical(nrow(f$history), 30L)
  expect_identical(f$counts$n_baseline, 200L)
})

test_that("keep = 0 stores no rows but keeps the columns", {
  f <- suppressWarnings(drifted_fit(keep = 0))
  expect_identical(nrow(f$history), 0L)
  expect_true(all(c("error", ".warning", ".drift", ".phase") %in% names(f$history)))
  expect_identical(glance(f)$n_obs, 600L)
})

test_that("history size no longer grows with the stream (no O(N^2))", {
  f <- fit(drift_detector("ddm", keep = 100),
           sim_drift_stream(n_pre = 100, n_post = 0, seed = 1), signal = error)
  one <- tibble::tibble(t = 1L, error = 0, drift_true = FALSE)
  for (i in 1:300) f <- advance(f, one)
  expect_identical(nrow(f$history), 100L)
  expect_identical(f$counts$n_obs, 400L)
})

test_that("batching does not change a truncated history", {
  f0 <- fit(drift_detector("ddm", keep = 120),
            sim_drift_stream(n_pre = 100, n_post = 0, seed = 1), signal = error)
  stream <- sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.3, seed = 3)
  one <- advance(f0, stream)
  two <- advance(advance(f0, stream[1:200, ]), stream[201:400, ])
  expect_identical(one$history, two$history)
})

test_that("autoplot() uses absolute positions on a truncated history", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::autoplot(drifted_fit(keep = 50))
  expect_s3_class(p, "ggplot")
  expect_equal(range(p$data$index), c(551, 600))
  expect_error(ggplot2::autoplot(suppressWarnings(drifted_fit(keep = 0))), "keep = 0")
})
