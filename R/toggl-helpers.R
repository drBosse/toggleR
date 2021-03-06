#' Fetch a list from toggl using the v8 api.
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param what What to fetch
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return The list (JSON) of clients accessable using \code{toggl_token} from the toggl workspace with id: \code{workspace_id}.
#' @family get.toggl
#' @examples
#' get.toggl.v8(Sys.getenv("TOGGL_TOKEN"), Sys.getenv("TOGGL_WORKSPACE"), "clients")
#' @export
get.toggl.v8 <- function(toggl_token, workspace_id, what, verbose = FALSE) {
  username <- toggl_token
  password <- "api_token"

  base <- "https://api.track.toggl.com/api"
  endpoint <- "v8/workspaces"

  call <- paste(base, endpoint, workspace_id, what, sep = "/")

  if (verbose) {
    result <- GET(call, authenticate(username, password), verbose())
  } else {
    result <- GET(call, authenticate(username, password))
  }
  return(result)
}
#' Fetch a list from toggl using the v8 api.
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param what What to fetch
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return A data frame with the wanted data, accessable using \code{toggl_token} from the toggl workspace with id: \code{workspace_id}.
#' @family get.toggl
#' @examples
#' get.toggl.v8(Sys.getenv("TOGGL_TOKEN"), Sys.getenv("TOGGL_WORKSPACE"), "clients")
#' @export
get.toggl.v8.data <- function(toggl_token, workspace_id, what, verbose = FALSE) {
  json.response <- get.toggl.v8(toggl_token, workspace_id, what, verbose)

  if (json.response$status_code == 200) {
    return(fromJSON(content(json.response, "text")))
  }

  print(json.response)
  return("ERROR")
}
#' Fetch a list of clients from toggl.
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return A data frame of the clients accessable using \code{toggl_token} from the toggl workspace with id: \code{workspace_id}.
#' @family get.toggl
#' @examples
#' get.toggl.clients(Sys.getenv("TOGGL_TOKEN"), Sys.getenv("TOGGL_WORKSPACE"))
#' @export
get.toggl.clients <- function(toggl_token, workspace_id, verbose = FALSE) {
  return(get.toggl.v8.data(toggl_token, workspace_id, "clients"))
}

#' Fetch a list of groups from toggl.
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return A data frame of the groups accessable using \code{toggl_token} from the toggl workspace with id: \code{workspace_id}.
#' @family get.toggl
#' @examples
#' get.toggl.groups(Sys.getenv("TOGGL_TOKEN"), Sys.getenv("TOGGL_WORKSPACE"))
#' @export
get.toggl.groups <- function(toggl_token, workspace_id, verbose = FALSE) {
  return(get.toggl.v8.data(toggl_token, workspace_id, "groups"))
}

#' Fetch a page of entries for a group using the V2 API
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param group The group Id for the wanted group
#' @param since The start date of the wanted time interval, Default value: \code{Sys.Date() -7}
#' @param until The end date of the wanted interval, Default value: \code{Sys.Date()}
#' @param page Which page of the data to fetch, Default value: 1
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return A httr response object with the paged data for the wanted \code{group}.
#' @family get.toggl
#' @export
get.toggl.v2.group.details <- function(toggl_token, workspace_id, group, since = Sys.Date() - 7, until = Sys.Date(), page = 1, verbose = FALSE) {
  username <- toggl_token
  password <- "api_token"

  base <- "https://toggl.com/reports/api"
  endpoint <- "v2/details?"

  what <- paste("workspace_id=", workspace_id, sep = "")
  what <- paste(what, "&since=", since, "&until=", until, sep = "")
  what <- paste(what, "&user_agent=api_test", sep = "")
  what <- paste(what, "&members_of_group_ids=", group, sep = "")
  what <- paste(what, "&billable=both", sep = "")
  what <- paste(what, "&page=", page, sep = "")

  call <- paste(base, endpoint, sep = "/")
  call <- paste(call, what, sep = "")

  if (verbose) {
    print(call)
  }

  if (verbose) {
    result <- GET(call, authenticate(username, password), verbose())
  } else {
    result <- GET(call, authenticate(username, password))
  }
  return(result)
}

#' Fetch the detailed entries for a group during a specified time interval
#'
#' @param toggl_token A toggl API token to access https://toggl.com.
#' @param workspace_id The workspace id for the wanted workspace.
#' @param group The group Id for the wanted group
#' @param since The start date of the wanted time interval, Default value: \code{Sys.Date() -7}
#' @param until The end date of the wanted interval, Default value: \code{Sys.Date()}
#' @param verbose A flag to enable more verbose output, Default value: FALSE
#' @return A data frame with the collected entries for the wanted \code{group}.
#' @family get.toggl
#' @export
get.toggl.group.data <- function(toggl_token, workspace_id, group, since = Sys.Date() - 7, until = Sys.Date(),  verbose = FALSE) {
  data.response <- data.frame()
  start.date <- since
  batch.size <- 100
  batch <- 1

  if (verbose) {
    print(paste("Token:", toggl_token))
    print(paste("W Id:", workspace_id))
    print(paste("Group:", group))
    print(paste("Since:", since))
    print(paste("Until:", until))
  }
  while (start.date < until) {

    end.date <- start.date + (batch.size - 1)
    if (end.date > until) {
      end.date <- until
    }

    print(paste("Fetching batch number: ", batch))
    print(paste("Range: ", start.date, " - ", end.date))

    not.done <- TRUE
    page <- 1

    while (not.done) {     # collect all pages
      not.OK   <- TRUE
      while(not.OK) {      # collect one page
        json.response <- get.toggl.v2.group.details(toggl_token, workspace_id, group, since = start.date, until = end.date, page = page)
        if (json.response$status_code == 200) {
          not.OK <- FALSE
          response <- fromJSON(content(json.response, "text", encoding = 'UTF-8'))

          if (length(response$data) > 0) {
            data.response <- rbind(data.response, response$data)
            if (page == 1) {
              print(paste('Fetching', response$total_count, 'entries in', 1 + (response$total_count %/% response$per_page), 'pages from toggl'))
              cat(page)
            } else {
              cat(paste('.', page, sep = ''))
            }
          } else {
            print(" OK")
            not.done <- FALSE
          }

        } else {
          print(" ERROR")
          print(json.response)
          Sys.sleep(2)
        }
      }
      page <- page + 1
    }
    start.date <- start.date + batch.size
    batch <- batch + 1
    Sys.sleep(1)
  }
  return(data.response)
}
