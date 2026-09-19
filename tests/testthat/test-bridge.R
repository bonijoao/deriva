test_that("classification: .error = 0/1 mismatch, default estimate .pred_class", {
  d <- tibble::tibble(
    truth = factor(c("a", "b", "a")),
    .pred_class = factor(c("a", "a", "a"))
  )
  out <- add_prediction_error(d, truth = truth)
  expect_identical(out$.error, c(0L, 1L, 0L))
})

test_that("regression: .error = absolute error, default estimate .pred", {
  d <- tibble::tibble(truth = c(1, 2, 3), .pred = c(1, 1, 5))
  out <- add_prediction_error(d, truth = truth)
  expect_identical(out$.error, c(0, 1, 2))
})

test_that("explicit estimate column works", {
  d <- tibble::tibble(y = c(1, 2), yhat = c(2, 2))
  out <- add_prediction_error(d, truth = y, estimate = yhat)
  expect_identical(out$.error, c(1, 0))
})

test_that("clear errors on missing columns", {
  d <- tibble::tibble(truth = c(1, 2))
  expect_error(add_prediction_error(d, truth = truth), ".pred")
  expect_error(add_prediction_error(d, truth = nope), "not found")
})

test_that("the tidymodels bridge runs end to end", {
  d <- tibble::tibble(truth = factor(c("a", "b", "a")), .pred_class = factor(c("a", "a", "a")))
  f <- fit(drift_detector("ddm"), add_prediction_error(d, truth = truth), signal = .error)
  expect_s3_class(f, "drift_detector_fit")
  r <- tibble::tibble(truth = c(1, 2, 3), .pred = c(1, 1, 5))
  expect_s3_class(
    fit(drift_detector("page_hinkley"), add_prediction_error(r, truth = truth), signal = .error),
    "drift_detector_fit"
  )
})
