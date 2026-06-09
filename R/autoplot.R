#' Plot the monitored signal with drift markings
#'
#' Plots the running mean of the signal over the full history, with the
#' baseline/stream boundary, warning points (orange) and drift points
#' (red vertical lines). Requires ggplot2 (Suggests).
#'
#' @param object A `drift_detector_fit`.
#' @param ... Not used.
#' @return A ggplot object.
#' @exportS3Method ggplot2::autoplot
autoplot.drift_detector_fit <- function(object, ...) {
  rlang::check_installed("ggplot2", reason = "to use `autoplot()`.")
  h <- object$history
  df <- tibble::tibble(
    index = seq_len(nrow(h)),
    signal = as.numeric(h[[object$signal_col]]),
    warning = !is.na(h$.warning) & h$.warning,
    drift = !is.na(h$.drift) & h$.drift
  )
  df$running_mean <- cumsum(df$signal) / df$index
  n_baseline <- sum(h$.phase == "baseline")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$index, y = .data$running_mean)) +
    ggplot2::geom_line(colour = "grey30") +
    ggplot2::labs(
      x = "observation", y = paste0("running mean of ", object$signal_col),
      title = paste0("Drift monitoring (", object$spec$method, ")")
    )
  if (n_baseline > 0) {
    p <- p + ggplot2::geom_vline(xintercept = n_baseline, linetype = "dotted")
  }
  if (any(df$warning)) {
    p <- p + ggplot2::geom_point(
      data = df[df$warning, ], colour = "orange", size = 1.5
    )
  }
  if (any(df$drift)) {
    p <- p + ggplot2::geom_vline(
      xintercept = df$index[df$drift], colour = "red", alpha = 0.7
    )
  }
  p
}
