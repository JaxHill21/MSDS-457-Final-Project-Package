#' Import cached PFF data for one or more seasons
#'
#' Reads the PFF CSV extracts produced by the project ingestion workflow and
#' returns either player-game grades or team-game grades. By default, rows are
#' limited to schools that were Big Ten members in that season; set
#' `include_opponents` to `TRUE` to retain opponents that appear in Big Ten
#' teams' games. The returned data also labels seasons from 2025 onward as the
#' direct institutional revenue-sharing era.
#'
#' @param season One or more season years, such as `c(2023, 2024)`.
#' @param level Either `"player"` for player-game grades or `"team"` for
#'   team-game grades.
#' @param data_dir Directory containing `big_ten_player_game_grades.csv` and
#'   `big_ten_team_game_grades.csv`. Defaults to `data/raw/pff` in the current
#'   working directory.
#' @param include_opponents If `FALSE`, keep only rows for Big Ten members in
#'   the requested season. Oregon, UCLA, USC, and Washington are treated as
#'   members beginning in 2024. If `TRUE`, retain all teams represented in the
#'   source extract.
#'
#' @returns A data frame containing the requested season rows, with the original
#'   PFF columns and a `revenue_sharing_era` column (`"pre_direct_sharing"` or
#'   `"direct_sharing"`). The source file and data level are also recorded as
#'   attributes.
#' @export
get_pff_season <- function(season,
                           level = c("player", "team"),
                           data_dir = file.path("data", "raw", "pff"),
                           include_opponents = FALSE) {
  level <- match.arg(level)

  if (!is.numeric(season) || length(season) == 0L ||
      anyNA(season) || any(season != as.integer(season))) {
    stop("`season` must contain one or more whole-number season years.", call. = FALSE)
  }
  if (!is.logical(include_opponents) || length(include_opponents) != 1L ||
      is.na(include_opponents)) {
    stop("`include_opponents` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.character(data_dir) || length(data_dir) != 1L || is.na(data_dir) ||
      !nzchar(data_dir)) {
    stop("`data_dir` must be one non-empty path.", call. = FALSE)
  }

  file_name <- if (level == "player") {
    "big_ten_player_game_grades.csv"
  } else {
    "big_ten_team_game_grades.csv"
  }
  file_path <- file.path(data_dir, file_name)
  if (!file.exists(file_path)) {
    stop(
      sprintf("Could not find %s. Set `data_dir` to the directory containing the PFF CSV extracts.", file_name),
      call. = FALSE
    )
  }

  data <- utils::read.csv(
    file_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA", "NULL")
  )
  if (!"season" %in% names(data)) {
    stop(sprintf("The file %s has no `season` column.", file_name), call. = FALSE)
  }
  if (!"school_id" %in% names(data)) {
    stop(sprintf("The file %s has no `school_id` column for identifying Big Ten teams.", file_name), call. = FALSE)
  }

  data$season <- suppressWarnings(as.integer(as.character(data$season)))
  data <- data[!is.na(data$season) & data$season %in% as.integer(season), , drop = FALSE]

  if (!include_opponents) {
    school_id <- as.character(data$school_id)
    current_member <- !is.na(school_id) & nzchar(school_id)
    recent_joiners <- c("oregon", "ucla", "usc", "washington")
    membership_start <- ifelse(school_id %in% recent_joiners, 2024L, 2014L)
    data <- data[current_member & data$season >= membership_start, , drop = FALSE]
  }
  data$revenue_sharing_era <- ifelse(
    data$season >= 2025L,
    "direct_sharing",
    "pre_direct_sharing"
  )
  rownames(data) <- NULL
  attr(data, "pff_source_file") <- normalizePath(file_path, mustWork = TRUE)
  attr(data, "pff_level") <- level
  data
}

#' Prepare player- or team-level offensive PFF grades
#'
#' Filters player-grade extracts to offensive rows and adds common columns for
#' the offense grade, level, and snap count. Team-game grade extracts are also
#' accepted and receive the same `offense_grade` column. Season, week, grade,
#' and identifier columns are converted to consistent types. Other source
#' columns are retained so callers can choose the metrics needed for analysis.
#'
#' @param data A data frame returned by [get_pff_season()] or a compatible PFF
#'   grade extract.
#' @param min_snaps Minimum player snaps to retain. This applies only to
#'   player-level data; team-level data are returned unchanged by this filter.
#'
#' @returns A cleaned data frame with `offense_level`, numeric
#'   `offense_grade`, and numeric `offense_snaps` columns, plus the original
#'   fields. For team-level data, `offense_snaps` is `NA` because the team-grade
#'   extract does not report a corresponding team snap count.
#' @export
clean_pff_offense <- function(data, min_snaps = 0) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.numeric(min_snaps) || length(min_snaps) != 1L || is.na(min_snaps) ||
      min_snaps < 0) {
    stop("`min_snaps` must be one non-negative number.", call. = FALSE)
  }
  if (!"offense" %in% names(data)) {
    stop("The input must contain an `offense` grade column.", call. = FALSE)
  }

  is_player_data <- all(c("unit", "player_id") %in% names(data))
  is_team_data <- !is_player_data && all(c("team", "game_id") %in% names(data))
  if (!is_player_data && !is_team_data) {
    stop(
      "Input must be player-game grades (with `unit` and `player_id`) or team-game grades (with `team` and `game_id`).",
      call. = FALSE
    )
  }

  if (is_player_data) {
    keep <- !is.na(data$unit) & tolower(as.character(data$unit)) == "offense"
    data <- data[keep, , drop = FALSE]
    data$offense_level <- "player"
    if ("overall_snaps" %in% names(data)) {
      data$offense_snaps <- suppressWarnings(as.numeric(as.character(data$overall_snaps)))
      data <- data[is.na(data$offense_snaps) | data$offense_snaps >= min_snaps, , drop = FALSE]
    } else if (min_snaps > 0) {
      stop("Player data has no `overall_snaps` column for applying `min_snaps`.", call. = FALSE)
    } else {
      data$offense_snaps <- NA_real_
    }
  } else {
    data$offense_level <- "team"
    data$offense_snaps <- NA_real_
  }

  data$offense_grade <- suppressWarnings(as.numeric(as.character(data$offense)))
  for (id_column in intersect(c("player_id", "team_id", "franchise_id", "game_id"), names(data))) {
    data[[id_column]] <- as.character(data[[id_column]])
  }
  if ("season" %in% names(data)) data$season <- suppressWarnings(as.integer(as.character(data$season)))
  if ("week" %in% names(data)) data$week <- suppressWarnings(as.integer(as.character(data$week)))
  if ("position" %in% names(data)) data$position <- toupper(as.character(data$position))

  rownames(data) <- NULL
  data
}
