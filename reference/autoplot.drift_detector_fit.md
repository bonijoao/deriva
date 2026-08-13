# Plot the monitored signal with drift markings

Plots the running mean of the signal over the full history, with the
baseline/stream boundary (labelled "training ends"), warning points
(orange) and drift points (red vertical lines, the first one labelled
with its index). Requires ggplot2 (Suggests).

## Usage

``` r
# S3 method for class 'drift_detector_fit'
autoplot(object, ...)
```

## Arguments

- object:

  A `drift_detector_fit`.

- ...:

  Not used.

## Value

A ggplot object.
