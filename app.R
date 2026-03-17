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
    paste0(
      "필수 패키지가 설치되어 있지 않습니다: ",
      paste(missing_packages, collapse = ", "),
      "\nREADME.md 또는 scripts/install_packages.R를 참고해 패키지를 설치한 뒤 다시 실행해 주세요."
    ),
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

app_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
helper_files <- list.files(
  file.path(app_root, "R"),
  pattern = "\\.R$",
  full.names = TRUE
)

invisible(lapply(helper_files, source))

example_tickers <- c("AAPL", "MSFT", "TSLA", "NVDA", "BTC-USD", "ETH-USD")
period_options <- c("1개월", "3개월", "6개월", "1년", "3년", "전체")
moving_average_choices <- c("5일" = 5, "20일" = 20, "60일" = 60, "120일" = 120)

ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#f3f5f8",
    fg = "#1f2937",
    primary = "#1f4fa3",
    secondary = "#6b7280",
    base_font = font_google("Noto Sans KR"),
    heading_font = font_google("IBM Plex Sans")
  ),
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  div(
    class = "dashboard-shell",
    div(
      class = "hero-section",
      div(
        class = "hero-copy",
        div(class = "eyebrow", "Portfolio Project"),
        h1("R Market Analyzer"),
        p(
          "주식과 코인 시세를 한 화면에서 조회하고, 이동평균선·변동성·기간 수익률을 함께 확인할 수 있는 Shiny 대시보드입니다."
        )
      ),
      div(
        class = "hero-meta",
        div(class = "hero-meta-label", "데이터 소스"),
        div(class = "hero-meta-value", "Yahoo Finance"),
        div(class = "hero-meta-caption", "티커 입력 기반 실시간 조회")
      )
    ),
    div(
      class = "card-panel controls-panel",
      div(
        class = "panel-header",
        div(
          class = "panel-title-wrap",
          h3("조회 설정"),
          p("예시 티커를 바로 선택하거나 직접 입력해 분석을 시작할 수 있습니다.")
        )
      ),
      fluidRow(
        column(
          width = 4,
          selectizeInput(
            inputId = "primary_symbol",
            label = "기준 종목",
            choices = example_tickers,
            selected = "AAPL",
            multiple = FALSE,
            options = list(
              create = TRUE,
              persist = FALSE,
              placeholder = "예: AAPL 또는 BTC-USD"
            )
          )
        ),
        column(
          width = 4,
          selectizeInput(
            inputId = "comparison_symbols",
            label = "비교 종목",
            choices = example_tickers,
            selected = c("MSFT", "BTC-USD"),
            multiple = TRUE,
            options = list(
              create = TRUE,
              persist = FALSE,
              placeholder = "비교할 종목을 선택하거나 입력하세요"
            )
          )
        ),
        column(
          width = 2,
          selectInput(
            inputId = "period",
            label = "조회 기간",
            choices = period_options,
            selected = "1년"
          )
        ),
        column(
          width = 2,
          checkboxGroupInput(
            inputId = "moving_averages",
            label = "이동평균선",
            choices = moving_average_choices,
            selected = c(20, 60)
          )
        )
      ),
      div(
        class = "control-hint",
        "예시 티커: AAPL, MSFT, TSLA, BTC-USD, ETH-USD"
      )
    ),
    uiOutput("status_message"),
    fluidRow(
      column(
        width = 8,
        div(
          class = "card-panel chart-panel",
          div(
            class = "panel-header",
            div(
              class = "panel-title-wrap",
              h3("가격 차트"),
              div(
                class = "panel-subtitle",
                textOutput("price_caption", inline = TRUE)
              )
            )
          ),
          plotOutput("price_chart", height = "380px")
        )
      ),
      column(
        width = 4,
        div(
          class = "card-panel summary-panel",
          div(
            class = "panel-header",
            div(
              class = "panel-title-wrap",
              h3("변동성 분석"),
              p("일간 수익률 기준 요약 지표")
            )
          ),
          uiOutput("volatility_cards")
        )
      )
    ),
    fluidRow(
      column(
        width = 7,
        div(
          class = "card-panel chart-panel",
          div(
            class = "panel-header",
            div(
              class = "panel-title-wrap",
              h3("정규화 가격 비교"),
              p("기간 시작 시점을 100으로 맞춘 상대 성과 비교")
            )
          ),
          plotOutput("normalized_chart", height = "320px")
        )
      ),
      column(
        width = 5,
        div(
          class = "card-panel chart-panel",
          div(
            class = "panel-header",
            div(
              class = "panel-title-wrap",
              h3("기간 수익률 비교"),
              p("기준 종목과 비교 종목의 누적 수익률")
            )
          ),
          plotOutput("returns_chart", height = "320px")
        )
      )
    ),
    div(
      class = "card-panel table-panel",
      div(
        class = "panel-header",
        div(
          class = "panel-title-wrap",
          h3("수익률 비교 테이블"),
          p("조회 기간 기준 시작가·종료가·누적 수익률 요약")
        )
      ),
      DTOutput("returns_table")
    )
  )
)

