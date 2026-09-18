expect_bad <- function(check, x) {
  expect_error(check(x, arg = "p", call = rlang::current_env()),
               class = "deriva_error_invalid_param")
}

test_that("p_whole() accepts whole numbers at or above min", {
  chk <- p_whole(min = 1)
  expect_true(chk(30, arg = "p", call = NULL))
  expect_true(chk(1L, arg = "p", call = NULL))
  for (x in list(0, -1, 2.5, "abc", NA_real_, c(1, 2), NULL, Inf, TRUE)) expect_bad(chk, x)
  expect_true(p_whole(min = 0)(0, arg = "p", call = NULL))
})

test_that("p_number() honours open and closed bounds", {
  closed <- p_number(0)
  expect_true(closed(0, arg = "p", call = NULL))
  expect_true(closed(50, arg = "p", call = NULL))
  for (x in list(-0.1, "abc", NA_real_, c(1, 2), NULL, Inf)) expect_bad(closed, x)

  half_open <- p_number(0, 1, open_min = TRUE)
  expect_true(half_open(1, arg = "p", call = NULL))
  expect_bad(half_open, 0)
  expect_bad(half_open, 1.01)
})

test_that("p_prob() is the open unit interval", {
  chk <- p_prob()
  expect_true(chk(0.005, arg = "p", call = NULL))
  for (x in list(0, 1, 5, -1, "abc")) expect_bad(chk, x)
})

test_that("p_flag() accepts only a single TRUE/FALSE", {
  chk <- p_flag()
  expect_true(chk(TRUE, arg = "p", call = NULL))
  for (x in list(NA, 1, "TRUE", c(TRUE, FALSE), NULL)) expect_bad(chk, x)
})

test_that("the error names the argument and what was expected", {
  expect_error(p_prob()(5, arg = "alpha", call = rlang::current_env()),
               "`alpha` must be a number in \\(0, 1\\)")
})

test_that("c_order() and c_all() report the first violated constraint", {
  non_strict <- c_order("lo", "hi")
  expect_null(non_strict(list(lo = 1, hi = 1)))
  expect_match(non_strict(list(lo = 2, hi = 1)), "`lo` \\(2\\) must not exceed `hi` \\(1\\)")
  strict <- c_order("lo", "hi", strict = TRUE)
  expect_match(strict(list(lo = 1, hi = 1)), "`lo` \\(1\\) must be less than `hi` \\(1\\)")
  both <- c_all(c_order("a", "b"), c_order("c", "d"))
  expect_null(both(list(a = 1, b = 2, c = 1, d = 2)))
  expect_match(both(list(a = 1, b = 2, c = 3, d = 2)), "`c`")
})

test_that("validate_params() runs every check and then the constraint", {
  m <- list(name = "toy",
            checks = list(a = p_whole(), b = p_whole()),
            constraint = c_order("a", "b"))
  expect_invisible(validate_params(m, list(a = 1, b = 2)))
  expect_error(validate_params(m, list(a = "x", b = 2)), class = "deriva_error_invalid_param")
  expect_error(validate_params(m, list(a = 3, b = 2)), "Invalid parameter combination")
})
