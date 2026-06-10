test_that("HDDM_W matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "hddm-w-golden.csv"))
  res <- detect_drift(tibble::tibble(error = golden$error), .col = error, method = "hddm_w")
  expect_identical(which(res$.drift), which(golden$drift))
  expect_identical(which(res$.warning), which(golden$warning))
})
