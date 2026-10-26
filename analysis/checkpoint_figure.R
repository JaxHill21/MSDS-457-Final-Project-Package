# Module 5 checkpoint figure: Big Ten team-season offensive grades by season
#
# Reads the local PFF team-game extract with get_pff_season(), averages each
# Big Ten school's game grades within a season, and plots six offensive grades
# from 2014 to 2026 with the direct revenue-sharing era (2025 onward) shaded.
#
# The PFF extract is not part of the repository. By default it is read from
# data/raw/pff/big_ten_team_game_grades.csv in the package folder, which git
# ignores; change `pff_dir` if it is elsewhere. The figure is written to
# analysis/figures/, which is also kept out of version control because it is
# built from PFF grades.
#
# Run from the package root (the folder with DESCRIPTION), for example by
# opening the project in RStudio and sourcing this file.

library(ggplot2)

# Load the development version of the package so get_pff_season() and
# clean_pff_offense() are available without installing it
devtools::load_all(".", quiet = TRUE)

pff_dir <- file.path("data", "raw", "pff")
out_dir <- file.path("analysis", "figures")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Team-game grades for Big Ten members only (opponents are dropped by default)
team_games <- get_pff_season(2014:2026, level = "team", data_dir = pff_dir)
team_games <- clean_pff_offense(team_games)

# Latest week of the in-progress 2026 season, for the caption
last_week_2026 <- max(team_games$week[team_games$season == 2026], na.rm = TRUE)

# Offensive grades to show, with panel labels
grade_labels <- c(
  offense    = "Overall offense",
  pass       = "Passing",
  pass_route = "Receiving",
  pass_block = "Pass blocking",
  run        = "Rushing",
  run_block  = "Run blocking"
)

# Average each school's game grades within a season
team_season <- aggregate(
  team_games[names(grade_labels)],
  by = team_games[c("school_id", "season", "revenue_sharing_era")],
  FUN = mean,
  na.rm = TRUE
)

# Long format: one row per school, season and grade
team_season_long <- data.frame(
  school_id = rep(team_season$school_id, times = length(grade_labels)),
  season = rep(team_season$season, times = length(grade_labels)),
  era = rep(team_season$revenue_sharing_era, times = length(grade_labels)),
  grade_name = rep(names(grade_labels), each = nrow(team_season)),
  grade = unlist(team_season[names(grade_labels)], use.names = FALSE)
)
team_season_long$grade_name <- factor(
  team_season_long$grade_name,
  levels = names(grade_labels),
  labels = grade_labels
)
team_season_long$era <- factor(
  team_season_long$era,
  levels = c("pre_direct_sharing", "direct_sharing"),
  labels = c("Before direct sharing (2014-2024)", "Direct sharing (2025-2026)")
)
# 2026 is in progress, so its points are drawn hollow
team_season_long$partial_season <- team_season_long$season == 2026

# Conference mean of the team-season grades, by season
season_means <- aggregate(
  grade ~ season + grade_name,
  data = team_season_long,
  FUN = mean
)
season_means$partial_season <- season_means$season == 2026

# Colors: gray for the earlier era, blue for the revenue-sharing era
era_colors <- c(
  "Before direct sharing (2014-2024)" = "#9a9893",
  "Direct sharing (2025-2026)" = "#2a78d6"
)
ink_primary <- "#0b0b0b"
ink_secondary <- "#52514e"
grid_color <- "#e4e3df"

set.seed(457)

checkpoint_plot <- ggplot(team_season_long, aes(x = season, y = grade)) +
  # Shade the revenue-sharing era
  annotate(
    "rect",
    xmin = 2024.5, xmax = 2026.5, ymin = -Inf, ymax = Inf,
    fill = "#2a78d6", alpha = 0.08
  ) +
  geom_jitter(
    aes(color = era, shape = partial_season),
    width = 0.18, height = 0,
    size = 1.1, alpha = 0.75, stroke = 0.5
  ) +
  # Completed seasons as a solid line; the step to partial 2026 is dashed
  geom_line(
    data = subset(season_means, season <= 2025),
    color = ink_primary, linewidth = 0.6
  ) +
  geom_line(
    data = subset(season_means, season >= 2025),
    color = ink_primary, linewidth = 0.6, linetype = "22"
  ) +
  geom_point(
    data = season_means,
    aes(shape = partial_season),
    color = ink_primary, fill = "white", size = 1.4, stroke = 0.7
  ) +
  facet_wrap(~ grade_name, ncol = 3) +
  scale_x_continuous(
    breaks = c(2015, 2020, 2025),
    limits = c(2013.5, 2026.5),
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(40, 90, by = 10)) +
  scale_color_manual(values = era_colors, name = NULL) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 21), guide = "none") +
  labs(
    title = "Big Ten team-season offensive grades, 2014-2026",
    subtitle = paste(
      "Each dot is one school's average PFF game grade for a season;",
      "the line is the conference mean."
    ),
    x = NULL,
    y = "PFF grade (0-100)",
    caption = paste0(
      "Shading marks the direct revenue-sharing era. 2026 (hollow points, ",
      "dashed line) covers games through week ", last_week_2026, " only.\n",
      "Schools are Big Ten members as of each season (14 through 2023, ",
      "18 from 2024). Source: PFF college team-game grades."
    )
  ) +
  guides(color = guide_legend(override.aes = list(size = 2.5, alpha = 1))) +
  theme_minimal(base_size = 9) +
  theme(
    plot.title = element_text(face = "bold", size = 11, color = ink_primary),
    plot.subtitle = element_text(color = ink_secondary, margin = margin(b = 6)),
    plot.caption = element_text(color = ink_secondary, hjust = 0, size = 7),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    strip.text = element_text(face = "bold", hjust = 0, color = ink_primary),
    axis.text = element_text(color = ink_secondary),
    axis.title.y = element_text(color = ink_secondary),
    panel.grid.major = element_line(color = grid_color, linewidth = 0.3),
    panel.grid.minor = element_blank(),
    panel.spacing.x = unit(12, "pt"),
    legend.position = "top",
    legend.justification = "left",
    legend.margin = margin(0, 0, 0, 0),
    legend.box.spacing = unit(2, "pt"),
    plot.background = element_rect(fill = "white", color = NA)
  )

print(checkpoint_plot)

# 6.5 inches fits the text width of a Word page with 1-inch margins
ggsave(
  file.path(out_dir, "checkpoint_offense_grades_by_season.png"),
  checkpoint_plot, width = 6.5, height = 4.6, dpi = 300
)
ggsave(
  file.path(out_dir, "checkpoint_offense_grades_by_season.pdf"),
  checkpoint_plot, width = 6.5, height = 4.6
)
