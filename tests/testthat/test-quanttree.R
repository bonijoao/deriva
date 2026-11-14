test_that("quanttree bins hold exactly L_k training values", {
  set.seed(1); tr <- stats::rnorm(512)
  cuts <- qt_cuts(tr, 16)
  expect_identical(qt_counts(tr, cuts), rep(32L, 16))
  expect_identical(qt_sizes(100, 3), c(33L, 33L, 34L))
  expect_identical(qt_counts(c(-Inf, Inf), cuts)[c(1, 16)], c(1L, 1L))
})

test_that("qt_pearson is Eq. 6", {
  expect_equal(qt_pearson(c(2, 2, 2, 2), rep(4L, 4), 16), 0)
  expect_equal(qt_pearson(c(8, 0, 0, 0), rep(4L, 4), 16), (6^2 + 3 * 2^2) / 2)
})

test_that("qt_threshold reproduces Table 1 of Boracchi et al. (2018)", {
  set.seed(2)
  expect_equal(qt_threshold(4096, 32, 64, 0.05, 2e5), 46)
  expect_equal(qt_threshold(4096, 32, 64, 0.01, 2e5), 54)
})

test_that("qt_threshold agrees with the literal Algorithm 2", {
  set.seed(3)
  lit <- replicate(20000, {
    tr <- stats::runif(256); cuts <- qt_cuts(tr, 8)
    qt_pearson(qt_counts(stats::runif(32), cuts), qt_sizes(256, 8), 256)
  })
  ts <- sort(lit); tau_lit <- min(ts[vapply(ts, function(s) sum(lit > s), 1) <= 0.05 * 20000])
  set.seed(4)
  expect_equal(qt_threshold(256, 8, 32, 0.05, 1e5), tau_lit, tolerance = 0.1)
})
