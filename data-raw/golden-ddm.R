# Golden fixture generator. Oracle: datadriftR (GPL) — DEV-ONLY.
# Rule (design 10b): deriva is implemented from the papers/skills and
# validated against datadriftR's OUTPUT. Never port datadriftR code.
if (!requireNamespace("datadriftR", quietly = TRUE)) {
  install.packages("datadriftR", repos = "https://cloud.r-project.org")
}

stream <- deriva::sim_drift_stream(
  n_pre = 500, n_post = 500, p_pre = 0.05, p_post = 0.30, seed = 42
)

# Arg name per the tsdrift-ddm skill: min_num_instances (check ?datadriftR::DDM)
ddm <- datadriftR::DDM$new(
  min_num_instances = 30, warning_level = 2.0, out_control_level = 3.0
)
n <- nrow(stream)
warning <- logical(n)
drift <- logical(n)
for (i in seq_len(n)) {
  ddm$add_element(stream$error[[i]])
  warning[[i]] <- isTRUE(ddm$warning_detected)
  drift[[i]] <- isTRUE(ddm$change_detected)
}

golden <- data.frame(error = stream$error, warning = warning, drift = drift)
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE, showWarnings = FALSE)
write.csv(golden, file.path("tests", "testthat", "fixtures", "ddm-golden.csv"),
          row.names = FALSE)
cat("fixture written:", sum(drift), "drift flags,", sum(warning), "warning flags\n")
