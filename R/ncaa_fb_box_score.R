#' @title ncaa_fb_box_score
#' @description Obtains football game team box scores from the NCAA API.
#' @param game_id the game_id of a given NCAA FB game from the NCAA API
#' @return a data frame with NCAA FB player box score data for the given game
#' @import rvest
#' @importFrom jsonlite fromJSON
#' @importFrom janitor clean_names
#' @importFrom dplyr as_tibble select case_when filter everything across first mutate group_by ungroup summarise
#' @importFrom purrr map_if
#' @importFrom tidyr pivot_wider unnest separate
#' @export
#' @examples \donttest{
#'   ncaa_fb_box_score(game_id = 5931773)
#' }
ncaa_fb_box_score <- function(game_id) {
  base_url <- "https://data.ncaa.com/casablanca/game/"

  full_url <- paste(base_url, game_id, "boxscore.json", sep="/")

  # Check for internet
  #check_internet()

  # Create the GET request and set response as res
  res <- httr::GET(full_url)

  # Check the result
  check_status(res)

  bs.json <- jsonlite::fromJSON(full_url, flatten = TRUE)

  bs.df <- as.data.frame(bs.json$tables)

  bs.df2 <- bs.df %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$data, names_repair = "unique")

  data <- bs.df2 %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$row, names_sep = "_")

  headers <- bs.df2 %>%
    purrr::map_if(is.data.frame, list) %>%
    dplyr::as_tibble() %>%
    tidyr::unnest(.data$header, names_sep = "_")

  #Rename data
  combined <- cbind(data, headers)
  colnames(combined) <- c("id", "headerColor", "headerClass", "header", "playerCategory", "display", "total",
                          "id2", "headerColor2", "headerClass2", "statCategory", "headerdisplay", "row", "total2")

  #Assign player name to each row
  formatted <- combined %>%
    dplyr::select(id, headerColor, headerClass, playerCategory, display, total, headerdisplay) %>%
    dplyr::mutate(
      playerid = cumsum(dplyr::case_when(playerCategory == "playerName" ~ 1,
                                       TRUE ~ 0))) %>%
    dplyr::group_by(playerid) %>%
    dplyr::mutate(playerName = trimws(dplyr::first(display))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-playerid) %>%
    dplyr::filter(is.na(playerCategory))

  #Clarify duplicate column names
  formatted$headerdisplay <- apply(formatted, 1, function(x) {
    id <- as.character(x["id"])
    stat.name <- as.character(x["headerdisplay"])

    if (id == "rushing_visiting" | id == "rushing_home") {
      return(paste0("Rushing.", stat.name))
    } else if (id == "receiving_visiting" | id == "receiving_home") {
      return(paste0("Receiving.", stat.name))
    } else if (id == "passing_visiting" | id == "passing_home") {
      return(paste0("Passing.", stat.name))
    } else if (id == "punt_returns_visiting" | id == "punt_returns_home") {
      return(paste0("Punt.Return.", stat.name))
    } else if (id == "kick_returns_visiting" | id == "kick_returns_home") {
      return(paste0("Kick.Return.", stat.name))
    }

    return(stat.name)
  })

  #Remove total fields, only focus on players
  no.total <- formatted %>%
    tidyr::pivot_wider(names_from = .data$headerdisplay, values_from = .data$display) %>%
    tidyr::separate(.data$`Passing.CP-ATT-INT`, c("PassingComp", "PassingAtt", "PassingInt"), "-") %>%
    #tidyr::separate(.data$`FG-FGA`, c("FG", "FGA"), "/") %>%
    dplyr::filter(is.na(total)) %>%
    dplyr::select(-c("headerClass", "playerCategory", "total", "id", "headerColor"))

  no.total[,2:34] <- sapply(no.total[,2:34],as.numeric)
  no.total[is.na(no.total)] <- 0

  final <- no.total %>%
    dplyr::group_by(playerName) %>%
    dplyr::summarise(dplyr::across(dplyr::everything(), sum)) %>%
    dplyr::ungroup() %>%
    janitor::clean_names()

  return(final)
}
