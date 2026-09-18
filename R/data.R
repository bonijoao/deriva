#' Simulated credit monitoring stream
#'
#' A synthetic per-observation error stream from a credit-approval
#' classifier in production: 500 stable observations (5% error rate),
#' then 500 after a market shift raised the error rate to 30%. Frozen
#' with a fixed seed, so every example that loads it sees the same
#' story — including the single, correct DDM detection at `t = 542`
#' with no false positives before it.
#'
#' @format A tibble with 1,000 rows and 3 columns:
#' \describe{
#'   \item{t}{Observation index, 1 to 1000.}
#'   \item{error}{0/1 classifier error for that observation.}
#'   \item{drift_true}{Ground truth: `TRUE` from observation 501 on,
#'     the point the market shift occurred.}
#' }
#' @source Simulated with [sim_drift_stream()]:
#'   `sim_drift_stream(n_pre = 500, n_post = 500, p_pre = 0.05, p_post = 0.30, seed = 2)`.
#'   See `data-raw/credit-monitoring.R`.
#' @examples
#' credit_monitoring
#' detect_drift(credit_monitoring, .col = error, method = "ddm")
"credit_monitoring"

#' Simulated sensor monitoring stream
#'
#' A synthetic numeric sensor-reading stream: 500 stable observations
#' centred at 0, then 500 after the sensor drifted out of calibration
#' and the mean shifted to 2. Frozen with a fixed seed.
#'
#' @format A tibble with 1,000 rows and 3 columns:
#' \describe{
#'   \item{t}{Observation index, 1 to 1000.}
#'   \item{value}{Numeric sensor reading.}
#'   \item{drift_true}{Ground truth: `TRUE` from observation 501 on,
#'     the point the sensor drifted.}
#' }
#' @source Simulated with [sim_dist_stream()]:
#'   `sim_dist_stream(n_pre = 500, n_post = 500, mean_pre = 0, mean_post = 2, seed = 2)`.
#'   See `data-raw/sensor-monitoring.R`.
#' @examples
#' sensor_monitoring
#' detect_drift(sensor_monitoring, .col = value, method = "kswin", seed = 7)
"sensor_monitoring"
