#' @title ncaa_fb_game_info
#' @description Obtains football game team box scores from the NCAA API.
#' @param game_id the game_id of a given NCAA FB game from the NCAA API
#' @return a data frame with NCAA FB game team stats
#' @export
#' @examples \donttest{
#'   ncaa_fb_team_stats(5931773)
#' }
ncaa_fb_team_stats <- function(game_id) {
  base_url <- "https://data.ncaa.com/casablanca/game/"

  full_url <- paste(base_url, game_id, "teamStats.json", sep="/")

  # Check for internet
  #check_internet()

  # Create the GET request and set response as res
  res <- httr::GET(full_url)

  # Check the result
  #check_status(res)

  ts.json <- jsonlite::fromJSON(full_url, flatten = TRUE)

  ts.df <- as.data.frame(ts.json$teams)
  #Store stats df to get stats for categories without a breakdown
  stats.df <- ts.df %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$stats)
  #get stats for categories with a breakdown
  breakdown.df <- stats.df %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$breakdown, names_repair = "unique")

  stats.df <- stats.df %>%
    dplyr::select(teamId, stat, data) %>%
    dplyr::rename("team_id" = .data$teamId, "value" = .data$data)
  breakdown.df <- breakdown.df %>%
    dplyr::mutate(stat = paste(.data$stat...2, .data$stat...4, sep = "_")) %>%
    dplyr::select(teamId, stat, data...5) %>%
    dplyr::rename("team_id" = .data$teamId, "value" = .data$data...5)

  #Merge top level stats and stat breakdowns
  all.stats <- rbind(stats.df, breakdown.df)

  #Cleanup data for potential double dash issue
  all.stats$value <- gsub('--', '-', all.stats$value)

  #Widen the data
  stats.wider <- all.stats %>%
    tidyr::pivot_wider(names_from = .data$stat, values_from = .data$value) %>%
    tidyr::separate('Fumbles: Number-Lost', c("Fumbles", "FumblesLost"), "-") %>%
    tidyr::separate("Penalties: Number-Yards", c("Penalties", "PenaltyYards"), "-") %>%
    tidyr::separate("Punting: Number-Yards", c("Punts", "PuntingYards"), "-") %>%
    tidyr::separate("Punt Returns: Number-Yards", c("PuntReturns", "PuntReturnYards"), "-") %>%
    tidyr::separate("Kickoff Returns: Number-Yards", c("KickReturns", "KickReturnYards"), "-") %>%
    tidyr::separate("Interception Returns: Number-Yards", c("Interceptions", "InterceptionYards"), "-") %>%
    tidyr::separate("Third-Down Conversions", c("ThirdDownConversions", "ThirdDownAttempts"), "-") %>%
    tidyr::separate("Fourth-Down Conversions", c("FourthDownConversions", "FourthDownAttempts"), "-") %>%
    dplyr::rename("FirstDowns" = .data$`1st Downs`,
           "FirstDownsRushing" = .data$`1st Downs_Rushing`,
           "FirstDownsPassing" = .data$`1st Downs_Passing`,
           "FirstDownsPenalty" = .data$`1st Downs_Penalty`) %>%
    janitor::clean_names()

  meta.data.df <- as.data.frame(ts.json$meta$teams) %>%
    dplyr::select(id, homeTeam, shortname)
  team.stats.final <- merge(stats.wider, meta.data.df, by.x = "team_id", by.y = "id")

  return(stats.wider)
}
