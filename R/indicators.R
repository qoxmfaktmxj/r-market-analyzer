add_moving_averages <- function(data, windows = c(5, 20, 60, 120)) {
  enriched_data <- data

  for (window in windows) {
    enriched_data[[paste0("ma_", window)]] <- TTR::SMA(enriched_data$close, n = window)
  }

  enriched_data
}

prepare_moving_average_lines <- function(data, selected_windows) {
  if (length(selected_windows) == 0) {
    return(tibble::tibble())
  }

  selected_columns <- paste0("ma_", selected_windows)

  data |>
    dplyr::select(date, dplyr::any_of(selected_columns)) |>
    tidyr::pivot_longer(
      cols = -date,
      names_to = "series",
      values_to = "value"
    ) |>
    dplyr::filter(!is.na(value)) |>
    dplyr::mutate(series = paste0(gsub("ma_", "", series), "일 MA"))
}
