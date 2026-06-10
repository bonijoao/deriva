test_that("ADWIN matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "adwin-golden.csv"))
  res <- detect_drift(tibble::tibble(value = golden$value), .col = value, method = "adwin")
  expect_identical(which(res$.drift), which(golden$drift))
})
