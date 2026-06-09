.onLoad <- function(libname, pkgname) {
  register_drift_method(
    name = "ddm",
    init = ddm_init,
    step = ddm_step,
    signal_type = "error",
    params = list(min_instances = 30, warning_level = 2, out_control_level = 3),
    meta = list(
      full_name = "Drift Detection Method",
      reference = "Gama et al. (2004). Learning with Drift Detection. SBIA 2004."
    )
  )
  register_drift_method(
    name = "eddm",
    init = eddm_init,
    step = eddm_step,
    signal_type = "error",
    params = list(min_instances = 30, warning_level = 0.95, out_control_level = 0.90),
    meta = list(
      full_name = "Early Drift Detection Method",
      reference = "Baena-Garcia et al. (2006). Early Drift Detection Method. IWKDDS 2006."
    )
  )
  register_drift_method(
    name = "kswin",
    init = kswin_init,
    step = kswin_step,
    signal_type = "distribution",
    params = list(alpha = 0.005, window_size = 100, stat_size = 30),
    meta = list(
      full_name = "Kolmogorov-Smirnov Windowing",
      reference = "Raab et al. (2020). Reactive Soft Prototype Computing for Concept Drift Streams. Neurocomputing."
    )
  )
}
