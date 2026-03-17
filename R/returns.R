summarize_period_returns <- function(data) {
  data |>
    dplyr::group_by(symbol) |>
    dplyr::arrange(date, .by_group = TRUE) |>
    dplyr::summarise(
      start_date = dplyr::first(date),
      end_date = dplyr::last(date),
      start_price = dplyr::first(close),
      end_price = dplyr::last(close),
      total_return = (dplyr::last(close) / dplyr::first(close)) - 1,
      observations = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(total_return))
}

normalize_prices <- function(data) {
  data |>
    dplyr::group_by(symbol) |>
    dplyr::arrange(date, .by_group = TRUE) |>
    dplyr::mutate(normalized_price = 100 * close / dplyr::first(close)) |>
    dplyr::ungroup()
}
