# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                           Functions: running specific analyses & creating visualizations
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Overall
# -----

#' Mark a genomic region on a Plotly figure.
#' @param fig A Plotly htmlwidget.
#' @param chr_cs,ylim,chr_lengths Numeric plotting coordinates.
#' @param region A `chr:start-end` string.
#' @param plot_flanks A logical indicating whether to draw flanks.
#' @return A Plotly htmlwidget.
mark_region <- function(fig, chr_cs, ylim, region, chr_lengths, plot_flanks = T){
  c <- strsplit(region, ':')[[1]][1]
  s <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][1]) ; s <- max(s, 1)
  flank_s <- s - args$regions_flanking_size ; flank_s <- max(flank_s, 1)
  e <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][2]) ; e <- min(e, chr_lengths[c])
  flank_e <- e + args$regions_flanking_size ; flank_e <- min(flank_e, chr_lengths[c])

  region_start <- paste0(c, ':', scales::comma(s, accuracy = 1))
  region_end <- paste0(c, ':', scales::comma(e, accuracy = 1))
  flank_start <- paste0(c, ':', scales::comma(flank_s, accuracy = 1))
  flank_end <- paste0(c, ':', scales::comma(flank_e, accuracy = 1))

  add_region_trace <- function(fig, xs, text, size = 1/2){
    fig <- fig %>% add_trace(x = xs, y = ylim, name = 'region',
                             hoverinfo = "text", line = list(color = colors[length(letters) + 1], width = args$dot_factor * size),
                             text = text, type='scatter', marker = list(color = colors[length(letters) + 1], size = .1),
                             mode='lines+markers', hoverlabel=list(bgcolor=colors[length(letters) + 1]), inherit = F)
    return(fig)
  }

  fig <- add_region_trace(fig, c(chr_cs[c] + s, chr_cs[c] + s), paste0(region_start, ' (region start)'))
  fig <- add_region_trace(fig, c(chr_cs[c] + e, chr_cs[c] + e), paste0(region_end, ' (region end)'))

  if (plot_flanks){
    fig <- add_region_trace(fig, rep(chr_cs[c] + flank_s, 2), paste0(flank_start, ' (flank start)'), 1/4)
    fig <- add_region_trace(fig, rep(chr_cs[c] + flank_e, 2), paste0(flank_end, ' (flank end)'), 1/4)
  }
  return(fig)
}

#' Add cytobands to a Plotly figure.
#' @param fig A Plotly htmlwidget.
#' @param chr A chromosome name.
#' @param y,line_width Numeric plot coordinates.
#' @return A Plotly htmlwidget.
add_cytoband <- function(fig, chr, y, line_width = 4){
  s <- c()
  names <- c()
  cols <- c()
  for (i in 1:length(cytobands[[chr]])){
    xs <- c(cytobands[[chr]][[i]]$start, cytobands[[chr]][[i]]$end)
    col <- c('lightgrey', 'darkgrey')[[i %% 2 + 1]]
    if (any(sapply(c('acen', 'gvar', 'stalk'), function(x) grepl(x, cytobands[[chr]][[i]]$name)))) col <- 'black'
    fig <- add_trace(fig, x = xs, y = rep(y, 2),
                     name = NULL, hoverinfo = "none",
                     line = list(color = col, width = args$dot_factor * line_width),
                     type='scatter', mode='lines', inherit = F)
    seq <- seq(xs[1], xs[2], 10000000)
    s <- c(s, seq)
    names <- c(names, paste0(cytobands[[chr]][[i]]$name, ' (',
                             scales::comma(seq, accuracy = 1), ')'))
    cols <- c(cols, rep(col, length(seq)))
  }

  fig <- add_markers(fig, x = s, y = rep(y, length(s)), text=names, name = NULL,
                     hoverinfo='text', marker = list(color = cols, size = args$dot_factor * .1),
                     type='scatter', mode='marker', inherit = F)
  return(fig)
}

#' Add a chromosome locus bar to a Plotly figure.
#' @param fig A Plotly htmlwidget.
#' @param chr A chromosome name.
#' @param end,y,line_width Numeric plot coordinates.
#' @return A Plotly htmlwidget.
add_locus_bar <- function(fig, chr, end, y, line_width = 4){
  s <- c(seq(1, end, 10000000), end)
  names <- c(scales::comma(s, accuracy = 1))
  cols <- c()
  for (i in 1:c(length(s)-1)){
    col <- c('lightgrey', 'darkgrey')[[i %% 2 + 1]]
    fig <- add_trace(fig, x = c(s[i], s[i+1]), y = rep(y, 2),
                     name = NULL, hoverinfo = "none",
                     line = list(color = col, width = args$dot_factor * line_width),
                     type='scatter', mode='lines', inherit = F)
    cols <- c(cols, col)
  }
  cols <- c(cols, c('lightgrey', 'darkgrey')[c('lightgrey', 'darkgrey') != col])
  fig <- add_markers(fig, x = s, y = rep(y, length(s)), text=names, name = NULL,
                     hoverinfo='text', marker = list(color = cols, size = args$dot_factor * .1),
                     type='scatter', mode='marker', inherit = F)
  return(fig)
}

#' Add chromosome boundary lines to a Plotly figure.
#' @param fig A Plotly htmlwidget.
#' @param chr_cs,ylim Numeric plotting coordinates.
#' @return A Plotly htmlwidget.
add_chr_lines <- function(fig, chr_cs, ylim){
  for (c in names(chr_cs)){
    fig <- fig %>%
      add_trace(x = c(chr_cs[c], chr_cs[c]), y = ylim,
                hoverinfo = "text",
                line = list(color = 'black', width = .5),
                text = c, type='scatter',
                marker = list(color = 'black', size = .1),
                mode='lines+markers', inherit = F)
  }
  return(fig)
}

#' Fill every cell of a matrix.
#' @param matrix A matrix.
#' @param fill A scalar fill value.
#' @return A matrix.
fill_matrix <- function(matrix, fill = 'white'){
  for (i in 1:ncol(matrix)){
    matrix[,i] <- rep(fill, nrow(matrix))
  }
  return(matrix)
}

#' Encode a local file as a data URI.
#' @param file Path to a local file.
#' @return A scalar character data URI.
file_data_uri <- function(file){
  mime <- switch(
    tolower(tools::file_ext(file)),
    css = 'text/css',
    js = 'application/javascript',
    png = 'image/png',
    jpg = 'image/jpeg',
    jpeg = 'image/jpeg',
    gif = 'image/gif',
    svg = 'image/svg+xml',
    woff = 'font/woff',
    woff2 = 'font/woff2',
    ttf = 'font/ttf',
    'application/octet-stream'
  )
  base64enc::dataURI(file = file, mime = mime)
}
