test_that("DDM matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "ddm-golden.csv"))
  res <- detect_drift(
    tibble::tibble(error = golden$error),
    .col = error, method = "ddm"
  )
  # warm-up NAs in deriva map to FALSE in datadriftR; compare flag POSITIONS
  expect_identical(which(res$.drift), which(golden$drift))
  expect_identical(which(res$.warning), which(golden$warning))
})
