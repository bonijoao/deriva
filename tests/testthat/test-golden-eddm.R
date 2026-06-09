test_that("EDDM matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "eddm-golden.csv"))
  res <- detect_drift(tibble::tibble(error = golden$error), .col = error, method = "eddm")
  expect_identical(which(res$.drift), which(golden$drift))
  expect_identical(which(res$.warning), which(golden$warning))
})
