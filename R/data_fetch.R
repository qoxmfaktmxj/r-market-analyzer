clean_symbols <- function(symbols) {
  symbols |>
    as.character() |>
    trimws() |>
    toupper() |>
    purrr::discard(~ .x == "") |>
    unique()
}

period_to_start_date <- function(period, end_date = Sys.Date()) {
  switch(
    EXPR = period,
    "1개월" = end_date - 31,
    "3개월" = end_date - 92,
    "6개월" = end_date - 183,
    "1년" = end_date - 365,
    "3년" = end_date - (365 * 3),
    "전체" = as.Date("2000-01-01"),
    end_date - 365
  )
}

fetch_market_data <- function(symbol, from, to = Sys.Date()) {
  cleaned_symbol <- clean_symbols(symbol)

  if (length(cleaned_symbol) != 1) {
    return(list(
      success = FALSE,
      symbol = NA_character_,
      data = tibble::tibble(),
      error = "기준 종목 티커를 입력해 주세요. 예: AAPL, MSFT, BTC-USD"
    ))
  }

  cleaned_symbol <- cleaned_symbol[[1]]

  raw_data <- tryCatch(
    quantmod::getSymbols(
      Symbols = cleaned_symbol,
      src = "yahoo",
      from = from,
      to = to,
      auto.assign = FALSE,
      warnings = FALSE
    ),
    error = function(e) e
  )

  if (inherits(raw_data, "error")) {
    return(list(
      success = FALSE,
      symbol = cleaned_symbol,
      data = tibble::tibble(),
      error = paste0(
        cleaned_symbol,
        " 데이터를 불러오지 못했습니다. 티커 형식을 확인하거나 잠시 후 다시 시도해 주세요."
      )
    ))
  }

  adjusted_prices <- tryCatch(
    as.numeric(quantmod::Ad(raw_data)),
    error = function(e) as.numeric(quantmod::Cl(raw_data))
  )

  tidy_data <- tibble::tibble(
    date = as.Date(zoo::index(raw_data)),
    open = as.numeric(quantmod::Op(raw_data)),
    high = as.numeric(quantmod::Hi(raw_data)),
    low = as.numeric(quantmod::Lo(raw_data)),
    close = as.numeric(quantmod::Cl(raw_data)),
    volume = as.numeric(quantmod::Vo(raw_data)),
    adjusted = adjusted_prices
  ) |>
    dplyr::filter(!is.na(close)) |>
    dplyr::arrange(date) |>
    dplyr::mutate(symbol = cleaned_symbol, .before = 1)

  if (nrow(tidy_data) == 0) {
    return(list(
      success = FALSE,
      symbol = cleaned_symbol,
      data = tibble::tibble(),
      error = paste0(
        cleaned_symbol,
        " 에 대해 선택한 기간의 데이터를 찾지 못했습니다. 다른 기간 또는 다른 티커를 사용해 주세요."
      )
    ))
  }

  list(
    success = TRUE,
    symbol = cleaned_symbol,
    data = tidy_data,
    error = NULL
  )
}

fetch_market_bundle <- function(primary_symbol, comparison_symbols = NULL, from, to) {
  base_symbol <- clean_symbols(primary_symbol)

  if (length(base_symbol) == 0) {
    return(list(
      success = FALSE,
      error = "분석할 기준 종목 티커를 입력해 주세요.",
      warning = NULL,
      data = tibble::tibble(),
      base = tibble::tibble(),
      base_symbol = NA_character_,
      available_symbols = character()
    ))
  }

  base_symbol <- base_symbol[[1]]
  compare_symbols <- setdiff(clean_symbols(comparison_symbols), base_symbol)
  requested_symbols <- unique(c(base_symbol, compare_symbols))

  results <- purrr::map(requested_symbols, fetch_market_data, from = from, to = to)
  names(results) <- requested_symbols

  base_result <- results[[base_symbol]]

  if (!isTRUE(base_result$success)) {
    return(list(
      success = FALSE,
      error = base_result$error,
      warning = NULL,
      data = tibble::tibble(),
      base = tibble::tibble(),
      base_symbol = base_symbol,
      available_symbols = character()
    ))
  }

  success_results <- purrr::keep(results, ~ isTRUE(.x$success))
  failed_results <- purrr::keep(results, ~ !isTRUE(.x$success))

  warning_message <- NULL

  if (length(failed_results) > 0) {
    warning_message <- paste0(
      "일부 비교 종목 데이터를 불러오지 못했습니다: ",
      paste(names(failed_results), collapse = ", "),
      ". 나머지 종목으로 분석을 계속합니다."
    )
  }

  all_data <- purrr::map_dfr(success_results, "data")

  list(
    success = TRUE,
    error = NULL,
    warning = warning_message,
    data = all_data,
    base = base_result$data,
    base_symbol = base_symbol,
    available_symbols = unique(all_data$symbol)
  )
}
