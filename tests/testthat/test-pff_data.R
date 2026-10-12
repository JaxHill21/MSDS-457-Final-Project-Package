sample_dir <- system.file("extdata", package = "bigtenperf")

test_that("get_pff_season keeps Big Ten members for the requested season", {
  players <- get_pff_season(2023, level = "player", data_dir = sample_dir)

  expect_equal(nrow(players), 2)
  expect_setequal(players$school_id, "michigan")
  expect_equal(attr(players, "pff_level"), "player")
  expect_true(file.exists(attr(players, "pff_source_file")))
})

test_that("get_pff_season applies 2024 membership for new members", {
  players <- get_pff_season(2023:2024, level = "player", data_dir = sample_dir)
  oregon <- players[players$school_id == "oregon", ]

  expect_equal(unique(oregon$season), 2024L)
})

test_that("get_pff_season can retain opponents", {
  players <- get_pff_season(2023, data_dir = sample_dir, include_opponents = TRUE)

  expect_equal(nrow(players), 4)
  expect_true("EAST CAROLINA" %in% players$team)
})

test_that("get_pff_season labels the revenue-sharing era", {
  teams <- get_pff_season(2024:2025, level = "team", data_dir = sample_dir)

  expect_equal(
    teams$revenue_sharing_era[teams$season == 2024],
    rep("pre_direct_sharing", sum(teams$season == 2024))
  )
  expect_equal(unique(teams$revenue_sharing_era[teams$season == 2025]), "direct_sharing")
})

test_that("get_pff_season validates its inputs", {
  expect_error(get_pff_season(2023.5, data_dir = sample_dir), "whole-number")
  expect_error(get_pff_season(2023, include_opponents = NA, data_dir = sample_dir), "TRUE or FALSE")
  expect_error(get_pff_season(2023, data_dir = tempdir()), "Could not find")
  expect_error(get_pff_season(2023, level = "coach", data_dir = sample_dir))
})

test_that("clean_pff_offense filters player rows to offense and snap minimum", {
  players <- get_pff_season(2023:2025, level = "player", data_dir = sample_dir)
  offense <- clean_pff_offense(players, min_snaps = 10)

  expect_equal(nrow(offense), 4)
  expect_true(all(offense$unit == "offense"))
  expect_true(all(offense$offense_snaps >= 10))
  expect_type(offense$offense_grade, "double")
  expect_equal(unique(offense$offense_level), "player")
  expect_true(all(offense$position == toupper(offense$position)))
})

test_that("clean_pff_offense accepts team-level data", {
  teams <- get_pff_season(2025, level = "team", data_dir = sample_dir)
  offense <- clean_pff_offense(teams, min_snaps = 50)

  expect_equal(nrow(offense), nrow(teams))
  expect_equal(unique(offense$offense_level), "team")
  expect_true(all(is.na(offense$offense_snaps)))
  expect_equal(offense$offense_grade, 86.2)
})

test_that("clean_pff_offense validates its inputs", {
  expect_error(clean_pff_offense(list(offense = 1)), "data frame")
  expect_error(clean_pff_offense(data.frame(offense = 1), min_snaps = -1), "non-negative")
  expect_error(clean_pff_offense(data.frame(grade = 1)), "`offense` grade column")
  expect_error(clean_pff_offense(data.frame(offense = 1)), "player-game grades")
})
