test_that("optwin_cut falls back to the middle before w_proof", {
  expect_identical(optwin_cut(30, 0.99, 0.5)$cut, 16L)
  expect_identical(optwin_cut(50, 0.99, 0.5)$cut, 26L)
  expect_identical(optwin_cut(100, 0.99, 0.5)$cut, 51L)
  expect_identical(optwin_cut(178, 0.99, 0.5)$cut, 90L)
  # Eq. (2) as printed finds its first root at 179; the authors' code, whose df
  # uses 1/f^2, at 181 (their table: 90, 91, 84 at 179-181)
  expect_identical(optwin_cut(179, 0.99, 0.5)$cut, 82L)
})

test_that("optwin_cut matches the authors' table past w_proof", {
  ref <- c(`182` = 88, `190` = 105, `200` = 120, `300` = 232, `500` = 436, `1000` = 938, `5000` = 4939)
  got <- vapply(as.integer(names(ref)), function(n) optwin_cut(n, 0.99, 0.5)$cut, integer(1))
  expect_true(all(abs(got - ref) <= 2))
})

test_that("optwin_df is Eq. 2", {
  expect_equal(optwin_df(10, 5, 2), (1/10 + 2/5)^2 / ((1/10)^2/9 + (2/5)^2/4))
})
