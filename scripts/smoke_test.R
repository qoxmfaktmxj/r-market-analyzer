required_packages <- c(
  "shiny",
  "bslib",
  "dplyr",
  "purrr",
  "tidyr",
  "tibble",
  "ggplot2",
  "quantmod",
  "TTR",
  "scales",
  "DT"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    paste("필수 패키지가 없습니다:", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(purrr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(quantmod)
  library(TTR)
  library(scales)
  library(DT)
})

helper_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
invisible(lapply(helper_files, source))

sample_bundle <- fetch_market_bundle(
  primary_symbol = "AAPL",
  comparison_symbols = c("MSFT", "BTC-USD"),
  from = Sys.Date() - 180,
  to = Sys.Date()
)

stopifnot(isTRUE(sample_bundle$success))
stopifnot(nrow(sample_bundle$base) > 20)

base_with_ma <- add_moving_averages(sample_bundle$base)
volatility_summary <- summarize_volatility(sample_bundle$base)
return_summary <- summarize_period_returns(sample_bundle$data)
normalized_series <- normalize_prices(sample_bundle$data)

stopifnot(all(c("ma_5", "ma_20", "ma_60", "ma_120") %in% names(base_with_ma)))
stopifnot(nrow(volatility_summary) == 5)
stopifnot(nrow(return_summary) >= 1)
stopifnot("normalized_price" %in% names(normalized_series))

app_env <- new.env(parent = globalenv())
sys.source("app.R", envir = app_env)

stopifnot(is.function(app_env$server))
stopifnot(
  inherits(app_env$ui, "shiny.tag") ||
    inherits(app_env$ui, "shiny.tag.list")
)

message("Smoke test passed.")
