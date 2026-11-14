test_that("iks_c reproduces the Smirnov table", {
  expect_equal(round(iks_c(c(0.10, 0.05, 0.01, 0.001)), 2), c(1.22, 1.36, 1.63, 1.95))
})

test_that("iks_d is the two-sample KS statistic, ties included", {
  set.seed(1); a <- round(stats::rnorm(100), 1); b <- round(stats::rnorm(100, 0.3), 1)
  expect_equal(iks_d(sort(a), b), unname(suppressWarnings(stats::ks.test(a, b))$statistic))
  expect_equal(iks_d(sort(c(1, 2, 3)), c(1, 2, 3)), 0)
  expect_equal(iks_d(sort(c(-Inf, 0, 1)), c(2, 3, Inf)), 1)
})
