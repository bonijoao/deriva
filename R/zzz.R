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
  register_drift_method(
    name = "page_hinkley",
    init = page_hinkley_init,
    step = page_hinkley_step,
    signal_type = "distribution",
    params = list(min_instances = 30, delta = 0.05, threshold = 50, alpha = 1),
    meta = list(
      full_name = "Page-Hinkley Test",
      reference = "Page (1954). Continuous Inspection Schemes. Biometrika 41."
    )
  )
  register_drift_method(
    name = "ewma",
    init = ewma_init,
    step = ewma_step,
    signal_type = "error",
    params = list(lambda = 0.2, L = 3.5, min_instances = 30),
    meta = list(
      full_name = "EWMA for Concept Drift",
      reference = "Ross et al. (2012). EWMA Charts for Detecting Concept Drift. Pattern Recognition Letters."
    )
  )
  register_drift_method(
    name = "stepd",
    init = stepd_init,
    step = stepd_step,
    signal_type = "error",
    params = list(window_size = 30, warning_level = 0.05,
                  out_control_level = 0.003, min_instances = 30),
    meta = list(
      full_name = "Statistical Test of Equal Proportions Detector",
      reference = "Nishida (2008). Detecting Concept Drift Using Statistical Testing. Discovery Science 2008."
    )
  )
  register_drift_method(
    name = "fhddm",
    init = fhddm_init,
    step = fhddm_step,
    signal_type = "error",
    params = list(window_size = 100, delta = 1e-7, delta_warning = 1e-5),
    meta = list(
      full_name = "Fast Hoeffding Drift Detection Method",
      reference = "Pesaranghader & Viktor (2016). Fast Hoeffding Drift Detection Method. ECML-PKDD 2016."
    )
  )
  register_drift_method(
    name = "hddm_a",
    init = hddm_a_init,
    step = hddm_a_step,
    signal_type = "error",
    params = list(drift_confidence = 0.001, warning_confidence = 0.005,
                  two_side_option = TRUE),
    meta = list(
      full_name = "Hoeffding Drift Detection Method (A-test)",
      reference = "Frias-Blanco et al. (2015). Online and Non-Parametric Drift Detection Methods. IEEE TKDE."
    )
  )
  register_drift_method(
    name = "hddm_w",
    init = hddm_w_init,
    step = hddm_w_step,
    signal_type = "error",
    params = list(drift_confidence = 0.001, warning_confidence = 0.005,
                  lambda_option = 0.05, two_side_option = TRUE),
    meta = list(
      full_name = "Hoeffding Drift Detection Method (W-test)",
      reference = "Frias-Blanco et al. (2015). Online and Non-Parametric Drift Detection Methods. IEEE TKDE."
    )
  )
  register_drift_method(
    name = "adwin",
    init = adwin_init,
    step = adwin_step,
    signal_type = "distribution",
    params = list(delta = 0.002, clock = 32, max_buckets = 5,
                  min_window_length = 5, grace_period = 10),
    meta = list(
      full_name = "Adaptive Windowing",
      reference = "Bifet & Gavalda (2007). Learning from Time-Changing Data with Adaptive Windowing. SDM 2007."
    )
  )
  register_drift_method(
    name = "rddm",
    init = rddm_init,
    step = rddm_step,
    signal_type = "error",
    params = list(min_instances = 129, warning_level = 1.773,
                  out_control_level = 2.258, max_concept = 40000,
                  min_concept = 7000, warn_limit = 1400),
    meta = list(
      full_name = "Reactive Drift Detection Method",
      reference = "Barros et al. (2017). RDDM: Reactive Drift Detection Method. Expert Systems with Applications 90."
    )
  )
  register_drift_method(
    name = "fhddms",
    init = fhddms_init,
    step = fhddms_step,
    signal_type = "error",
    params = list(window_size = 100, short_size = 25, delta = 1e-7),
    meta = list(
      full_name = "Stacking Fast Hoeffding Drift Detection Method",
      reference = "Pesaranghader, Viktor & Paquet (2017). Reservoir of Diverse Adaptive Learners and Stacking FHDDM for Evolving Data Streams. Machine Learning."
    )
  )
  register_drift_method(
    name = "cusum",
    init = cusum_init,
    step = cusum_step,
    signal_type = "distribution",
    params = list(min_instances = 30, delta = 0.005, threshold = 50),
    meta = list(
      full_name = "Cumulative Sum",
      reference = "Page (1954). Continuous Inspection Schemes. Biometrika 41."
    )
  )
  mddm_reference <- "Pesaranghader, Viktor & Paquet (2018). McDiarmid Drift Detection Methods for Evolving Data Streams. IJCNN 2018."
  register_drift_method(
    name = "mddm_a",
    init = mddm_a_init,
    step = mddm_step,
    signal_type = "error",
    params = list(window_size = 100, delta = 1e-6, d = 0.01),
    meta = list(full_name = "McDiarmid DDM (Arithmetic)", reference = mddm_reference)
  )
  register_drift_method(
    name = "mddm_g",
    init = mddm_g_init,
    step = mddm_step,
    signal_type = "error",
    params = list(window_size = 100, delta = 1e-6, r = 1.01),
    meta = list(full_name = "McDiarmid DDM (Geometric)", reference = mddm_reference)
  )
  register_drift_method(
    name = "mddm_e",
    init = mddm_e_init,
    step = mddm_step,
    signal_type = "error",
    params = list(window_size = 100, delta = 1e-6, lambda = 0.01),
    meta = list(full_name = "McDiarmid DDM (Euler)", reference = mddm_reference)
  )
  fisher_reference <- "de Lima Cabral & de Barros (2018). Concept drift detection based on Fisher's Exact test. Information Sciences 442-443."
  register_drift_method(
    name = "ftdd",
    init = ftdd_init,
    step = ftdd_step,
    signal_type = "error",
    params = list(window_size = 30, warning_level = 0.05,
                  out_control_level = 0.003, min_instances = 30),
    meta = list(full_name = "Fisher Test Drift Detector", reference = fisher_reference)
  )
  register_drift_method(
    name = "fpdd",
    init = fpdd_init,
    step = fpdd_step,
    signal_type = "error",
    params = list(window_size = 30, warning_level = 0.05,
                  out_control_level = 0.003, min_instances = 30, min_cell = 5),
    meta = list(full_name = "Fisher Proportions Drift Detector", reference = fisher_reference)
  )
  register_drift_method(
    name = "fsdd",
    init = fsdd_init,
    step = fsdd_step,
    signal_type = "error",
    params = list(window_size = 30, warning_level = 0.05,
                  out_control_level = 0.003, min_instances = 30, min_cell = 5),
    meta = list(full_name = "Fisher Square Drift Detector", reference = fisher_reference)
  )
  register_drift_method(
    name = "wstd",
    init = wstd_init,
    step = wstd_step,
    signal_type = "error",
    params = list(window_size = 30, warning_level = 0.05,
                  out_control_level = 0.003, min_instances = 30, max_old = 4000),
    meta = list(
      full_name = "Wilcoxon Rank Sum Test Drift Detector",
      reference = "de Barros, Hidalgo & de Lima Cabral (2018). Wilcoxon Rank Sum Test Drift Detector. Neurocomputing 275."
    )
  )
  register_drift_method(
    name = "seed",
    init = seed_init,
    step = seed_step,
    signal_type = "distribution",
    params = list(delta = 0.05, block_size = 32, epsilon_prime = 0.01,
                  alpha = 0.8, compression_term = 75),
    meta = list(
      full_name = "SEED (block-based adaptive windowing)",
      reference = "Huang, Koh, Dobbie & Pears (2014). Drift Detection Using Stream Volatility. ECML PKDD 2014."
    )
  )
  register_drift_method(
    name = "seqdrift2",
    init = seqdrift2_init,
    step = seqdrift2_step,
    signal_type = "distribution",
    params = list(delta = 0.01, block_size = 200),
    meta = list(
      full_name = "SeqDrift2 (reservoir sampling + Bernstein bound)",
      reference = "Pears, Sakthithasan & Koh (2014). Detecting concept change in dynamic data streams. Machine Learning 97."
    )
  )
}
