test_that("big_ten_roster_profiles has the documented structure", {
  data <- big_ten_roster_profiles

  expect_s3_class(data, "data.frame")
  expect_equal(dim(data), c(231L, 11L))
  expect_equal(anyDuplicated(data[, c("school_id", "season")]), 0L)
  expect_setequal(range(data$season), c(2014L, 2026L))
  expect_equal(length(unique(data$school_id)), 18L)
})

test_that("big_ten_roster_profiles membership and shares are consistent", {
  data <- big_ten_roster_profiles
  joiners <- data$school_id %in% c("oregon", "ucla", "usc", "washington")

  expect_false(any(data$big_ten_member[joiners & data$season < 2024]))
  expect_true(all(data$big_ten_member[!joiners | data$season >= 2024]))
  for (column in c("pct_upperclassmen", "pct_in_state", "pct_previous_school")) {
    values <- data[[column]][!is.na(data[[column]])]
    expect_true(all(values >= 0 & values <= 1), info = column)
  }
})
