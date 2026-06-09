# Golden fixture generator. Oracle: datadriftR (GPL) - DEV-ONLY. PH is
# deterministic (no RNG); the seed only fixes the synthetic stream. Uses a
# continuous stream (PH's natural input).
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}
set.seed(123)
stream <- c(stats::rnorm(500, 0, 1), stats::rnorm(500, 3, 1))
k <- datadriftR::PageHinkley$new(min_instances = 30, delta = 0.05, threshold = 50, alpha = 1)
drift <- logical(length(stream))
for (i in seq_along(stream)) { k$add_element(stream[[i]]); drift[[i]] <- isTRUE(k$change_detected) }
golden <- data.frame(value = stream, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "page-hinkley-golden.csv"), row.names = FALSE)
cat("fixture written:", sum(drift), "drift flags at", paste(which(drift), collapse = ","), "\n")