server <- function(input, output, session) {
  selected_period <- reactive({
    end_date <- Sys.Date()

    list(
      label = input$period,
      start = period_to_start_date(input$period, end_date),
      end = end_date
    )
  })

  market_bundle <- reactive({
    req(input$primary_symbol)

    withProgress(message = "시장 데이터를 불러오는 중입니다...", value = 0.2, {
      bundle <- fetch_market_bundle(
        primary_symbol = input$primary_symbol,
        comparison_symbols = input$comparison_symbols,
        from = selected_period()$start,
        to = selected_period()$end
      )

      incProgress(0.8)
      bundle
    })
  })

  base_data <- reactive({
    bundle <- market_bundle()
    validate(need(bundle$success, bundle$error))

    add_moving_averages(bundle$base)
  })

  output$status_message <- renderUI({
    bundle <- market_bundle()

    if (!bundle$success) {
      return(dashboard_alert(bundle$error, type = "error"))
    }

    if (!is.null(bundle$warning)) {
      return(dashboard_alert(bundle$warning, type = "warning"))
    }

    dashboard_alert(
      paste0(
        bundle$base_symbol,
        " 포함 ",
        length(bundle$available_symbols),
        "개 종목 데이터를 분석 중입니다. 조회 기간: ",
        format(selected_period()$start, "%Y-%m-%d"),
        " ~ ",
        format(selected_period()$end, "%Y-%m-%d")
      ),
      type = "info"
    )
  })

  output$price_caption <- renderText({
    bundle <- market_bundle()
    validate(need(bundle$success, bundle$error))

    latest_row <- dplyr::last(arrange(bundle$base, date))

    paste0(
      bundle$base_symbol,
      " · 최근 종가 ",
      scales::number(latest_row$close, accuracy = 0.01),
      " · ",
      format(selected_period()$start, "%Y-%m-%d"),
      " ~ ",
      format(selected_period()$end, "%Y-%m-%d")
    )
  })

  output$price_chart <- renderPlot({
    data <- base_data()
    selected_windows <- sort(as.numeric(input$moving_averages))

    base_line <- data |>
      transmute(date = date, value = close, series = "종가")

    if (length(selected_windows) > 0) {
      ma_lines <- prepare_moving_average_lines(data, selected_windows)
      plot_data <- bind_rows(base_line, ma_lines)
    } else {
      plot_data <- base_line
    }

    color_map <- c(
      "종가" = "#0f172a",
      "5일 MA" = "#1d4ed8",
      "20일 MA" = "#0ea5e9",
      "60일 MA" = "#10b981",
      "120일 MA" = "#f59e0b"
    )

    ggplot(plot_data, aes(x = date, y = value, color = series)) +
      geom_line(linewidth = 0.95, na.rm = TRUE) +
      scale_color_manual(values = color_map, breaks = unique(plot_data$series)) +
      scale_x_date(date_labels = "%Y-%m", date_breaks = "2 months") +
      scale_y_continuous(labels = label_number(big.mark = ",", accuracy = 0.01)) +
      labs(x = NULL, y = "종가", color = NULL) +
      theme_market() +
      theme(legend.position = "top")
  })

  output$volatility_cards <- renderUI({
    bundle <- market_bundle()

    validate(need(bundle$success, bundle$error))

    summary_tbl <- summarize_volatility(bundle$base)

    tagList(
      metric_cards_ui(summary_tbl),
      div(
        class = "summary-footnote",
        "연환산 변동성은 252거래일 기준으로 계산했습니다."
      )
    )
  })

  output$normalized_chart <- renderPlot({
    bundle <- market_bundle()

    validate(need(bundle$success, bundle$error))

    normalized_data <- normalize_prices(bundle$data)

    ggplot(normalized_data, aes(x = date, y = normalized_price, color = symbol)) +
      geom_line(linewidth = 0.95, na.rm = TRUE) +
      scale_x_date(date_labels = "%Y-%m", date_breaks = "2 months") +
      scale_y_continuous(labels = label_number(accuracy = 1)) +
      labs(x = NULL, y = "정규화 가격 (시작=100)", color = NULL) +
      theme_market() +
      theme(legend.position = "top")
  })

  output$returns_chart <- renderPlot({
    bundle <- market_bundle()

    validate(need(bundle$success, bundle$error))

    summary_tbl <- summarize_period_returns(bundle$data) |>
      mutate(
        group = if_else(symbol == bundle$base_symbol, "기준 종목", "비교 종목"),
        symbol = reorder(symbol, total_return)
      )

    ggplot(summary_tbl, aes(x = symbol, y = total_return, fill = group)) +
      geom_col(width = 0.65) +
      geom_text(
        aes(label = percent(total_return, accuracy = 0.01)),
        hjust = ifelse(summary_tbl$total_return >= 0, -0.1, 1.1),
        size = 3.5,
        color = "#111827"
      ) +
      coord_flip() +
      scale_fill_manual(values = c("기준 종목" = "#1f4fa3", "비교 종목" = "#cbd5e1")) +
      scale_y_continuous(
        labels = percent_format(accuracy = 1),
        expand = expansion(mult = c(0.05, 0.15))
      ) +
      labs(x = NULL, y = "누적 수익률", fill = NULL) +
      theme_market() +
      theme(legend.position = "top")
  })

  output$returns_table <- renderDT({
    bundle <- market_bundle()

    validate(need(bundle$success, bundle$error))

    table_data <- summarize_period_returns(bundle$data) |>
      mutate(
        `시작일` = format(start_date, "%Y-%m-%d"),
        `종료일` = format(end_date, "%Y-%m-%d"),
        `시작가` = scales::number(start_price, accuracy = 0.01, big.mark = ","),
        `종료가` = scales::number(end_price, accuracy = 0.01, big.mark = ","),
        `기간 수익률` = scales::percent(total_return, accuracy = 0.01)
      ) |>
      transmute(
        `종목` = symbol,
        `시작일`,
        `종료일`,
        `시작가`,
        `종료가`,
        `기간 수익률`,
        `관측치` = observations
      )

    datatable(
      table_data,
      rownames = FALSE,
      class = "stripe hover compact",
      options = list(
        dom = "t",
        ordering = FALSE,
        autoWidth = TRUE,
        pageLength = max(5, nrow(table_data))
      )
    )
  })
}

shinyApp(ui = ui, server = server)
