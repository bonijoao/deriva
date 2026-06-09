kswin_fit <- function(seed = 1) {
  set.seed(seed)
  base <- sim_dist_stream(n_pre = 200, n_post = 0, seed = seed)
  fit(drift_detector("kswin"), base, signal = value)
}

test_that("the full S3 pipeline works UNCHANGED for a distribution method", {
  set.seed(1)
  f0 <- kswin_fit(1)
  expect_s3_class(f0, "drift_detector_fit")
  f1 <- advance(f0, sim_dist_stream(n_pre = 0, n_post = 400, mean_post = 3, seed = 2))
  expect_identical(nrow(f1$history), 600L)
  expect_true(all(is.na(f1$history$.warning)))           # no warning concept
  expect_s3_class(augment(f1), "tbl_df")
  expect_s3_class(tidy(f1), "tbl_df")
  g <- glance(f1)
  expect_identical(g$method, "kswin")
  expect_identical(g$n_warning, 0L)                      # all-NA -> 0
  skip_if_not_installed("ggplot2")
  expect_s3_class(ggplot2::autoplot(f1), "ggplot")
})

test_that("detect_drift() works for kswin", {
  set.seed(1)
  s <- sim_dist_stream(seed = 1)
  res <- detect_drift(s, .col = value, method = "kswin")
  expect_true(all(c(".warning", ".drift") %in% names(res)))
  expect_true(all(is.na(res$.warning)))
})

test_that("distribution methods reject non-numeric signals", {
  expect_error(
    detect_drift(tibble::tibble(v = factor(c("a", "b"))), .col = v, method = "kswin"),
    "numeric"
  )
})
