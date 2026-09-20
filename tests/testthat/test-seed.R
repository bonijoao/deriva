run_seed <- function(x, ...) {
  m <- drift_method("seed"); params <- m$params
  dots <- list(...); params[names(dots)] <- dots
  run_engine(m, m$init(params), x)
}

test_that("seed registered as a distribution method with defaults", {
  m <- drift_method("seed")
  expect_identical(m$signal_type, "distribution")
  expect_identical(m$params$delta, 0.05)
  expect_identical(m$params$block_size, 32)
  expect_identical(m$params$epsilon_prime, 0.01)
  expect_identical(m$params$compression_term, 75)
  expect_named(m$params, c("delta", "block_size", "epsilon_prime", "compression_term"))
})

test_that("seed warning is all NA and the first two blocks are NA", {
  out <- run_seed(stats::rnorm(200))
  expect_true(all(is.na(out$signals$.warning)))   # no warning level
  expect_true(all(is.na(out$signals$.drift[1:63])))
})

test_that("seed detects an error-rate jump after the change point", {
  set.seed(123); x <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
  out <- run_seed(x)
  d <- which(out$signals$.drift)
  expect_true(any(d > 500))
  expect_lt(length(d), 30)
})

test_that("seed detects a mean shift after the change point", {
  set.seed(1); x <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
  out <- run_seed(x)
  expect_true(any(which(out$signals$.drift) > 500))
})

test_that("seed keeps few detections on a stationary stream", {
  set.seed(7); x <- stats::rbinom(2000, 1, 0.2)
  out <- run_seed(x)
  expect_lt(length(which(out$signals$.drift)), 5)
})

test_that("seed no longer accepts the alpha it never used", {
  expect_error(drift_detector("seed", alpha = 0.8), "alpha")
})

# Block compression. Reached only after `compression_term` + 1 blocks accumulate
# without a reset, i.e. 2432 observations under the defaults, so the tests below
# either shrink the blocks or spend the observations to get there.

test_that("compression starts one block past compression_term", {
  flat <- rep(1, 76 * 32)
  expect_length(run_seed(flat[seq_len(75 * 32)])$state$blocks, 75)
  expect_lt(length(run_seed(flat)$state$blocks), 75)
})

test_that("compression merges homogeneous blocks and spares the two newest", {
  block <- function(v) list(total = sum(v), variance = sum((v - mean(v))^2), n = length(v))
  set.seed(42)
  values <- c(lapply(1:8, function(i) stats::rnorm(32, 0, 0.001)),
              lapply(1:2, function(i) stats::rnorm(32, 5, 0.001)))
  before <- lapply(values, block)
  after <- seed_compress(list(params = list(epsilon_prime = 0.01), blocks = before,
                              blocks_since_compress = 99))

  expect_length(after$blocks, 3)                         # 8 alike merge into 1
  expect_identical(after$blocks[2:3], before[9:10])      # newest two untouched
  expect_identical(after$blocks_since_compress, 0)
})

test_that("compression preserves the window's count and sum", {
  block <- function(v) list(total = sum(v), variance = sum((v - mean(v))^2), n = length(v))
  set.seed(42)
  values <- c(lapply(1:8, function(i) stats::rnorm(32, 0, 0.001)),
              lapply(1:2, function(i) stats::rnorm(32, 5, 0.001)))
  before <- lapply(values, block)
  after <- seed_compress(list(params = list(epsilon_prime = 0.01), blocks = before,
                              blocks_since_compress = 99))$blocks

  total <- function(bs, field) sum(vapply(bs, `[[`, numeric(1), field))
  expect_identical(total(after, "n"), total(before, "n"))
  expect_equal(total(after, "total"), total(before, "total"))
})

test_that("compression does not change which observations are flagged", {
  # block_size = 4 with compression_term = 5 compresses every 24 observations;
  # the same stream with a compression_term it never reaches is the control.
  compare <- function(x) {
    on <- run_seed(x, block_size = 4, compression_term = 5)
    off <- run_seed(x, block_size = 4, compression_term = 1e9)
    expect_identical(which(on$signals$.drift), which(off$signals$.drift))
  }
  set.seed(7)
  compare(stats::rnorm(800))                                  # stationary
  compare(c(stats::rnorm(400), stats::rnorm(400, 2)))         # abrupt shift
  compare(cumsum(stats::rnorm(800, 0.004)))                   # gradual drift
  compare(c(stats::rbinom(400, 1, 0.05), stats::rbinom(400, 1, 0.3)))
})
