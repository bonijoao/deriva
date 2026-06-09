dummy_method <- list(
  name = "dummy",
  init = function(params) list(count = 0),
  step = function(state, obs) {
    state$count <- state$count + 1
    list(state = state, signal = list(warning = obs > 5, drift = obs > 10))
  },
  signal_type = "error",
  params = list(),
  meta = list()
)

test_that("run_engine() folds state and collects signals", {
  out <- run_engine(dummy_method, dummy_method$init(list()), c(1, 6, 11))
  expect_named(out, c("state", "signals"))
  expect_identical(out$state$count, 3)
  expect_s3_class(out$signals, "tbl_df")
  expect_identical(out$signals$.warning, c(FALSE, TRUE, TRUE))
  expect_identical(out$signals$.drift, c(FALSE, FALSE, TRUE))
})

test_that("run_engine() on empty input returns state unchanged and 0-row tibble", {
  st <- dummy_method$init(list())
  out <- run_engine(dummy_method, st, numeric(0))
  expect_identical(out$state, st)
  expect_identical(nrow(out$signals), 0L)
})

test_that("run_engine() preserves NA signals (warm-up contract)", {
  na_method <- dummy_method
  na_method$step <- function(state, obs) list(state = state, signal = list(warning = NA, drift = NA))
  out <- run_engine(na_method, list(), c(1, 2))
  expect_identical(out$signals$.warning, c(NA, NA))
  expect_identical(out$signals$.drift, c(NA, NA))
})
