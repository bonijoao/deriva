test_that("kl_cells bisects the reference range like a 1-D kdq-tree", {
  ref <- c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 2^-10), c(-Inf, 0.25, 0.5, Inf))
})

test_that("kl_cells works on the original scale", {
  ref <- 10 + 2 * c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 2^-10), c(-Inf, 10.5, 11, Inf))
})

test_that("kl_cells stops splitting at the minimum cell width", {
  ref <- c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0)
  expect_equal(kl_cells(ref, 4, 0.6), c(-Inf, 0.5, Inf))
})

test_that("a constant reference gets a cell of its own", {
  b <- kl_cells(rep(3, 5), 4, 2^-10)
  expect_length(b, 4)
  expect_identical(kl_counts(3, b), c(0L, 1L, 0L))
  expect_identical(kl_counts(c(2.9, 3.1), b), c(1L, 0L, 1L))
})

test_that("values outside the reference range land in the outer cells", {
  b <- kl_cells(c(0, 0.1, 0.2, 0.3, 0.6, 0.9, 1.0), 4, 2^-10)
  expect_identical(kl_counts(c(-100, 100), b), c(1L, 0L, 1L))
})

test_that("kl_kt_divergence matches a hand computation", {
  expect_equal(kl_kt_divergence(c(2L, 0L), c(0L, 2L)), (2 / 3) * log2(5))
  expect_equal(kl_kt_divergence(c(3L, 1L), c(3L, 1L)), 0)
})

test_that("kl_bootstrap returns a positive threshold on a continuous reference", {
  set.seed(1); ref <- stats::rnorm(200)
  b <- kl_cells(ref, 20, 2^-10)
  set.seed(2); d <- kl_bootstrap(ref, b, 500, 0.01)
  expect_true(is.numeric(d) && length(d) == 1 && d > 0)
})
