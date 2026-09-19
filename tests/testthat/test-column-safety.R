base <- function() sim_drift_stream(n_pre = 100, n_post = 0, seed = 1)

test_that("data that already has deriva's columns is refused, not overwritten", {
  clash <- base(); clash$.drift <- "mine"
  expect_error(detect_drift(clash, .col = error), class = "deriva_error_reserved_column")
  expect_error(fit(drift_detector("ddm"), clash, signal = error),
               class = "deriva_error_reserved_column")
  f <- fit(drift_detector("ddm"), base(), signal = error)
  expect_error(advance(f, clash), class = "deriva_error_reserved_column")
  expect_error(augment(f, clash), class = "deriva_error_reserved_column")
  phase <- base(); phase$.phase <- "x"
  expect_error(fit(drift_detector("ddm"), phase, signal = error), "\\.phase")
  expect_no_error(detect_drift(phase, .col = error))
})

test_that("advance() refuses a batch whose columns differ from the baseline's", {
  f <- fit(drift_detector("ddm"), base(), signal = error)
  expect_error(advance(f, data.frame(error = c(0, 1), outra = 1:2)),
               class = "deriva_error_batch_columns")
  expect_error(advance(f, data.frame(error = c(0, 1), outra = 1:2)), "outra")
  expect_error(advance(f, base()[, c("t", "error")]), "drift_true")
  reordered <- base()[, c("drift_true", "error", "t")]
  expect_identical(nrow(advance(f, reordered)$history), 200L)
})

test_that("the schema check also holds when no history rows are kept", {
  f <- suppressWarnings(fit(drift_detector("ddm", keep = 0), base(), signal = error))
  expect_error(advance(f, data.frame(error = 1)), class = "deriva_error_batch_columns")
  expect_identical(advance(f, base())$counts$n_obs, 200L)
})
