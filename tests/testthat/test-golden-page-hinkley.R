test_that("Page-Hinkley matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "page-hinkley-golden.csv"))
  res <- detect_drift(tibble::tibble(value = golden$value), .col = value, method = "page_hinkley")
  expect_identical(which(res$.drift), which(golden$drift))
})
