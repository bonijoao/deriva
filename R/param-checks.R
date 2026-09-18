# A checker is function(x, arg, call): returns invisibly or aborts with class "deriva_error_invalid_param".

abort_param <- function(arg, expected, x, call) {
  got <- if (is.atomic(x) && length(x) == 1) {
    format(x)
  } else {
    paste0("<", class(x)[[1]], "> of length ", length(x))
  }
  cli::cli_abort(
    c("{.arg {arg}} must be {expected}.", "x" = "You supplied {got}."),
    class = "deriva_error_invalid_param", call = call
  )
}

is_scalar_number <- function(x) {
  is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x)
}

p_whole <- function(min = 1) {
  force(min)
  function(x, arg, call) {
    if (!(is_scalar_number(x) && x == trunc(x) && x >= min)) {
      abort_param(arg, paste0("a whole number >= ", min), x, call)
    }
    invisible(TRUE)
  }
}

p_number <- function(min, max = Inf, open_min = FALSE, open_max = FALSE) {
  expected <- if (is.infinite(max)) {
    paste0("a finite number ", if (open_min) "> " else ">= ", min)
  } else {
    paste0("a number in ", if (open_min) "(" else "[", min, ", ", max,
           if (open_max) ")" else "]")
  }
  function(x, arg, call) {
    ok <- is_scalar_number(x) &&
      (if (open_min) x > min else x >= min) &&
      (if (open_max) x < max else x <= max)
    if (!ok) abort_param(arg, expected, x, call)
    invisible(TRUE)
  }
}

p_prob <- function() p_number(0, 1, open_min = TRUE, open_max = TRUE)

p_flag <- function() {
  function(x, arg, call) {
    if (!(is.logical(x) && length(x) == 1 && !is.na(x))) {
      abort_param(arg, "TRUE or FALSE", x, call)
    }
    invisible(TRUE)
  }
}

# A constraint is function(params): NULL when satisfied, else a one-line description of the violation.
c_order <- function(lo, hi, strict = FALSE) {
  force(lo); force(hi); force(strict)
  function(p) {
    bad <- if (strict) p[[lo]] >= p[[hi]] else p[[lo]] > p[[hi]]
    if (!bad) return(NULL)
    sprintf("`%s` (%s) must %s `%s` (%s).", lo, format(p[[lo]]),
            if (strict) "be less than" else "not exceed", hi, format(p[[hi]]))
  }
}

c_all <- function(...) {
  constraints <- list(...)
  function(p) {
    for (f in constraints) {
      msg <- f(p)
      if (!is.null(msg)) return(msg)
    }
    NULL
  }
}

validate_params <- function(m, params, call = rlang::caller_env()) {
  for (nm in names(params)) {
    m$checks[[nm]](params[[nm]], arg = nm, call = call)
  }
  if (!is.null(m$constraint)) {
    msg <- m$constraint(params)
    if (!is.null(msg)) {
      cli::cli_abort(
        c("Invalid parameter combination for method {.val {m$name}}.", "x" = "{msg}"),
        class = "deriva_error_invalid_param", call = call
      )
    }
  }
  invisible(params)
}
