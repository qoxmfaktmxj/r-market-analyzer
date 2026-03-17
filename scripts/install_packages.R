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

if (length(missing_packages) == 0) {
  message("모든 필수 패키지가 이미 설치되어 있습니다.")
} else {
  default_library <- .libPaths()[1]
  library_writable <- file.access(default_library, 2) == 0

  if (!library_writable) {
    user_library <- Sys.getenv("R_LIBS_USER")

    if (!nzchar(user_library)) {
      major_minor <- paste(
        R.version$major,
        strsplit(R.version$minor, "\\.")[[1]][1],
        sep = "."
      )

      user_library <- file.path(
        Sys.getenv("LOCALAPPDATA"),
        "R",
        "win-library",
        major_minor
      )
    }

    dir.create(user_library, recursive = TRUE, showWarnings = FALSE)
    .libPaths(c(user_library, .libPaths()))
    target_library <- user_library
  } else {
    target_library <- default_library
  }

  message("패키지 설치 경로: ", target_library)

  install.packages(
    missing_packages,
    repos = "https://cloud.r-project.org",
    lib = target_library
  )
}
