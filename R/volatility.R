compute_daily_returns <- function(data) {
  data |>
    dplyr::arrange(date) |>
    dplyr::mutate(daily_return = close / dplyr::lag(close) - 1) |>
    dplyr::filter(!is.na(daily_return))
}

empty_volatility_summary <- function() {
  tibble::tibble(
    metric = c("일간 변동성", "연환산 변동성", "평균 일간 수익률", "최대 상승일", "최대 하락일"),
    value = c("계산 불가", "계산 불가", "계산 불가", "데이터 부족", "데이터 부족"),
    tone = c("neutral", "primary", "neutral", "positive", "negative")
  )
}

summarize_volatility <- function(data) {
  returns <- compute_daily_returns(data)

  if (nrow(returns) < 2) {
    return(empty_volatility_summary())
  }

  highest_gain <- returns |>
    dplyr::slice_max(order_by = daily_return, n = 1, with_ties = FALSE)

  biggest_drop <- returns |>
    dplyr::slice_min(order_by = daily_return, n = 1, with_ties = FALSE)

  tibble::tibble(
    metric = c("일간 변동성", "연환산 변동성", "평균 일간 수익률", "최대 상승일", "최대 하락일"),
    value = c(
      scales::percent(stats::sd(returns$daily_return), accuracy = 0.01),
      scales::percent(stats::sd(returns$daily_return) * sqrt(252), accuracy = 0.01),
      scales::percent(mean(returns$daily_return), accuracy = 0.01),
      paste0(format(highest_gain$date, "%Y-%m-%d"), " · ", scales::percent(highest_gain$daily_return, accuracy = 0.01)),
      paste0(format(biggest_drop$date, "%Y-%m-%d"), " · ", scales::percent(biggest_drop$daily_return, accuracy = 0.01))
    ),
    tone = c("neutral", "primary", "neutral", "positive", "negative")
  )
}
