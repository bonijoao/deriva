test_that("detect_drift() annotates a tibble end-to-end", {
  # seed = 2 is a CLEAN DDM story (verified against datadriftR): no false
  # positive before the true drift point, first drift at 542. seed = 42 is
  # NOT clean (DDM and datadriftR both flag 49 and 388), so it is reserved
  # for the golden test rather than the "clean detection" assertion.
  s <- sim_drift_stream(seed = 2) # 500 + 500, p 0.05 -> 0.30
  res <- detect_drift(s, .col = error, method = "ddm")
  expect_s3_class(res, "tbl_df")
  expect_identical(nrow(res), nrow(s))
  expect_true(all(c(".warning", ".drift") %in% names(res)))
  first_drift <- which(res$.drift)[1]
  expect_gt(first_drift, 500)          # not before the true drift point
  expect_false(any(res$.drift[31:500], na.rm = TRUE)) # no false positive
})

test_that("detect_drift() forwards hyperparameters", {
  s <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
  res <- detect_drift(s, .col = error, method = "ddm", min_instances = 60)
  expect_true(all(is.na(res$.drift[1:58]))) # obs 59 is the first evaluated (count = 60)
})

test_that("detect_drift() validates inputs like fit()", {
  expect_error(detect_drift(tibble::tibble(x = 0.5), .col = x), "0/1")
})
