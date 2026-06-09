test_that("drift_detector() builds a spec with method defaults", {
  spec <- drift_detector("ddm")
  expect_s3_class(spec, "drift_detector")
  expect_identical(spec$method, "ddm")
  expect_identical(spec$params$min_instances, 30)
})

test_that("drift_detector() lets the user override params", {
  spec <- drift_detector("ddm", min_instances = 50)
  expect_identical(spec$params$min_instances, 50)
  expect_identical(spec$params$warning_level, 2) # untouched default
})

test_that("drift_detector() rejects unknown params and methods", {
  expect_error(drift_detector("ddm", banana = 1), "banana")
  expect_error(drift_detector("nope"), "Unknown drift detection method")
})

test_that("print.drift_detector shows method and params", {
  expect_output(print(drift_detector("ddm")), "ddm")
  expect_output(print(drift_detector("ddm")), "min_instances")
})
