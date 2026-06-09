test_that("KSWIN matches datadriftR golden output exactly (same seed)", {
  golden <- utils::read.csv(test_path("fixtures", "kswin-golden.csv"))
  set.seed(123L)  # MUST match GOLDEN_SEED in data-raw/golden-kswin.R
  res <- detect_drift(tibble::tibble(value = golden$value), .col = value, method = "kswin")
  expect_identical(which(res$.drift), which(golden$drift))
})
