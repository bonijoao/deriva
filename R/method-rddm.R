# RDDM - Reactive Drift Detection Method (Barros et al. 2017, ESWA).
# DDM extended with three heuristics to keep it sensitive on very long stable
# concepts: (1) a soft "RDDM drift" that recomputes the DDM stats over the last
# `min_concept` stored predictions once a concept exceeds `max_concept` (without
# touching the learner); (2) a forced drift when warnings persist past
# `warn_limit`; (3) a bounded buffer of recent predictions replayed to re-seed
# the new concept's stats from the start of the warning period.
# Same 1=error convention as DDM. No external R oracle (datadriftR has no RDDM)
# -> validated against synthetic ground truth. Has warning.
# Reported drift = the DDM-drift flag; the soft RDDM-drift only schedules the
# stat recompute and is NOT a reported drift event.
rddm_init <- function(params) {
  list(
    params = params,
    stored = numeric(0),        # storedPredictions, capped at params$min_concept
    m_n = 1, m_p = 1, m_s = 0,
    m_pmin = Inf, m_smin = Inf, m_psmin = Inf,
    rddm_drift = FALSE, ddm_drift = FALSE,
    num_inst_concept = 0, num_warnings = 0,
    warning_detected = FALSE, change_detected = FALSE
  )
}

rddm_step <- function(state, obs) {
  p <- state$params

  # 1) Replay after an RDDM/forced/DDM drift flagged on the previous instance:
  #    reset the DDM stats and re-derive them over the stored buffer.
  if (state$rddm_drift) {
    state$m_n <- 1; state$m_p <- 1; state$m_s <- 0
    state$m_pmin <- Inf; state$m_smin <- Inf; state$m_psmin <- Inf
    stored <- state$stored
    for (k in seq_along(stored)) {
      v <- stored[k]
      state$m_p <- state$m_p + (v - state$m_p) / state$m_n
      state$m_s <- sqrt(state$m_p * (1 - state$m_p) / state$m_n)
      state$m_n <- state$m_n + 1
      if (k >= p$min_instances && state$m_p + state$m_s < state$m_psmin) {
        state$m_pmin <- state$m_p
        state$m_smin <- state$m_s
        state$m_psmin <- state$m_p + state$m_s
      }
    }
    state$rddm_drift <- FALSE
    state$ddm_drift <- FALSE
    state$num_inst_concept <- 0
    state$num_warnings <- 0
  }

  # 2) Store obs (forget oldest if buffer full) and update DDM stats with obs.
  state$stored <- c(state$stored, obs)
  if (length(state$stored) > p$min_concept) state$stored <- state$stored[-1]
  state$m_p <- state$m_p + (obs - state$m_p) / state$m_n
  state$m_s <- sqrt(state$m_p * (1 - state$m_p) / state$m_n)
  state$m_n <- state$m_n + 1
  state$num_inst_concept <- state$num_inst_concept + 1
  warning_level <- FALSE

  # Warm-up: NA until `min_instances` seen in the current concept (DDM-style).
  if (state$num_inst_concept < p$min_instances) {
    return(list(state = state, signal = list(warning = NA, drift = NA)))
  }

  # 3) Detection (DDM core).
  if (state$m_p + state$m_s < state$m_psmin) {
    state$m_pmin <- state$m_p
    state$m_smin <- state$m_s
    state$m_psmin <- state$m_p + state$m_s
  }

  if (state$m_p + state$m_s > state$m_pmin + p$out_control_level * state$m_smin) {
    state$rddm_drift <- TRUE; state$ddm_drift <- TRUE
    if (state$num_warnings == 0) state$stored <- obs   # abrupt: shrink buffer to [obs]
  } else if (state$m_p + state$m_s >
             state$m_pmin + p$warning_level * state$m_smin) {
    if (state$num_warnings >= p$warn_limit) {          # warning too long -> force drift
      state$rddm_drift <- TRUE; state$ddm_drift <- TRUE
      state$stored <- obs
    } else {
      warning_level <- TRUE
      state$num_warnings <- state$num_warnings + 1
    }
  } else {
    state$num_warnings <- 0
  }

  # Soft RDDM drift: concept too long and not in warning -> schedule recompute.
  if (state$num_inst_concept >= p$max_concept && !warning_level) {
    state$rddm_drift <- TRUE
  }

  state$warning_detected <- warning_level
  list(state = state, signal = list(warning = warning_level, drift = state$ddm_drift))
}
