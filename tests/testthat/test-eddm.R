run_eddm <- function(x, ...) {
  m <- drift_method("eddm")
  params <- m$params; dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("eddm is registered as an error method with the right defaults", {
  m <- drift_method("eddm")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params$min_instances, 30)
  expect_identical(m$params$warning_level, 0.95)
  expect_identical(m$params$out_control_level, 0.90)
})

test_that("eddm emits NA during warm-up (m_n < min_instances)", {
  out <- run_eddm(rep(0, 40))
  expect_true(all(is.na(out$signals$.drift[1:28])))
  expect_false(any(is.na(out$signals$.drift[29:40])))
})

# Note: EDDM is known to false-positive on stable low-error streams (the
# distance-between-errors distribution is noisy), and deriva reproduces that
# behaviour exactly -- see the golden test. So there is no "stays perfectly
# quiet on stable data" test; correctness is pinned by golden parity instead.

test_that("eddm detects when errors become much more frequent (and isn't pathological)", {
  set.seed(123)
  x <- c(stats::rbinom(500, 1, 0.02), stats::rbinom(500, 1, 0.5))
  out <- run_eddm(x)
  drifts <- which(out$signals$.drift)
  expect_true(any(drifts > 500))        # reacts to the real shift
  expect_lt(length(drifts), 50)         # not firing on every step
})
