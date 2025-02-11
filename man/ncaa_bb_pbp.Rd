% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncaa_bb.R
\name{ncaa_bb_pbp}
\alias{ncaa_bb_pbp}
\title{ncaa_bb_pbp}
\usage{
ncaa_bb_pbp(game_id, dirty_data_behavior = "warn")
}
\arguments{
\item{game_id}{the game_id for the specified game from stats.ncaa.com}

\item{dirty_data_behavior}{specifies the behavior for the function if
inconsistencies are detected between the box score and the pbp.
\itemize{
\item If "error", then when an inconsistency is detected, the function will throw
an error and not return anything.
\item If "warn", then a warning will display but the function will still return
pbp data.
\item If "silent", the function will still check that the data is clean, but
will not display any warning or error message.
This param defaults to "warn".
}}
}
\value{
a dataframe of cleaned, parsed play-by-play data for the specified
\code{game_id}
}
\description{
Scrapes and parses pbp data for ncaa basketball games
}
