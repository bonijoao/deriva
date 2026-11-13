test_that("seqdrift1_epsilon is Theorem 1 of Pears et al. (2014)", {
  L <- log(4 / (0.01 / (2 * (1 - 0.5^1))))
  expect_equal(seqdrift1_epsilon(200, 0.25, 0.01, 1),
               2 / (3 * 200) * (L + sqrt(L^2 + 18 * 0.25 * 200 * L)))
  L3 <- log(4 / (0.1 / (2 * (1 - 0.5^3))))
  expect_equal(seqdrift1_epsilon(400, 0.05, 0.1, 3),
               2 / (3 * 400) * (L3 + sqrt(L3^2 + 18 * 0.05 * 400 * L3)))
})

test_that("seqdrift1_epsilon is finite and positive at zero variance", {
  e <- seqdrift1_epsilon(200, 0, 0.01, 1)
  expect_true(is.finite(e) && e > 0)
})
