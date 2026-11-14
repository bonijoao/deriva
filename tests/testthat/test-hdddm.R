test_that("hdddm_distance is 0 for proportional histograms and sqrt(2) for disjoint ones", {
  expect_equal(hdddm_distance(c(1, 2, 3), c(2, 4, 6)), 0)
  expect_equal(hdddm_distance(c(5, 0), c(0, 7)), sqrt(2))
  expect_equal(hdddm_distance(c(1, 1), c(1, 0)),
               sqrt((sqrt(0.5) - 1)^2 + 0.5))
})

test_that("hdddm bins absorb out-of-range and infinite values", {
  e <- hdddm_edges(c(0, 10), 5)
  expect_equal(e, seq(0, 10, by = 2))
  expect_identical(hdddm_counts(c(-Inf, -3, 1, 9.9, 10, 50, Inf), e), c(3L, 0L, 0L, 0L, 4L))
  expect_equal(hdddm_edges(c(3, 3, 3), 4), seq(2.5, 3.5, length.out = 5))
})

test_that("hdddm_edges copes with a batch without finite values", {
  expect_equal(hdddm_edges(c(Inf, -Inf), 2), c(-0.5, 0, 0.5))
})
