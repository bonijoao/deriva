# Golden fixture generator. Oracle: datadriftR (GPL) - DEV-ONLY.
# KSWIN is stochastic: the seed is set right before the run so the sample()
# draws are reproducible. The deriva golden test sets the SAME seed.
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}
GOLDEN_SEED <- 123L

set.seed(99)  # stream generation seed (independent of the run seed)
stream <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))

set.seed(GOLDEN_SEED)  # run seed: governs sample() inside KSWIN
k <- datadriftR::KSWIN$new(alpha = 0.005, window_size = 100, stat_size = 30)
drift <- logical(length(stream))
for (i in seq_along(stream)) {
  k$add_element(stream[[i]])
  drift[[i]] <- isTRUE(k$change_detected)
}

golden <- data.frame(value = stream, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "kswin-golden.csv"), row.names = FALSE)
cat("fixture written: seed", GOLDEN_SEED, "|", sum(drift), "drift flags at", paste(which(drift), collapse = ","), "\n")
