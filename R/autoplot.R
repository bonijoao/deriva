#' Plot the monitored signal with drift markings
#'
#' Plots the running mean of the signal over the full history, with the
#' baseline/stream boundary (labelled "training ends"), warning points
#' (orange) and drift points (red vertical lines, the first one labelled
#' with its index). Requires ggplot2 (Suggests).
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

  # Fixed status colours (never themed): orange = warning, red = drift.
  # `series` is deriva's own identity colour -- a violet, deliberately not
  # the generic dashboard blue -- kept off the status colours so it never
  # impersonates a warning/drift state.
  ink       <- "#0b0b0b"
  ink2      <- "#52514e"
  muted     <- "#898781"
  grid_col  <- "#e1e0d9"
  divider   <- "#c3c2b7"
  series    <- "#4a3aa7"
  warn_col  <- "#fab219"
  drift_col <- "#d03b3b"

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$index, y = .data$running_mean)) +
    ggplot2::geom_line(colour = series, linewidth = 0.4)

  if (n_baseline > 0) {
    p <- p +
      ggplot2::geom_vline(xintercept = n_baseline, linetype = "dotted", colour = divider) +
      ggplot2::annotate(
        "text", x = n_baseline, y = Inf, label = "training ends",
        vjust = 1.6, hjust = -0.05, size = 3, colour = muted, fontface = "italic"
      )
  }
  if (any(df$warning)) {
    p <- p + ggplot2::geom_point(
      data = df[df$warning, ], shape = 21, size = 1.2,
      colour = warn_col, fill = warn_col, alpha = 0.9
    )
  }
  if (any(df$drift)) {
    first_drift <- df$index[df$drift][1]
    p <- p +
      ggplot2::geom_vline(
        xintercept = df$index[df$drift], colour = drift_col, alpha = 0.55, linewidth = 0.5
      ) +
      ggplot2::annotate(
        "text", x = first_drift, y = Inf, label = paste0("drift at t=", first_drift),
        vjust = 3.1, hjust = -0.05, size = 3, colour = drift_col, fontface = "bold"
      )
  }

  p +
    ggplot2::labs(
      title = paste0("Drift monitoring (", object$spec$method, ")"),
      subtitle = sprintf(
        "%d observations | %d warning(s) | %d drift(s) detected",
        nrow(df), sum(df$warning), sum(df$drift)
      ),
      x = "observation",
      y = paste0("running mean of `", object$signal_col, "`"),
      caption = "orange = warning     |     red = confirmed drift"
    ) +
    ggplot2::theme_minimal(base_size = 11, base_family = "sans") +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(colour = ink, face = "bold", size = 13),
      plot.subtitle = ggplot2::element_text(colour = ink2, face = "italic", size = 9.5, margin = ggplot2::margin(b = 8)),
      plot.caption  = ggplot2::element_text(colour = muted, face = "italic", size = 8, hjust = 0, margin = ggplot2::margin(t = 8)),
      axis.title    = ggplot2::element_text(colour = ink2, size = 9),
      axis.text     = ggplot2::element_text(colour = muted, size = 8),
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = grid_col, linewidth = 0.3)
    )
}
