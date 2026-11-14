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

run_ow <- function(x, ...) detect_drift(tibble::tibble(error = x), .col = error, method = "optwin", ...)

test_that("optwin is registered with the authors' defaults", {
  m <- drift_method("optwin")
  expect_identical(m$signal_type, "error")
  expect_identical(m$params, list(confidence = 0.99, rho = 0.5, max_window = 25000,
                                  min_window = 30, warning_confidence = 0.98, f_test = TRUE))
})

test_that("optwin is NA until observation 30", {
  set.seed(1); r <- run_ow(stats::rbinom(100, 1, 0.3))
  expect_true(all(is.na(r$.drift[1:29])) && all(is.na(r$.warning[1:29])))
  expect_false(is.na(r$.drift[30]) || is.na(r$.warning[30]))
})

test_that("optwin detects a rise in the error rate and ignores a fall", {
  set.seed(2); r <- run_ow(c(stats::rbinom(1000, 1, 0.3), stats::rbinom(600, 1, 0.6)))
  expect_true(any(r$.drift[1001:1600], na.rm = TRUE))
  set.seed(3); r <- run_ow(c(stats::rbinom(1000, 1, 0.6), stats::rbinom(1000, 1, 0.3)))
  expect_false(any(r$.drift[1001:2000], na.rm = TRUE))
})

test_that("optwin warns no later than it drifts on a ramp", {
  set.seed(4); p <- c(rep(0.2, 600), seq(0.2, 0.7, length.out = 1400))
  r <- run_ow(stats::rbinom(length(p), 1, p))
  d <- which(r$.drift)[1]; w <- which(r$.warning)[1]
  expect_false(is.na(d)); expect_false(is.na(w)); expect_lte(w, d)
})

test_that("optwin re-warms after a drift", {
  set.seed(5); r <- run_ow(c(stats::rbinom(400, 1, 0.1), stats::rbinom(400, 1, 0.8)))
  hit <- which(r$.drift)[1]
  expect_true(all(is.na(r$.drift[(hit + 1):(hit + 28)])))
  expect_false(is.na(r$.drift[hit + 29]))
})

test_that("optwin survives a constant stream and flags one error after only zeros", {
  expect_false(any(run_ow(rep(0, 300))$.drift, na.rm = TRUE))
  expect_false(any(run_ow(rep(1, 300))$.drift, na.rm = TRUE))
  r <- run_ow(c(rep(0, 40), 1, rep(0, 20)))
  expect_identical(which(r$.drift), 41L)        # zero variance: the F-test fires (Algorithm 1)
  set.seed(6); x <- stats::rbinom(300, 1, 0.3) + 0; x[100] <- Inf
  expect_error(run_ow(x), "0/1")                # non-finite errors never reach the detector
})

test_that("optwin is batch-invariant", {
  set.seed(7); s <- tibble::tibble(error = c(stats::rbinom(700, 1, 0.2), stats::rbinom(700, 1, 0.5)))
  f0 <- fit(drift_detector("optwin"), s[1:200, ], signal = error)
  expect_identical(advance(f0, s[201:1400, ])$history,
                   advance(advance(f0, s[201:888, ]), s[889:1400, ])$history)
})

test_that("optwin rejects inconsistent settings", {
  expect_error(drift_detector("optwin", warning_confidence = 0.995), "warning_confidence")
  expect_error(drift_detector("optwin", min_window = 50, max_window = 40), "min_window")
})

test_that("optwin's smallest min_window still leaves two values in each sub-window", {
  expect_error(drift_detector("optwin", min_window = 4), "min_window")
  set.seed(8); expect_no_error(run_ow(stats::rbinom(200, 1, 0.3), min_window = 5))
})

test_that("optwin with f_test = FALSE decides on the t-test alone", {
  expect_false(any(run_ow(c(rep(0, 40), 1, rep(0, 20)), f_test = FALSE)$.drift, na.rm = TRUE))
  set.seed(9); x <- stats::rbinom(3000, 1, 0.05)
  expect_gt(sum(run_ow(x)$.drift, na.rm = TRUE), sum(run_ow(x, f_test = FALSE)$.drift, na.rm = TRUE))
  set.seed(10); r <- run_ow(c(stats::rbinom(1500, 1, 0.05), stats::rbinom(1500, 1, 0.15)), f_test = FALSE)
  expect_true(any(r$.drift[1501:3000], na.rm = TRUE))
})

test_that("optwin_cut is the largest W_hist with R <= rho, by brute force", {
  brute <- function(n, cf, rho) {
    dp <- cf^(1 / 4); nh <- 2:(n - 2); nn <- n - nh; f <- stats::qf(dp, nh - 1, nn - 1)
    R <- stats::qt(dp, optwin_df(nh, nn, f)) * sqrt(1 / nh + f / nn)
    if (any(R <= rho)) max(nh[R <= rho]) else floor(n / 2) + 1
  }
  for (cf in c(0.99, 0.999)) for (rho in c(0.1, 0.5, 1)) for (n in c(5, 30, 179, 181, 400, 1234, 3999)) {
    expect_identical(optwin_cut(n, cf, rho)$cut, as.integer(brute(n, cf, rho)), label = paste(cf, rho, n))
  }
})

test_that("optwin fills its cut cache quickly for a small rho", {
  skip_on_cran()
  expect_lt(system.time(for (n in 30:4000) optwin_cut(n, 0.97, 0.1))[["elapsed"]], 10)
})

test_that("optwin's warning is FALSE on the drift observation", {
  set.seed(11); r <- run_ow(c(stats::rbinom(500, 1, 0.1), stats::rbinom(500, 1, 0.6)))
  expect_false(any(r$.warning[which(r$.drift)]))
})
