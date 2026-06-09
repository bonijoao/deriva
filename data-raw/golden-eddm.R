# Golden fixture generator. Oracle: datadriftR (GPL) - DEV-ONLY. EDDM is
# deterministic (no RNG); the seed only fixes the synthetic stream.
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}
set.seed(123)
stream <- c(stats::rbinom(500, 1, 0.02), stats::rbinom(500, 1, 0.5))
e <- datadriftR::EDDM$new(min_num_instances = 30, eddm_warning = 0.95, eddm_outcontrol = 0.90)
drift <- logical(length(stream)); warning <- logical(length(stream))
for (i in seq_along(stream)) {
  e$add_element(stream[[i]])
  drift[[i]] <- isTRUE(e$change_detected)
  warning[[i]] <- isTRUE(e$warning_detected)
}
golden <- data.frame(error = stream, warning = warning, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "eddm-golden.csv"), row.names = FALSE)
cat("fixture written:", sum(drift), "drift,", sum(warning), "warning\n")
