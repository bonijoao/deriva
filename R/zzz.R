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
}
