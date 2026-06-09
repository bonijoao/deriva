make_fit <- function() {
  base <- sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)
  fit(drift_detector("ddm"), base, signal = error)
}

test_that("advance() returns a NEW fit with appended history", {
  f0 <- make_fit()
  batch <- sim_drift_stream(n_pre = 0, n_post = 50, p_post = 0.05, seed = 2)
  f1 <- advance(f0, batch)
  expect_s3_class(f1, "drift_detector_fit")
  expect_identical(nrow(f1$history), 150L)
  expect_identical(nrow(f0$history), 100L) # f0 untouched (immutability)
  expect_true(all(f1$history$.phase[101:150] == "stream"))
})

test_that("advancing in two batches equals advancing once (fold property)", {
  f0 <- make_fit()
  stream <- sim_drift_stream(n_pre = 0, n_post = 400, p_post = 0.3, seed = 3)
  one <- advance(f0, stream)
  two <- advance(advance(f0, stream[1:200, ]), stream[201:400, ])
  expect_identical(one$history, two$history)
  expect_identical(one$state, two$state)
})

test_that("batch of size 1 works (stream mode)", {
  f0 <- make_fit()
  f1 <- advance(f0, tibble::tibble(t = 101L, error = 1, drift_true = TRUE))
  expect_identical(nrow(f1$history), 101L)
})

test_that("advance() validates the signal column in new_data", {
  f0 <- make_fit()
  expect_error(advance(f0, tibble::tibble(x = 1)), "not found")
})
