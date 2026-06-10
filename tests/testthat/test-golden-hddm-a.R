test_that("HDDM_A matches datadriftR golden output exactly", {
  golden <- utils::read.csv(test_path("fixtures", "hddm-a-golden.csv"))
  res <- detect_drift(tibble::tibble(error = golden$error), .col = error, method = "hddm_a")
  expect_identical(which(res$.drift), which(golden$drift))
  expect_identical(which(res$.warning), which(golden$warning))
})
