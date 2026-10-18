# bigtenperf: Big Ten Football Performance Tools

This project is an R package prototype for importing and preparing authorized
PFF college football performance data for Big Ten analysis. Raw data are not
included. Keep PFF credentials and restricted source files outside version
control.

## Installation

```r
# install.packages("devtools")
devtools::install_github("JaxHill21/MSDS-457-Final-Project-Package")
```

## Functions

`get_pff_season()` reads the provided cached PFF player-game or team-game grade
table and filters it to requested season(s). It keeps the teams that were Big
Ten members for the selected season: Oregon, UCLA, USC, and Washington enter the
sample in 2024. It adds a `revenue_sharing_era` label, treating 2025 as the
first football season in which participating Division I schools could provide
direct institutional benefits under the House settlement. The NCAA records the
benefits-pool rule as adopted June 6, 2025, effective July 1, 2025
([NCAA Division I Manual](https://web3.ncaa.org/lsdbi/reports/getReport/90008)).

`clean_pff_offense()` filters player-grade data to offensive rows, retains the
source measures, and adds common `offense_grade`, `offense_level`, and
`offense_snaps` fields. It also accepts the team-game grade extract, where a
player snap count is not available.

The supplied extracts are in the `football_recruiting_efficiency` download.
Example:

```r
pff_players <- get_pff_season(
  season = 2024,
  level = "player",
  data_dir = "/path/to/football_recruiting_efficiency/data/raw/pff"
)
offense_players <- clean_pff_offense(pff_players, min_snaps = 1)
```

Use `level = "team"` to read team-game grades. By default, rows without a
Big Ten `school_id` are excluded; set `include_opponents = TRUE` to retain
opponents in the source file. The supplied 2026 season is in progress and is
not directly comparable to completed seasons without accounting for its
partial schedule.

## Dataset

`big_ten_roster_profiles` summarizes the football rosters posted on each Big Ten
school's athletics site, one row per school per season for 2014-2026 (231 rows).
It covers roster size, average height and weight, class-year makeup, in-state
share and the share of players listing a previous school. It contains
school-level summaries only, with no individual player data. See
`?big_ten_roster_profiles` for definitions and caveats, and
`data-raw/big_ten_roster_profiles.R` for how it was built.

```r
str(big_ten_roster_profiles)
```

## Sample data

The package ships two small synthetic CSVs in `inst/extdata` that mimic the
layout of the PFF extracts. They are made-up values used only for the examples
and tests:

```r
library(bigtenperf)
sample_dir <- system.file("extdata", package = "bigtenperf")
players <- get_pff_season(2023:2025, level = "player", data_dir = sample_dir)
clean_pff_offense(players, min_snaps = 10)
```

## Development

Documentation is generated with roxygen2 and the package is checked with
devtools:

```r
devtools::document()
devtools::test()
devtools::check()
```
