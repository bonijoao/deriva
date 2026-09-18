bundled <- function(m) {
  if (the$methods[[m]]$signal_type == "error") {
    list(data = credit_monitoring, col = as.name("error"))
  } else {
    list(data = sensor_monitoring, col = as.name("value"))
  }
}

fit_on <- function(m, data, col) {
  do.call(fit, list(drift_detector(m, seed = 1), data, signal = col))
}

test_that("an empty baseline and an empty batch are accepted by every method", {
  for (m in names(the$methods)) {
    b <- bundled(m)
    f <- fit_on(m, b$data[0, ], b$col)
    expect_identical(glance(f)$n_obs, 0L, label = m)
    f2 <- advance(f, b$data[0, ])
    expect_identical(f2$counts, f$counts, label = m)
    expect_identical(nrow(tidy(f2)), 0L, label = m)
  }
})

test_that("single-observation baseline and batch are accepted by every method", {
  for (m in names(the$methods)) {
    b <- bundled(m)
    f <- advance(fit_on(m, b$data[1, ], b$col), b$data[2, ])
    expect_identical(glance(f)$n_obs, 2L, label = m)
    expect_identical(nrow(augment(f)), 2L, label = m)
  }
})

test_that("detect_drift() on zero rows returns zero annotated rows", {
  for (m in names(the$methods)) {
    b <- bundled(m)
    r <- do.call(detect_drift, list(b$data[0, ], .col = b$col, method = m))
    expect_identical(nrow(r), 0L, label = m)
    expect_true(all(c(".warning", ".drift") %in% names(r)), label = m)
  }
})
