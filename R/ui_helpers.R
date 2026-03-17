dashboard_alert <- function(message, type = c("info", "warning", "error")) {
  type <- match.arg(type)

  div(
    class = paste("dashboard-alert", paste0("alert-", type)),
    span(class = "alert-dot"),
    span(message)
  )
}

metric_card <- function(title, value, tone = "neutral") {
  div(
    class = paste("metric-card", paste0("tone-", tone)),
    div(class = "metric-label", title),
    div(class = "metric-value", value)
  )
}

metric_cards_ui <- function(summary_tbl) {
  div(
    class = "metric-grid",
    tagList(
      purrr::pmap(
        summary_tbl,
        function(metric, value, tone) {
          metric_card(metric, value, tone)
        }
      )
    )
  )
}

theme_market <- function() {
  theme_minimal(base_family = "Noto Sans KR") +
    theme(
      plot.background = element_rect(fill = "#ffffff", color = NA),
      panel.background = element_rect(fill = "#ffffff", color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "#e5e7eb", linewidth = 0.4),
      axis.text = element_text(color = "#4b5563", size = 10),
      axis.title = element_text(color = "#374151", size = 10),
      plot.title = element_text(color = "#111827", face = "bold", size = 13),
      legend.text = element_text(color = "#374151", size = 10),
      legend.position = "top",
      legend.key.width = grid::unit(18, "pt")
    )
}
