#' Big Ten football roster profiles by school and season
#'
#' A school-season summary of the football rosters published on the athletics
#' websites of the 18 schools in the 2024 Big Ten Conference, covering the 2014
#' through 2026 seasons. Each row describes one team's roster: its size, the
#' players' average height and weight, its class-year makeup, how many players
#' come from the school's home state, and how many list a previous college.
#' Oregon, UCLA, USC and Washington are included for seasons before they
#' joined the conference so their rosters can be compared before and after the
#' move.
#'
#' @format A data frame with 231 rows and 11 variables:
#' \describe{
#'   \item{school_id}{Short school identifier, such as `"ohio_state"`.}
#'   \item{school_name}{School name, such as `"Ohio State"`.}
#'   \item{season}{Football season (integer, 2014--2026).}
#'   \item{big_ten_member}{`TRUE` if the school was a Big Ten member that
#'     season. `FALSE` for Oregon, UCLA, USC and Washington before 2024.}
#'   \item{revenue_sharing_era}{`"direct_sharing"` for 2025 and later, when
#'     schools could pay athletes directly under the House settlement;
#'     otherwise `"pre_direct_sharing"`. Matches the label added by
#'     [get_pff_season()].}
#'   \item{roster_size}{Number of players listed on the roster.}
#'   \item{avg_height_in}{Average player height, in inches.}
#'   \item{avg_weight_lbs}{Average listed player weight, in pounds.}
#'   \item{pct_upperclassmen}{Share of players (0--1) whose class year is
#'     junior or later, including graduate and fifth-year players.}
#'   \item{pct_in_state}{Share of players (0--1) whose hometown is in the
#'     same state as the school.}
#'   \item{pct_previous_school}{Share of players (0--1) listing a previous
#'     school (a four-year transfer, junior college or prep school). `NA`
#'     where the school did not fill in this field (see Details).}
#' }
#'
#' @details
#' Rosters were scraped from each school's official athletics site, then
#' summarized so that no individual player information is included. All
#' values are as the schools report them:
#'
#' * Ohio State's archived rosters begin in 2017, so Ohio State has no rows
#'   for 2014--2016.
#' * Roster size depends on whether a school lists walk-ons, so it is not a
#'   count of scholarship players.
#' * Class labels vary by school (`"R-Jr."`, `"Redshirt Junior"`, `"3rd"`,
#'   and so on) and were mapped to academic class before computing
#'   `pct_upperclassmen`. Some schools label by eligibility instead.
#'   Ohio State's 2017--2021 rosters, for example, list very few freshmen.
#' * Hometown states written in AP style, as postal codes or in full were
#'   all matched. Hometowns without a state were left out of
#'   `pct_in_state`.
#' * Heights outside 60--84 inches and weights outside 140--420 pounds were
#'   treated as data-entry errors and left out of the averages.
#' * `pct_previous_school` is `NA` when a school-season reports no previous
#'   schools at all (for example Nebraska 2014--2025), or when more than 90%
#'   of players have one, which happens when the field holds high schools
#'   (Ohio State).
#'
#' The script that builds the data is in `data-raw/big_ten_roster_profiles.R`
#' in the package's GitHub repository.
#'
#' @source Official football rosters on the athletics websites of the Big Ten
#'   member schools (for example <https://ohiostatebuckeyes.com>), scraped
#'   September 2026.
#'
#' @examples
#' str(big_ten_roster_profiles)
#'
#' # Average roster weight before and after the revenue-sharing era
#' aggregate(avg_weight_lbs ~ revenue_sharing_era,
#'           data = big_ten_roster_profiles, FUN = mean)
#'
#' # Washington's roster before and after joining the Big Ten
#' subset(big_ten_roster_profiles, school_id == "washington",
#'        select = c(season, big_ten_member, roster_size, pct_in_state))
"big_ten_roster_profiles"
