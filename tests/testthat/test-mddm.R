run_mddm <- function(method, x, ...) {
  m <- drift_method(method); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("mddm variants registered as error methods with reference defaults", {
  for (nm in c("mddm_a", "mddm_g", "mddm_e")) {
    m <- drift_method(nm)
    expect_identical(m$signal_type, "error")
    expect_identical(m$params$window_size, 100)
    expect_identical(m$params$delta, 1e-6)
  }
  expect_identical(drift_method("mddm_a")$params$d, 0.01)
  expect_identical(drift_method("mddm_g")$params$r, 1.01)
  expect_identical(drift_method("mddm_e")$params$lambda, 0.01)
})

test_that("mddm variants emit FALSE (not NA) while the window fills", {
  for (nm in c("mddm_a", "mddm_g", "mddm_e")) {
    out <- run_mddm(nm, stats::rbinom(100, 1, 0.1))
    expect_false(any(is.na(out$signals$.drift)))
  }
})

test_that("mddm variants detect an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.02), stats::rbinom(500, 1, 0.5))
  for (nm in c("mddm_a", "mddm_g", "mddm_e")) {
    out <- run_mddm(nm, x)
    expect_true(any(which(out$signals$.drift) > 500))
  }
})
