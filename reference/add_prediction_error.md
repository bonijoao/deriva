# Build a drift signal from model predictions

Bridge from tidymodels: takes the output of
[`augment()`](https://generics.r-lib.org/reference/augment.html) on a
fitted workflow/model and adds a `.error` column — the signal drift
detectors consume. Classification (factor/character truth): 0/1 mismatch
against `estimate` (default column `.pred_class`). Regression (numeric
truth): absolute error against `estimate` (default column `.pred`).

## Usage

``` r
add_prediction_error(data, truth, estimate = NULL, ...)
```

## Arguments

- data:

  A data frame with truth and prediction columns.

- truth:

  Unquoted name of the true outcome column.

- estimate:

  Unquoted name of the prediction column. Defaults to `.pred_class`
  (classification) or `.pred` (regression), following tidymodels
  conventions.

- ...:

  Not used.

## Value

`data` as a tibble with a `.error` column added.

## Examples

``` r
d <- tibble::tibble(truth = c(1, 2, 3), .pred = c(1, 1, 5))
add_prediction_error(d, truth = truth)
#> # A tibble: 3 × 3
#>   truth .pred .error
#>   <dbl> <dbl>  <dbl>
#> 1     1     1      0
#> 2     2     1      1
#> 3     3     5      2
```
