## Build `big_ten_roster_profiles` from the scraped school-site rosters.
##
## Source: data/raw/rosters/big_ten_rosters.csv in the football_recruiting_efficiency
## project (one row per player per season, scraped from each school's athletics
## site). The player-level file is not included in this package; only the
## school-season summaries below are. Set BIGTEN_PROJECT_DIR to the project
## folder before running.

project_dir <- Sys.getenv(
  "BIGTEN_PROJECT_DIR",
  file.path("~", "Downloads", "football_recruiting_efficiency")
)
rosters <- utils::read.csv(
  file.path(project_dir, "data", "raw", "rosters", "big_ten_rosters.csv"),
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
rosters <- rosters[rosters$season >= 2014, ]

# Class standing: schools label class year in about 30 different ways
# ("R-Jr.", "Redshirt Junior", "3rd", "Gr.+", ...). Redshirt markers are
# dropped so the value reflects academic class, with graduate/fifth-year and
# beyond grouped together.
class_year <- tolower(trimws(rosters$class_year))
class_year <- trimws(gsub("[*+]", "", class_year))
class_year <- sub("^(r-|rs\\.? |redshirt )", "", class_year)
class_levels <- c(
  "fr." = 1, "freshman" = 1, "fy." = 1, "1st" = 1,
  "so." = 2, "sophomore" = 2, "2nd" = 2,
  "jr." = 3, "junior" = 3, "3rd" = 3,
  "sr." = 4, "senior" = 4, "4th" = 4,
  "gr." = 5, "graduate student" = 5, "5th" = 5, "fifth" = 5,
  "fifth year" = 5, "6th" = 5, "sixth year" = 5, "7th" = 5
)
rosters$class_level <- unname(class_levels[class_year])

# In-state: compare the state in "City, State" hometowns to the school's state.
# Schools use AP abbreviations, postal codes and full names interchangeably.
# Hometowns without a comma (about 90 rows) are treated as unknown.
school_state <- c(
  illinois = "IL", indiana = "IN", iowa = "IA", maryland = "MD",
  michigan = "MI", michigan_state = "MI", minnesota = "MN", nebraska = "NE",
  northwestern = "IL", ohio_state = "OH", oregon = "OR", penn_state = "PA",
  purdue = "IN", rutgers = "NJ", ucla = "CA", usc = "CA", washington = "WA",
  wisconsin = "WI"
)
state_spellings <- list(
  CA = c("calif.", "calif", "ca", "california"),
  IL = c("ill.", "ill", "il", "illinois"),
  IN = c("ind.", "ind", "in", "indiana"),
  IA = c("iowa", "ia"),
  MD = c("md.", "md", "maryland"),
  MI = c("mich.", "mich", "mi", "michigan"),
  MN = c("minn.", "minn", "mn", "minnesota"),
  NE = c("neb.", "neb", "nebr.", "ne", "nebraska"),
  NJ = c("n.j.", "nj", "new jersey"),
  OH = c("ohio", "oh"),
  OR = c("ore.", "ore", "or", "oregon"),
  PA = c("pa.", "pa", "penn.", "pennsylvania"),
  WA = c("wash.", "wash", "wa", "washington"),
  WI = c("wis.", "wis", "wisc.", "wisc", "wi", "wisconsin")
)
hometown_state <- ifelse(
  grepl(",", rosters$hometown),
  tolower(trimws(sub("^[^,]*,", "", rosters$hometown))),
  NA_character_
)
hometown_state <- trimws(sub("[/(].*$", "", hometown_state))
rosters$in_state <- mapply(
  function(state, school) {
    if (is.na(state)) return(NA)
    state %in% state_spellings[[school_state[[school]]]]
  },
  hometown_state,
  rosters$school_id,
  USE.NAMES = FALSE
)

# Implausible measurements (data-entry errors) are excluded from the averages.
height <- rosters$height_total_inches
rosters$height_in <- ifelse(height >= 60 & height <= 84, height, NA_real_)
weight <- rosters$weight_lbs
rosters$weight_lbs_clean <- ifelse(weight >= 140 & weight <= 420, weight, NA_real_)

share <- function(x) if (all(is.na(x))) NA_real_ else round(mean(x, na.rm = TRUE), 3)

# Previous school is not filled in consistently: some school-seasons leave it
# blank for everyone (e.g. Nebraska 2014-2025), and Ohio State's pages put the
# high school there. Shares of 0 or above 0.9 are treated as not reported.
previous_school_share <- function(previous_school) {
  value <- round(mean(!is.na(previous_school)), 3)
  if (value == 0 || value > 0.9) NA_real_ else value
}

groups <- split(rosters, list(rosters$school_id, rosters$season), drop = TRUE)
big_ten_roster_profiles <- do.call(rbind, lapply(groups, function(team) {
  data.frame(
    school_id = team$school_id[1],
    school_name = team$school_name[1],
    season = as.integer(team$season[1]),
    roster_size = nrow(team),
    avg_height_in = round(mean(team$height_in, na.rm = TRUE), 1),
    avg_weight_lbs = round(mean(team$weight_lbs_clean, na.rm = TRUE), 1),
    pct_upperclassmen = share(team$class_level >= 3),
    pct_in_state = share(team$in_state),
    pct_previous_school = previous_school_share(team$previous_school),
    stringsAsFactors = FALSE
  )
}))

# Oregon, UCLA, USC and Washington joined the Big Ten in 2024; every other
# school was a member for all seasons in the data.
recent_joiners <- c("oregon", "ucla", "usc", "washington")
big_ten_roster_profiles$big_ten_member <- with(
  big_ten_roster_profiles,
  !(school_id %in% recent_joiners & season < 2024)
)
big_ten_roster_profiles$revenue_sharing_era <- ifelse(
  big_ten_roster_profiles$season >= 2025L,
  "direct_sharing",
  "pre_direct_sharing"
)

big_ten_roster_profiles <- big_ten_roster_profiles[
  order(big_ten_roster_profiles$school_id, big_ten_roster_profiles$season),
  c("school_id", "school_name", "season", "big_ten_member",
    "revenue_sharing_era", "roster_size", "avg_height_in", "avg_weight_lbs",
    "pct_upperclassmen", "pct_in_state", "pct_previous_school")
]
rownames(big_ten_roster_profiles) <- NULL

usethis::use_data(big_ten_roster_profiles, overwrite = TRUE)
