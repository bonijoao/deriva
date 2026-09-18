spec_with <- function(method, nm, value) {
  do.call(drift_detector, c(list(method), stats::setNames(list(value), nm)))
}

test_that("every registered method declares one check per parameter", {
  for (m in the$methods) {
    expect_setequal(names(m$checks), names(m$params))
  }
})

test_that("every method's defaults pass its own validation", {
  for (name in names(the$methods)) {
    expect_no_error(drift_detector(name))
  }
})

test_that("no hyperparameter accepts an invalid value (diagnostic finding A)", {
  bad_numeric <- list("abc", -1, NA_real_, c(1, 2), NULL)
  bad_flag <- list("abc", NA, c(TRUE, FALSE), NULL)
  for (name in names(the$methods)) {
    defaults <- the$methods[[name]]$params
    for (nm in names(defaults)) {
      bad <- if (is.logical(defaults[[nm]])) bad_flag else bad_numeric
      for (value in bad) {
        expect_error(spec_with(name, nm, value), class = "deriva_error_invalid_param")
      }
    }
  }
})

test_that("values outside the parameter space are rejected, not run", {
  expect_error(drift_detector("kswin", alpha = 5), "`alpha` must be a number in \\(0, 1\\)")
  expect_error(drift_detector("mddm_a", window_size = 0), "`window_size`")
  expect_error(drift_detector("fhddm", delta = -1), "`delta`")
  expect_error(drift_detector("hddm_a", two_side_option = "yes"), "TRUE or FALSE")
})

test_that("joint constraints catch combinations that crash the engine", {
  expect_error(drift_detector("kswin", window_size = 31, stat_size = 30),
               "Invalid parameter combination")
  expect_no_error(drift_detector("kswin", window_size = 32, stat_size = 30))
  expect_error(drift_detector("fhddms", short_size = 200), "`short_size`")
  expect_error(drift_detector("ddm", warning_level = 4), "`warning_level`")
  expect_error(drift_detector("stepd", out_control_level = 0.5), "`out_control_level`")
  expect_error(drift_detector("rddm", min_concept = 50000), "`min_concept`")
})

test_that("method must be a single string", {
  expect_error(drift_detector(data.frame(x = 1)), "`method` must be a single string")
  expect_error(drift_detector(c("ddm", "eddm")), "`method` must be a single string")
})

test_that("mddm_g and mddm_e reject values that overflow the weights", {
  expect_error(drift_detector("mddm_g", r = 1e5), class = "deriva_error_invalid_param")
  expect_error(drift_detector("mddm_e", lambda = 1000), class = "deriva_error_invalid_param")
  expect_no_error(drift_detector("mddm_g"))
  expect_no_error(drift_detector("mddm_e"))
})
