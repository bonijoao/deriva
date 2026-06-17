run_fsdd <- function(x, ...) {
  m <- drift_method("fsdd"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("fsdd registered as error method with min_cell default", {
  m <- drift_method("fsdd")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 30)
  expect_identical(m$params$min_cell, 5)
})

test_that("fsdd detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_fsdd(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("fsdd emits NA during warm-up", {
  out <- run_fsdd(stats::rbinom(40, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

# --- distinguishing logic: chi-square WITHOUT continuity correction ---

test_that("fsdd uses Fisher when a cell is small and chi-square (no continuity) otherwise", {
  p <- drift_method("fsdd")$params
  # small cell -> Fisher branch
  expect_equal(
    fsdd_pvalue(r_old = 50, n_old = 500, r_rec = 1, n_rec = 30, p),
    fisher_pvalue(r_old = 50, n_old = 500, r_rec = 1, n_rec = 30, p)
  )
  # large cells -> chi-square homogeneity test WITHOUT continuity correction
  expect_equal(
    fsdd_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, p),
    prop_z_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, continuity = FALSE)
  )
})

test_that("fsdd's no-continuity branch differs from fpdd's continuity branch", {
  # On the same large-cell table the two non-Fisher branches must not coincide;
  # the continuity correction makes fpdd's p-value strictly larger (less eager).
  pf <- drift_method("fpdd")$params; ps <- drift_method("fsdd")$params
  pv_fpdd <- fpdd_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, pf)
  pv_fsdd <- fsdd_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, ps)
  expect_gt(pv_fpdd, pv_fsdd)
})
