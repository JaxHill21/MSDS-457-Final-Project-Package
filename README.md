# MSDS-457-Final-Project-Package

# Big Ten Football Performance Tools

This project is an R package prototype for importing and preparing authorized
PFF college football performance data for Big Ten analysis. Raw data are not
included. Keep PFF credentials and restricted source files outside version
control.

## First functions

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
