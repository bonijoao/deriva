test_that("register_drift_method() stores and drift_method() retrieves", {
  register_drift_method(
    name = "dummy-reg",
    init = function(params) list(n = 0),
    step = function(state, obs) list(state = state, signal = list(warning = FALSE, drift = FALSE)),
    signal_type = "error",
    params = list(threshold = 1),
    meta = list(full_name = "Dummy", reference = "none")
  )
  m <- drift_method("dummy-reg")
  expect_named(m, c("name", "init", "step", "signal_type", "params", "meta"))
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$threshold, 1)
  the$methods[["dummy-reg"]] <- NULL
})

test_that("drift_method() errors clearly on unknown method", {
  expect_error(drift_method("nope"), "Unknown drift detection method")
})

test_that("register_drift_method() validates signal_type", {
  expect_error(
    register_drift_method("bad", init = identity, step = identity,
                          signal_type = "banana", params = list(), meta = list()),
    "signal_type"
  )
})
