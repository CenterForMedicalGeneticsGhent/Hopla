# Haplotype plots

#' Build chromosome haplotype profiles.
#' @return A named list of Plotly htmlwidgets.
get_haplo_profiles <- function(){
  get_breaks <- function(f, pos){
    changes <- cumsum(rle(f)$lengths)
    colors <- letter_colors[rle(f)$values]
    breakpoints <- sapply(changes, function(x) pos[x] + (pos[x+1] - pos[x]) / 2)
    breakpoints <- breakpoints[-length(breakpoints)]
    return(list(breakpoints = breakpoints, colors = colors))
  }

  filter_region <- function(frame, chr, whole_chromosome = F){
    if (length(args$regions)){
      for (region in args$regions){
        r_split <- strsplit(region, ':')[[1]]
        if (chr == r_split[1]){
          if (whole_chromosome) return(frame)
          s <- as.numeric(strsplit(r_split[2],'-')[[1]][1])
          s <- s - args$regions_flanking_size
          e <- as.numeric(strsplit(r_split[2],'-')[[1]][2])
          e <- e + args$regions_flanking_size
          return(frame[frame$x >= s & frame$x <= e,])
        }
      }
    }
    return(frame[-(1:nrow(frame)),])
  }

  add_marker_and_trace <- function(fig, y, f = 'f1', mar = 'y-down-open', symbol_offset = .3){
    for (i in 1:(length(breaks[[s]][[f]])-1)){
      if (i != 1){
        fig <- add_markers(fig, x = breaks[[s]][[f]][i], y = rep(y + symbol_offset, 2),
                           name = NULL, hoverinfo = "none",
                           marker = list(symbol = mar, color = colors[length(letters) + 1],
                                         size = args$dot_factor * 8),
                           type='scatter', mode='marker', inherit = F)
      }
      fig <- add_trace(fig, x = c(breaks[[s]][[f]][i], breaks[[s]][[f]][i+1]), y = rep(y, 2),
                       name = NULL, hoverinfo = "none",
                       line = list(color = breaks[[s]][[paste0(f, 'cols')]][i], width = args$dot_factor * 2),
                       type='scatter', mode='lines', inherit = F)
    }
    return(fig)
  }

  chr_lengths <- sapply(chrs, function(x) max(vcfs_filtered2[[1]]$POS[vcfs_filtered2[[1]]$CHROM == x]))

  haplo_profiles <- list()
  for (c in chrs){
    haplo_frames <- list()
    annot_list <- list()
    breaks <- list()
    for (s in args$samples_no_u){
      x <- map_list[[c]]$pos
      flow_strands <- split_strands(parsed_flow[[c]][,which(args$samples_no_u == s)])
      geno_strands <- split_strands(parsed_geno[[c]][,which(args$samples_no_u == s)])
      f1 <- flow_strands[[1]]
      f2 <- flow_strands[[2]]
      g1 <- geno_strands[[1]]
      g2 <- geno_strands[[2]]
      c1 <- is_corrected[[c]][,which(args$samples_no_u == s) * 2 - 1]
      c2 <- is_corrected[[c]][,which(args$samples_no_u == s) * 2]
      breaks[[s]]$f1 <- c(x[1], get_breaks(f1, x)$breakpoints, x[length(x)])
      breaks[[s]]$f1cols <- get_breaks(f1, x)$colors
      breaks[[s]]$f2 <- c(x[1], get_breaks(f2, x)$breakpoints, x[length(x)])
      breaks[[s]]$f2cols <- get_breaks(f2, x)$colors
      symbol <- rep(1, length(c1) * 2)
      symbol[c(c1,c2)] <- 0
      symbol[c(g1,g2) == 'NA'] <- 101 ## will show nothing
      id1 <- paste0(c, ':', map_list[[c]]$pos_out, ' (', g1, ')')
      id2 <- paste0(c, ':', map_list[[c]]$pos_out, ' (', g2, ')')
      y1 <- length(args$samples_no_u) * 3 - which(args$samples_no_u == s) * 3 + 1
      y2 <- length(args$samples_no_u) * 3 - which(args$samples_no_u == s) * 3
      haplo_frame_sub <- data.frame(c(x, x), c(rep(y1, length(x)), rep(y2, length(x))),
                                    c(id1, id2), c(letter_colors[f1],  letter_colors[f2]), symbol,
                                    stringsAsFactors = F, c(rep(which(args$samples_no_u == s) * 2 - 1, length(x)),
                                                            rep(which(args$samples_no_u == s) * 2, length(x))))
      annot_list[[which(args$samples_no_u == s)]] <- list(x = 1, y = y1 + 1,
                                                          text = args$samples_out[args$sample_ids == s], showarrow = F)
      if (all(c(g1, g2) == 'NA')) next
      haplo_frames[[length(haplo_frames) + 1L]] <- haplo_frame_sub
    }
    haplo_frame <- data.table::rbindlist(haplo_frames)

    ## raw data points

    colnames(haplo_frame) <- c('x', 'y', 'id', 'col', 'symbol', 'name')
    haplo_frame_for_plotly <- haplo_frame
    if (args$keep_chromosomes_only) haplo_frame_for_plotly <- filter_region(haplo_frame, c, whole_chromosome = T)
    if (args$keep_regions_only) haplo_frame_for_plotly <- filter_region(haplo_frame, c)
    p <- plot_ly(haplo_frame_for_plotly, x =~x, y =~y, text =~id, name=~name, marker = list(color=~col,
                                                                                            symbol=~symbol,
                                                                                            size = args$dot_factor * 4,
                                                                                            line=list(color=~col)),
                 type = 'scattergl', mode = 'markers', hoverinfo = 'text', height = 900 * length(args$samples_no_u),
                 hoverlabel=list(bgcolor=~col))

    ## layout

    p <- p %>% layout(xaxis = list(title = c, showticklabels = F,
                                   zeroline = F, showgrid = F), showlegend = F,
                      yaxis = list(title = '',showticklabels = F, zeroline = F, showgrid = F,
                                   fixedrange = T, range = c(-1, length(args$samples_no_u) * 3 + 1)),
                      annotations = annot_list)

    ## add traces and recombination points

    for (s in args$samples_no_u){
      y2 <- length(args$samples_no_u) * 3 - which(args$samples_no_u == s) * 3
      p <- add_marker_and_trace(p, length(args$samples_no_u) * 3 - which(args$samples_no_u == s) * 3 + 1)
      p <- add_marker_and_trace(p, length(args$samples_no_u) * 3 - which(args$samples_no_u == s) * 3, 'f2', 'y-up-open', symbol_offset = -.3)
    }

    ## add regions

    if (length(args$regions)){
      for (region in args$regions){
        if (c == strsplit(region, ':')[[1]][1]){
          tmp <- 1 ; names(tmp) <- c
          p <- mark_region(p, tmp, c(-.5, length(args$samples_no_u) * 3 + 1), region, chr_lengths)
        }
      }
    }

    ## add cytobands

    if (length(args$cytoband_file)){
      p <- add_cytoband(p, c, max(haplo_frame$y) + 2)
    } else {
      p <- add_locus_bar(p, c, chr_lengths[[c]], max(haplo_frame$y) + 2)
    }

    haplo_profiles[[c]] <- p
  }
  return(haplo_profiles)
}

