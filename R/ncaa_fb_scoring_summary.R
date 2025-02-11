#' @title ncaa_fb_scoring_summary
#'
#' @description Obtains football game scoring summary.
#'
#' @param game_id the game_id of a given NCAA FB game from the NCAA API
#'
#' @return A data frame of all scoring plays for the given game
#' @import rvest
#' @importFrom dplyr row_number arrange mutate select as_tibble
#' @importFrom jsonlite fromJSON
#' @importFrom janitor clean_names
#' @importFrom purrr map_if
#' @importFrom tidyr unnest
#' @export
#' @examples \donttest{
#'   ncaa_fb_scoring_summary(5931773)
#' }
ncaa_fb_scoring_summary <- function(game_id) {
  base_url <- "https://data.ncaa.com/casablanca/game/"

  full_url <- paste(base_url, game_id, "scoringSummary.json", sep="/")

  # Check for internet
  #check_internet()

  # Create the GET request and set response as res
  res <- httr::GET(full_url)

  # Check the result
  #check_status(res)

  scoring.json <- jsonlite::fromJSON(full_url, flatten = TRUE)

  scores <- as.data.frame(scoring.json$periods)
  summary.df <- scores %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$summary) %>%
    dplyr::mutate(series_order = dplyr::row_number()) %>%
    janitor::clean_names()

  meta.data.df <- as.data.frame(scoring.json$meta$teams) %>%
    dplyr::select(id, homeTeam, shortname)
  scoring.summary.final <- merge(summary.df, meta.data.df, by.x = "team_id", by.y = "id")
  scoring.summary.final <- scoring.summary.final %>%
    dplyr::arrange(series_order) %>%
    janitor::clean_names()

  return(scoring.summary.final)
}
