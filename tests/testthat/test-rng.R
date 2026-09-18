shift <- function(seed) {
  withr::with_seed(seed, tibble::tibble(value = c(stats::rnorm(300), stats::rnorm(300, 3))))
}

test_that("a seeded stochastic detector is reproducible", {
  s <- shift(1)
  a <- detect_drift(s, .col = value, method = "kswin", seed = 42)
  b <- detect_drift(s, .col = value, method = "kswin", seed = 42)
  expect_identical(a, b)
  a2 <- detect_drift(s, .col = value, method = "seqdrift2", block_size = 50, seed = 42)
  b2 <- detect_drift(s, .col = value, method = "seqdrift2", block_size = 50, seed = 42)
  expect_identical(a2, b2)
})

test_that("a seeded run leaves the user's global RNG untouched", {
  s <- shift(1)
  set.seed(99)
  before <- .Random.seed
  f <- fit(drift_detector("kswin", seed = 42), s[1:200, ], signal = value)
  f <- advance(f, s[201:600, ])
  invisible(augment(f, s[1:150, ]))
  invisible(detect_drift(s, .col = value, method = "kswin", seed = 42))
  expect_identical(.Random.seed, before)
})

test_that("seed = N matches set.seed(N) followed by an unseeded run", {
  golden <- utils::read.csv(test_path("fixtures", "kswin-golden.csv"))
  res <- detect_drift(tibble::tibble(value = golden$value), .col = value,
                      method = "kswin", seed = 123L)
  expect_identical(which(res$.drift), which(golden$drift))
})

test_that("seeded results do not depend on how the stream is batched", {
  s <- shift(2)
  f0 <- fit(drift_detector("kswin", seed = 7), s[1:200, ], signal = value)
  one <- advance(f0, s[201:600, ])
  two <- advance(advance(f0, s[201:350, ]), s[351:600, ])
  expect_identical(one$history, two$history)
  expect_identical(one$rng, two$rng)
})

test_that("augment() preview equals what advance() records, seeded", {
  s <- shift(3)
  f0 <- fit(drift_detector("kswin", seed = 7), s[1:200, ], signal = value)
  prev <- augment(f0, s[201:600, ])
  adv <- advance(f0, s[201:600, ])$history[201:600, ]
  expect_identical(prev$.drift, adv$.drift)
})

test_that("seed = NULL keeps the 0.1.0 behaviour (global RNG)", {
  s <- shift(1)
  set.seed(5); a <- detect_drift(s, .col = value, method = "kswin")
  set.seed(5); b <- detect_drift(s, .col = value, method = "kswin")
  expect_identical(a, b)
  expect_null(fit(drift_detector("kswin"), s[1:200, ], signal = value)$rng)
})

test_that("seed is validated", {
  for (bad in list("a", 1.5, c(1, 2), NA_real_, 1e12)) {
    expect_error(drift_detector("kswin", seed = bad), class = "deriva_error_invalid_param")
  }
  expect_no_error(drift_detector("ddm", seed = 1))
})

test_that("seed and keep are reserved names in the registry", {
  expect_error(
    register_drift_method("bad", init = identity, step = identity, signal_type = "error",
                          params = list(seed = 1), checks = list(seed = p_whole()),
                          meta = list()),
    "reserved"
  )
})
