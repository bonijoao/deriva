# Golden fixture generator. Oracle: datadriftR (GPL) - DEV-ONLY. ADWIN is
# deterministic (no RNG); the seed only fixes the synthetic continuous stream.
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}
set.seed(123)
stream <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
a <- datadriftR::ADWIN$new(delta = 0.002, clock = 32, max_buckets = 5,
                          min_window_length = 5, grace_period = 10)
drift <- logical(length(stream))
for (i in seq_along(stream)) {
  a$add_element(stream[[i]])
  drift[[i]] <- isTRUE(a$detected_change())
}
golden <- data.frame(value = stream, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "adwin-golden.csv"), row.names = FALSE)
cat("fixture written:", sum(drift), "drift flags at", paste(which(drift), collapse = ","), "\n")