#' Build the pairwise haplotype concordance table.
#' @return A Plotly table htmlwidget.
get_haplo_tables <- function(){
  flow_strands <- lapply(chrs, function(chr){
    per_sample <- lapply(seq_along(args$samples_no_u), function(i){
      split_strands(parsed_flow[[chr]][,i])
    })
    names(per_sample) <- args$samples_no_u
    per_sample
  })
  names(flow_strands) <- chrs

  rows <- list()
  for (s1 in args$samples_no_u){
    for (i1 in c(1,2)){
      row <- c()
      for (s2 in args$samples_no_u){
        for (i2 in c(1,2)){
          if ((which(args$samples_no_u == s2) > which(args$samples_no_u == s1)) |
              (s1 == s2 & i1 != i2)){
            row <- c(row, '')
          } else {
            obs <- c()
            exp <- c()
            for (chr in chrs){
              strand1 <- flow_strands[[chr]][[s1]][[i1]]
              strand2 <- flow_strands[[chr]][[s2]][[i2]]
              if (all(strand1 == 'X') | all(strand2 == 'X')) next
              obs <- c(obs, length(which(strand1 == strand2)))
              exp <- c(exp, length(strand1))
            }
            row <- c(row, paste0(round(sum(obs) / sum(exp) * 100, 2), '%'))
          }
        }
      }
      rows[[length(rows) + 1]] <- row
    }
  }

  table <- rbind(rep(c('1', '2'), length(args$samples_no_u)), sapply(rows, cbind))
  table <- cbind(c('', rep(c('1', '2'), length(args$samples_no_u))), table)
  table <- cbind(c('', unlist(lapply(args$samples_no_u, function(x) c(paste0('(', which(args$samples_no_u == x), ') ',
                                                                             trim_whitespace(gsub(x, '', args$samples_out[args$sample_ids == x]))),
                                                                      args$samples_no_u[args$samples_no_u == x])))), table)
  table <- rbind(c('', '', unlist(lapply(args$samples_no_u, function(x) rep(paste0('(', which(args$samples_no_u == x), ')'),2)))), table)
  table <- cbind(table, rep('', nrow(table)))

  cols_fill <- fill_matrix(table, 'white')
  cols_fill[1:2,] <- colors[1] ; cols_fill[,1:2] <- colors[1]
  cols_fill[1:2,1:2] <- 'white'
  for (i in seq(1, length(args$samples_no_u)*2, 4)){
    cols_fill[1:2, (i+2):(i+3)] <- colors[2]
    cols_fill[(i+2):(i+3), 1:2] <- colors[2]
  }
  cols_fill[,ncol(cols_fill)] <- 'white'
  cols_line <- fill_matrix(table, 'grey')
  cols_line[2,] <- 'white' ; cols_line[,2] <- 'white'
  for (i in seq(1, length(args$samples_no_u)*2, 4)){
    cols_line[1, (i+2):(i+3)] <- colors[2]
    cols_line[(i+2):(i+3), 1] <- colors[2]
  }
  for (i in seq(3, length(args$samples_no_u)*2, 4)){
    cols_line[1, (i+2):(i+3)] <- colors[1]
    cols_line[(i+2):(i+3), 1] <- colors[1]
  }
  cols_line[1:2,1:2] <- 'white'
  cols_line[,ncol(cols_line)] <- 'white'

  fig <- plot_ly(
    type = 'table',
    header = list(
      line = list(color = 'white'),
      fill = list(color = 'white'),
      font = list(color = 'white', size = 1)),
    cells = list(values = t(table),
                 line = list(color = t(cols_line), width = t(fill_matrix(table, 1))), fill = list(color = t(cols_fill)),
                 font = list(color = rgb(.2,.2,.2), size = 9)), hoverinfo = 'none')
  fig <- fig %>% layout(autosize = T, font = list(family = report_font))
  return(fig)
}
