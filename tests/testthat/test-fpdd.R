run_fpdd <- function(x, ...) {
  m <- drift_method("fpdd"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("fpdd registered as error method with min_cell default", {
  m <- drift_method("fpdd")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$window_size, 30)
  expect_identical(m$params$min_cell, 5)
})

test_that("fpdd detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_fpdd(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("fpdd emits NA during warm-up", {
  out <- run_fpdd(stats::rbinom(40, 1, 0.1))
  expect_true(all(is.na(out$signals$.drift[1:28])))
})

# --- distinguishing logic: the Fisher-vs-proportions switch ---

test_that("fisher_cells_small flags a sparse 2x2 table", {
  # recent has 1 error in 30 -> errors cell = 1 < 5 -> small
  expect_true(fisher_cells_small(r_old = 50, n_old = 500, r_rec = 1, n_rec = 30, min_cell = 5))
  # all cells comfortably >= 5 -> not small
  expect_false(fisher_cells_small(r_old = 50, n_old = 200, r_rec = 10, n_rec = 30, min_cell = 5))
})

test_that("fpdd uses Fisher when a cell is small and the proportions test otherwise", {
  p <- drift_method("fpdd")$params
  # small cell -> Fisher branch
  expect_equal(
    fpdd_pvalue(r_old = 50, n_old = 500, r_rec = 1, n_rec = 30, p),
    fisher_pvalue(r_old = 50, n_old = 500, r_rec = 1, n_rec = 30, p)
  )
  # large cells -> STEPD-style proportions test WITH continuity correction
  expect_equal(
    fpdd_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, p),
    prop_z_pvalue(r_old = 20, n_old = 200, r_rec = 12, n_rec = 30, continuity = TRUE)
  )
})
