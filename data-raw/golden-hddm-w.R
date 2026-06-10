# Golden fixture generator. Oracle: datadriftR (GPL) - DEV-ONLY. HDDM_W is
# deterministic (no RNG); the seed only fixes the synthetic error stream.
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}
set.seed(123)
stream <- c(stats::rbinom(500, 1, 0.05), stats::rbinom(500, 1, 0.5))
w <- datadriftR::HDDM_W$new(drift_confidence = 0.001, warning_confidence = 0.005,
                           lambda_option = 0.05, two_side_option = TRUE)
drift <- logical(length(stream)); warning <- logical(length(stream))
for (i in seq_along(stream)) {
  w$add_element(stream[[i]])
  drift[[i]] <- isTRUE(w$change_detected)
  warning[[i]] <- isTRUE(w$warning_detected)
}
golden <- data.frame(error = stream, warning = warning, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "hddm-w-golden.csv"), row.names = FALSE)
cat("fixture written:", sum(drift), "drift,", sum(warning), "warning\n")
