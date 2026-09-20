no_warm_up <- c("hddm_a", "hddm_w")
no_warning_level <- c("ewma", "page_hinkley", "cusum", "kswin", "adwin", "seed",
                      "seqdrift2", "fhddms", "mddm_a", "mddm_g", "mddm_e")

test_that("NA marks observations a detector did not evaluate", {
  for (m in setdiff(names(the$methods), no_warm_up)) {
    r <- run_on_bundled(m)
    expect_true(is.na(r$.drift[[1]]), label = paste(m, "first .drift is NA"))
    expect_true(is.na(r$.warning[[1]]), label = paste(m, "first .warning is NA"))
  }
  for (m in no_warm_up) {
    expect_false(is.na(run_on_bundled(m)$.drift[[1]]), label = m)
  }
})

test_that("a detector without a warning level never reports one", {
  for (m in names(the$methods)) {
    w <- run_on_bundled(m)$.warning
    if (m %in% no_warning_level) {
      expect_true(all(is.na(w)), label = m)
    } else {
      expect_false(all(is.na(w)), label = m)
    }
  }
})

test_that("warm-up ends where each algorithm first evaluates", {
  first_evaluated <- c(fhddm = 100, fhddms = 100, mddm_a = 100, mddm_g = 100,
                       mddm_e = 100, kswin = 101, adwin = 11, seed = 64,
                       seqdrift2 = 400)
  for (m in names(first_evaluated)) {
    d <- run_on_bundled(m)$.drift
    expect_identical(which(!is.na(d))[[1]], as.integer(first_evaluated[[m]]), label = m)
  }
})

test_that("the warm-up after a detected drift is NA again", {
  for (m in setdiff(names(the$methods), no_warm_up)) {
    r <- run_on_bundled(m)
    hits <- which(r$.drift)
    expect_gt(length(hits), 0)
    after <- hits[hits < nrow(r)] + 1
    expect_true(all(is.na(r$.drift[after])), label = paste(m, "re-warms after drift"))
  }
})

test_that("a detector with no warm-up keeps evaluating right after a drift", {
  for (m in no_warm_up) {
    r <- run_on_bundled(m)
    after <- which(r$.drift) + 1
    after <- after[after <= nrow(r)]
    expect_gt(length(after), 0)
    expect_false(any(is.na(r$.drift[after])), label = m)
  }
})
