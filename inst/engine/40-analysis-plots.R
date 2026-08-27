# Analysis plots

#' Build a genotype count table.
#' @param vcf_list A named list of sample data frames.
#' @return A Plotly table htmlwidget.
get_plotly_table <- function(vcf_list){
  states <- c('0/0', '0/1', '1/1')
  rows <- list()
  for (i in 1:length(args$samples_no_u)){
    for (k in 1:3){
      row <- c()
      for (j in 1:length(args$samples_no_u)){
        x <- vcf_list[[args$samples_no_u[i]]]
        x <- x[which(x$GT %in% states),]
        y <- vcf_list[[args$samples_no_u[j]]]
        y <- y[which(y$GT %in% states),]
        for (l in 1:3){
          if (j > i) { row <- c(row, '') ; next }
          if (k != l & j == i){ row <- c(row, '') ; next }
          row <- c(row, scales::comma(length(intersect(x$ID[which(x$GT == states[k])],
                                                       y$ID[which(y$GT == states[l])])), accuracy = 1))
        }
      }
      rows[[length(rows) + 1]] <- row
    }
  }

  table <- rbind(rep(c('0/0', '0/1', '1/1'), length(args$samples_no_u)), sapply(rows, cbind))
  table <- cbind(c('', rep(c('0/0', '0/1', '1/1'), length(args$samples_no_u))), table)
  table <- cbind(c('', unlist(lapply(args$samples_no_u, function(x) c(paste0('(', which(args$samples_no_u == x), ')'),
                                                                      x, trim_whitespace(gsub(x, '', args$samples_out[args$sample_ids == x])))))), table)
  table <- rbind(c('', '', unlist(lapply(args$samples_no_u, function(x) c('',paste0('(', which(args$samples_no_u == x), ')'),'')))), table)
  table <- cbind(table, rep('', nrow(table)))

  cols_fill <- fill_matrix(table, 'white')
  cols_fill[1:2,] <- colors[1] ; cols_fill[,1:2] <- colors[1]
  cols_fill[1:2,1:2] <- 'white'
  for (i in seq(1, length(args$samples_no_u)*3, 6)){
    cols_fill[1:2, (i+2):(i+4)] <- colors[2]
    cols_fill[(i+2):(i+4), 1:2] <- colors[2]
  }
  cols_fill[,ncol(cols_fill)] <- 'white'
  cols_line <- fill_matrix(table, 'grey')
  cols_line[2,] <- 'white' ; cols_line[,2] <- 'white'
  for (i in seq(1, length(args$samples_no_u)*3, 6)){
    cols_line[1, (i+2):(i+4)] <- colors[2]
    cols_line[(i+2):(i+4), 1] <- colors[2]
  }
  if (length(args$samples_no_u) > 1){
    for (i in seq(4, length(args$samples_no_u)*3, 6)){
      cols_line[1, (i+2):(i+4)] <- colors[1]
      cols_line[(i+2):(i+4), 1] <- colors[1]
    }
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
                 font = list(color = rgb(.2,.2,.2), size = 9), height = 30), hoverinfo = 'none')
  fig <- fig %>% layout(autosize = T, font = list(family = report_font))

  return(fig)
}

# -----
# Pedigree
# -----

#' Render the current pedigree to PNG.
#' @param file Output PNG path.
#' @return Invisible `NULL`.
write_pedigree <- function(file){
  status <- matrix(ncol = 2, nrow = length(args$sample_ids))
  if (length(args$nonaffected)) status[which(args$sample_ids %in% args$nonaffected),] <- 0
  if (length(args$carrier)){
    status[which(args$sample_ids %in% args$carrier),1] <- 0
    status[which(args$sample_ids %in% args$carrier),2] <- 1
  }
  if (length(args$affected)) status[which(args$sample_ids %in% args$affected),] <- 1

  pedi <- suppressWarnings(pedigree(args$samples_out,
                                    args$samples_out[match(args$father_ids, args$sample_ids)],
                                    args$samples_out[match(args$mother_ids, args$sample_ids)],
                                    args$genders, status))
  png(file, width=log(length(args$sample_ids)) * 4, height=5, units='in', res=512)
  suppressWarnings(plot(pedi, mar = c(4,4,4,4), density = c(-1, -1)))
  invisible(dev.off())
}

# -----
# Variant distribution
# -----

#' Build the genome-wide variant distribution figure.
#' @param vcf_list A named list of sample data frames.
#' @return A Plotly htmlwidget.
get_var_dis_fig <- function(vcf_list){
  chr_lengths <- sapply(chrs, function(x) max(vcf_list[[1]]$POS[vcf_list[[1]]$CHROM == x]))
  chr_cs <- c(1, cumsum(chr_lengths)) ; names(chr_cs) <- c(chrs, 'end')

  annot <- c()
  counts <- c()
  poss <- c()
  for (chr in chrs){
    breaks <- seq(1, chr_lengths[chr] + args$window_size, args$window_size)
    poss <- c(poss, breaks[-length(breaks)] + chr_cs[chr])
    h <- hist(vcf_list[[1]]$POS[vcf_list[[1]]$CHROM == chr], breaks, plot = F)
    counts <- c(counts, h$counts)
    annot <- c(annot, paste0(chr, ':', scales::comma(breaks[-length(breaks)], accuracy = 1), '-',
                             scales::comma(breaks[-length(breaks)] + args$window_size - 1,
                                           accuracy = 1)))
  }

  dat <- data.frame(annot, poss, counts)

  colnames(dat) <- c('range', 'index', 'count')
  var_dis <- plot_ly(dat, x =~index, y =~count, text=~range, height = 240,
                     marker = list(color = colors[1], alpha = .5, size = 2 * args$dot_factor,
                                   line = list(color = colors[1], alpha = .5)),
                     type = 'scatter', mode = 'markers', hoverinfo = 'y+text')

  var_dis <- var_dis %>% layout(xaxis = list(title = '', showticklabels = F,
                                             zeroline = F, showgrid = F),
                                showlegend = F, yaxis = list(title = 'variant count', zeroline = F),
                                hovermode = 'x unified')

  var_dis <- add_chr_lines(var_dis, chr_cs, c(-max(dat$count)*.1, max(dat$count)*1.1))

  if (length(args$regions)){
    for (region in args$regions){
      var_dis <- mark_region(var_dis, chr_cs, c(-max(dat$count)*.1, max(dat$count)*1.1), region, chr_lengths)
    }
  }
  return(var_dis)
}

# -----
# Variant depth
# -----

#' Build per-sample depth histograms.
#' @param vcf_list A named list of sample data frames.
#' @return A named list of Plotly htmlwidgets.
get_var_depth_hist <- function(vcf_list){
  sample_depths <- function(s){
    depths <- vcf_list[[s]]$DP
    depths[is.finite(depths) & depths != 0]
  }

  # One set of breaks and one pair of axis ranges, so the panels stay comparable.
  lowest <- Inf ; highest <- -Inf ; total <- 0
  for (s in args$samples_no_u){
    depths <- sample_depths(s)
    if (!length(depths)) next
    lowest <- min(lowest, depths) ; highest <- max(highest, depths)
    total <- total + length(depths)
  }

  varhists <- list()
  panel_height <- 200 * ceiling(length(args$samples_no_u) / 4)
  if (!is.finite(lowest)){
    for (s in args$samples_no_u){
      empty <- data.frame(depth = numeric(), count = integer())
      hist <- plot_ly(empty, x = ~depth, y = ~count, type = 'bar', hoverinfo = 'x+y',
                      marker = list(color = colors[1]), height = panel_height)
      varhists[[s]] <- hist %>% layout(xaxis = list(title = list(text = args$samples_out[args$sample_ids == s],
                                                                 standoff = 1),
                                                    zeroline = F, showgrid = F),
                                       yaxis = list(title = 'density', zeroline = F), showlegend = F)
    }
    return(varhists)
  }

  if (highest == lowest){ lowest <- lowest - .5 ; highest <- highest + .5 }
  number_of_bins <- min(100L, max(1L, ceiling(log2(total)) + 1L))
  breaks <- seq(lowest, highest, length.out = number_of_bins + 1L)
  mids <- breaks[-length(breaks)] + diff(breaks) / 2

  counts <- list()
  for (s in args$samples_no_u){
    depths <- sample_depths(s)
    counts[[s]] <- if (length(depths)){
      graphics::hist(depths, breaks = breaks, plot = F)$counts
    } else {
      rep(0L, number_of_bins)
    }
  }
  highest_count <- max(1, unlist(counts))

  for (s in args$samples_no_u){
    depth_counts <- data.frame(depth = mids, count = counts[[s]])
    hist <- plot_ly(depth_counts, x = ~depth, y = ~count, type = 'bar', hoverinfo = 'x+y',
                    marker = list(color = colors[1]), height = panel_height)
    hist <- hist %>% layout(xaxis = list(title = list(text = args$samples_out[args$sample_ids == s], standoff = 1),
                                         zeroline = F, showgrid = F, range = c(lowest, highest)),
                            yaxis = list(title = 'density', zeroline = F, range = c(0, highest_count)),
                            showlegend = F)
    varhists[[s]] <- hist
  }
  return(varhists)
}

#' Build copy-number segmentation figures.
#' @return A named list of Plotly htmlwidgets.
get_cn_fig <- function(){

  cluster_max_len_between_cpg = 200
  clusters <- vector('list', length(chrs))

  for (chr_i in seq_along(chrs)){
    chr <- chrs[chr_i]
    pos <- vcfs[[1]]$POS[vcfs[[1]]$CHROM == chr]

    starts <- c(pos[1], pos[which(pos[-1] - pos[-length(pos)] > cluster_max_len_between_cpg) + 1])
    ends <- c(pos[which(pos[-1] - pos[-length(pos)] > cluster_max_len_between_cpg)], pos[length(pos)])
    amount <- diff(c(0, which(pos[-1] - pos[-length(pos)] > cluster_max_len_between_cpg), length(pos)))

    chr_cluster <- matrix(nrow = length(ends), ncol = 4)
    chr_cluster[,1] <- rep(chr, length(starts))
    chr_cluster[,2] <- starts
    chr_cluster[,3] <- ends + 1
    chr_cluster[,4] <- amount

    clusters[[chr_i]] <- chr_cluster
  }

  clusters <- data.frame(do.call(rbind, clusters), stringsAsFactors = F)
  colnames(clusters) <- c('seqnames', 'start', 'end', 'amount')
  for (i in 2:4) clusters[,i] <- as.numeric(clusters[,i])
  clusters_gr <- GRanges(clusters)

  pos_gr <- GRanges(seqnames = vcfs[[1]]$CHROM, ranges = IRanges(start = vcfs[[1]]$POS, width = 1))

  chr_lengths <- sapply(chrs, function(x) max(vcfs[[1]]$POS[vcfs[[1]]$CHROM == x]))
  cn <- GRanges(seqnames = chrs, ranges = IRanges(start = 1, width = chr_lengths))
  cn <- as.data.frame(slidingWindows(cn, width = args$window_size, step = args$window_size))[,3:5]
  cn_gr <- GRanges(cn)

  hits <- findOverlaps(clusters_gr, pos_gr, select = 'all')
  hits <- split(hits@to, hits@from)

  hits2 <- findOverlaps(cn_gr, clusters_gr, select = 'all')
  hits2 <- split(hits2@to, hits2@from)

  copy_number_plots <- list()
  for (s in args$samples_no_u){
    vcf <- vcfs[[s]]
    var_mask <- vcf$GT != './.'

    dat_clusters <- clusters
    dat_clusters$mean_depth[as.numeric(names(hits))] <- sapply(hits, function(hit) mean(vcf$AD[hit][var_mask[hit]], na.rm = T))

    dat_cn <- cn
    dat_cn$index <- 1:nrow(dat_cn) * args$window_size - args$window_size / 2
    dat_cn$range <- paste0(dat_cn$seqnames, ':', dat_cn$start, '-', dat_cn$end)
    dat_cn$amount[as.numeric(names(hits2))] <- sapply(hits2, function(hit) length(!is.na(dat_clusters$mean_depth[hit])))
    dat_cn$mean_depth[as.numeric(names(hits2))] <- sapply(hits2, function(hit) mean(dat_clusters$mean_depth[hit], na.rm = T))
    dat_cn$sd_depth[as.numeric(names(hits2))] <- sapply(hits2, function(hit) sd(dat_clusters$mean_depth[hit], na.rm = T))

    x <- dat_cn$mean_depth ; y <- dat_cn$sd_depth ; m <- !is.na(y) & !is.na(x)
    dat_cn$resi <- NA; dat_cn$resi[m] <- lm(y[m] ~ x[m])$residuals

    weights <- dat_cn$amount / mean(dat_cn$amount, na.rm = T)
    dat_cn$weight <- weights * 2 * args$dot_factor

    dat_cn$mask <- dat_cn$amount >= as.numeric(quantile(dat_cn$amount[dat_cn$amount != 0], .05, na.rm = T)) &
      dat_cn$resi < as.numeric(quantile(dat_cn$resi, .95, na.rm = T)) &
      dat_cn$resi > as.numeric(quantile(dat_cn$resi, .05, na.rm = T))
    dat_cn$mask[is.na(dat_cn$mask)] <- F

    dat_cn$ratio <- log2(dat_cn$mean_depth / median(dat_cn$mean_depth[dat_cn$mask], na.rm = T))

    cd_object <- CNA(dat_cn$ratio[dat_cn$mask],
                     dat_cn$seqnames[dat_cn$mask],
                     dat_cn$start[dat_cn$mask], data.type = "logratio", sampleid = "X")
    capture.output(
      segmented_cd_object <- segment(cd_object, verbose=1, weights = dat_cn$weight[dat_cn$mask]),
      file = nullfile()
    )

    dat_seg <- segmented_cd_object$output
    dat_seg$loc.end <- dat_seg$loc.end + args$window_size - 1

    cn_plot <- plot_ly(dat_cn[dat_cn$mask,], x =~index, y =~ratio, text =~range, name = s,
                       height = 210 * length(args$samples_no_u),
                       marker = list(color = colors[1], alpha = .5, size = args$dot_factor * 2,
                                     line = list(color = colors[1], alpha = .5)),
                       type = 'scatter', mode = 'markers', hoverinfo = 'y+text')

    chr_lengths <- sapply(chrs, function(chr) length(which(dat_cn$seqnames == chr))) * args$window_size
    chr_cs <- c(0, sapply(chrs, function(chr) last(which(dat_cn$seqnames == chr))) * args$window_size)
    names(chr_cs) <- c(chrs, 'end')

    lower <- min(-2.25, quantile(dat_cn$ratio, na.rm = T, .01))
    upper <- max(2.25, quantile(dat_cn$ratio, na.rm = T, .99))
    ylim = c(lower, upper)

    for (i in 1:nrow(dat_seg)){
      st <- dat_seg$loc.start[i] + chr_cs[as.character(dat_seg$chrom[i])]
      e <- dat_seg$loc.end[i] + chr_cs[as.character(dat_seg$chrom[i])]
      h <- dat_seg$seg.mean[i]
      text <- paste0(as.character(dat_seg$chrom[i]), ':', dat_seg$loc.start[i], '-', dat_seg$loc.end[i])
      cn_plot <- cn_plot %>%
        add_trace(x = c(st,e), y = c(h, h), name = text,
                  line = list(color = colors[2], width = args$dot_factor),
                  text = paste0('segment: ', text), type='scatter', hoverinfo = 'y+text',
                  marker = list(color = colors[2], size = .1),
                  mode='lines+markers', inherit = T)
    }

    cn_plot <- cn_plot %>% layout(xaxis = list(title = args$samples_out[args$sample_ids == s],
                                               showticklabels = F, zeroline = F, showgrid = F),
                                  showlegend = F, yaxis = list(title = 'log2(ratio)', zeroline = F, range = ylim))

    cn_plot <- add_chr_lines(cn_plot, chr_cs, ylim)
    if (length(args$regions)){
      for (region in args$regions){
        cn_plot <- mark_region(cn_plot, chr_cs, ylim, region, chr_lengths)
      }
    }

    copy_number_plots[[s]] <- cn_plot
  }
  return(copy_number_plots)
}

# -----
# Man errors
# -----

#' Build a Mendelian-error figure for one child.
#' @param child A sample identifier.
#' @param father,mother Optional parent identifiers.
#' @param n_rel Number of plotted relationships.
#' @return A Plotly htmlwidget.
get_men_err_fig <- function(child, father, mother, n_rel){

  get_trio_error <- function(gt_child, gt_parent_1, gt_parent_2){
    trio_error <- rep(0, length(gt_child))

    m <- gt_parent_1 == '0/0' & gt_parent_2 == '0/0'
    trio_error[m] <- 1
    trio_error[m][gt_child[m] %in% c('0/1', '1/1')] <- 2

    m <- (gt_parent_1 == '0/1' & gt_parent_2 == '0/0') | (gt_parent_1 == '0/0' & gt_parent_2 == '0/1')
    trio_error[m] <- 1
    trio_error[m][gt_child[m] %in% c('1/1')] <- 2

    m <- (gt_parent_1 == '1/1' & gt_parent_2 == '0/1') | (gt_parent_1 == '0/1' & gt_parent_2 == '1/1')
    trio_error[m] <- 1
    trio_error[m][gt_child[m] %in% c('0/0')] <- 2

    m <- gt_parent_1 == '1/1' & gt_parent_2 == '1/1'
    trio_error[m] <- 1
    trio_error[m][gt_child[m] %in% c('0/0', '0/1')] <- 2

    m <- (gt_parent_1 == '0/0' & gt_parent_2 == '1/1') | (gt_parent_1 == '1/1' & gt_parent_2 == '0/0')
    trio_error[m] <- 1
    trio_error[m][gt_child[m] %in% c('0/0', '1/1')] <- 2

    return(trio_error)
  }

  get_duo_error <- function(gt_child, gt_parent){
    duo_error <- rep(0, length(gt_child))

    m <- gt_parent == '0/0'
    duo_error[m] <- 1
    duo_error[m][gt_child[m] %in% c('1/1')] <- 2

    m <- gt_parent == '1/1'
    duo_error[m] <- 1
    duo_error[m][gt_child[m] %in% c('0/0')] <- 2

    return(duo_error)
  }

  man_err_frame <- vcfs_filtered[[child]][,1:2]

  if (length(father) & length(mother)) man_err_frame$trio <- get_trio_error(vcfs_filtered[[child]]$GT,
                                                                            vcfs_filtered[[father]]$GT,
                                                                            vcfs_filtered[[mother]]$GT)
  if (length(father)) man_err_frame$fat <- get_duo_error(vcfs_filtered[[child]]$GT,
                                                         vcfs_filtered[[father]]$GT)
  if (length(mother)) man_err_frame$mot <- get_duo_error(vcfs_filtered[[child]]$GT,
                                                         vcfs_filtered[[mother]]$GT)

  man_err_frame_gr <- man_err_frame[,1:2] ; colnames(man_err_frame_gr) <- c('seqnames', 'start')
  man_err_frame_gr$end <- man_err_frame_gr$start + 1
  man_err_frame_gr <- GRanges(man_err_frame_gr)

  chr_lengths <- sapply(chrs, function(x) max(vcfs_filtered[[1]]$POS[vcfs_filtered[[1]]$CHROM == x]))
  x <- GRanges(seqnames = chrs, ranges = IRanges(start = 1, width = chr_lengths))
  x <- as.data.frame(slidingWindows(x, width = args$window_size, step = args$window_size))[,3:5]
  x_gr <- GRanges(x)

  x$index <- 1:nrow(x) * args$window_size - args$window_size / 2
  x$range <- paste0(x$seqnames, ':', x$start, '-', x$end)

  hits <- findOverlaps(x_gr, man_err_frame_gr, select = 'all')
  hits <- split(hits@to, hits@from)

  if (length(father) & length(mother)){
    x$trio <- 0
    x$trio[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man_err_frame$trio[hit] == 2)))
  }
  if (length(father)){
    x$fat <- 0
    x$fat[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man_err_frame$fat[hit] == 2)))
  }
  if (length(mother)){
    x$mot <- 0
    x$mot[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man_err_frame$mot[hit] == 2)))
  }

  me_plot <- plot_ly(x, x =~index, y = 0, height = 210 * n_rel,
                     line = list(color = colors[1], width = 0),
                     name = 'trio errors', type = 'scatter', mode = 'lines', hoverinfo = 'none')

  if (length(father) & length(mother)){
    me_plot <- me_plot %>% add_trace(x =~index, y =~trio, text =~range,
                                     line = list(color = colors[1], width = args$dot_factor),
                                     name = 'trio errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')

    me_plot <- me_plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$trio,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[1], opacity = .2)
  }

  if (length(father)){
    me_plot <- me_plot %>% add_trace(x =~index, y =~fat, text =~range,
                                     line = list(color = colors[2], width = args$dot_factor, dash = 'dot'),
                                     name = 'father errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')

    me_plot <- me_plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$fat,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[2], opacity = .2)
  }

  if (length(mother)){
    me_plot <- me_plot %>% add_trace(x =~index, y =~mot, text =~range,
                                     line = list(color = colors[3], width = args$dot_factor, dash = 'dot'),
                                     name = 'mother errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')

    me_plot <- me_plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$mot,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[3], opacity = .2)
  }

  ylim = c(0, max(x$trio, x$fat, x$mot, 50, na.rm = T))

  me_plot <- me_plot %>% layout(xaxis = list(title = args$samples_out[args$sample_ids == child],
                                             showticklabels = F, zeroline = F, showgrid = F),
                                showlegend = F, yaxis = list(title = 'mendelian error count', zeroline = F, range = ylim))

  chr_lengths <- sapply(chrs, function(chr) length(which(x$seqnames == chr))) * args$window_size
  chr_cs <- c(0, sapply(chrs, function(chr) last(which(x$seqnames == chr))) * args$window_size)
  names(chr_cs) <- c(chrs, 'end')

  me_plot <- add_chr_lines(me_plot, chr_cs, ylim)
  if (length(args$regions)){
    for (region in args$regions){
      me_plot <- mark_region(me_plot, chr_cs, ylim, region, chr_lengths)
    }
  }

  return(me_plot)
}

# -----
# BAF
# -----

#' Build region-specific B-allele-frequency figures.
#' @return A nested list of Plotly htmlwidgets.
get_region_baf <- function(){
  chr_lengths <- sapply(chrs, function(x) max(vcfs_filtered[[1]]$POS[vcfs_filtered[[1]]$CHROM == x]))
  bafs <- list()
  for (region in args$regions){
    c <- strsplit(region, ':')[[1]][1]
    st <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][1]) - args$regions_flanking_size
    st <- max(1, st)
    en <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][2]) + args$regions_flanking_size
    en <- min(chr_lengths[c], en)

    m <- vcfs_filtered[[1]]$CHROM == c & vcfs_filtered[[1]]$POS > st & vcfs_filtered[[1]]$POS < en
    for (s in args$samples_no_u){
      dat <- data.frame(paste0(vcfs_filtered[[s]]$CHROM[m], ':', vcfs_filtered[[s]]$pos_out[m]),
                        vcfs_filtered[[s]]$POS[m], vcfs_filtered[[s]]$AF[m] * 100)
      colnames(dat) <- c('id', 'index', 'AF')
      dat <- dat[!is.na(dat$AF),]

      baf <- plot_ly(dat, x =~index, y =~AF, text =~id, height = 300 * ceiling(length(args$samples_no_u) / 4),
                     marker = list(color = colors[1], alpha = .5,
                                   size = args$dot_factor * 2, line = list(color = colors[1], alpha = .5)),
                     type = 'scatter', mode = 'markers', hoverinfo = 'y+text')

      yaxis = list(title = 'BAF (%)', zeroline = F, range = c(-15,115), fixedrange = T)
      if (which(args$samples_no_u == s) %% 4 != 1) {
        yaxis = list(title = '', showticklabels = F, zeroline = F, range = c(-15,115), fixedrange = T)
      }
      baf <- baf %>% layout(xaxis = list(title = '',
                                         showticklabels = F, zeroline = F, showgrid = F),
                            showlegend = F, yaxis = yaxis,
                            annotations = list(list(
                              x = (st + en) / 2, y = -10,
                              text = args$samples_out[args$sample_ids == s],
                              showarrow = F, font = list(size = 11)
                            )))

      tmp <- c(1) ; names(tmp) <- c

      baf <- mark_region(baf, tmp, c(-5,105), region, chr_lengths, plot_flanks = F)

      region_out <- paste0(c, ':', scales::comma(st, accuracy = 1), ':', scales::comma(en, accuracy = 1))

      bafs[[region_out]][[s]] <- baf
    }
  }
  return(bafs)
}

#' Build genome-wide B-allele-frequency figures.
#' @param s A sample identifier.
#' @return A chromosome-indexed list of Plotly htmlwidgets.
get_genome_baf <- function(s){
  chr_lengths <- sapply(chrs, function(x) max(vcfs_filtered[[1]]$POS[vcfs_filtered[[1]]$CHROM == x]))
  bafs <- list()
  for (chr in chrs){
    chr_m <- vcfs_filtered[[s]]$CHROM == chr
    dat <- data.frame(paste0(vcfs_filtered[[s]]$CHROM[chr_m], ':', vcfs_filtered[[s]]$pos_out[chr_m]),
                      vcfs_filtered[[s]]$POS[chr_m], vcfs_filtered[[s]]$AF[chr_m] * 100)
    colnames(dat) <- c('id', 'index', 'AF')
    dat <- dat[!is.na(dat$AF),]

    if(args$limit_baf_to_p) dat <- dat[sort(sample(nrow(dat),round(nrow(dat) * args$value_of_p))),]

    ## raw data

    baf <- plot_ly(dat, x = ~index, y = ~AF, text =~id,
                   marker = list(color = colors[1], alpha = .5, size = args$dot_factor * 2,
                                 line = list(color = colors[1], alpha = .5)),
                   type = 'scattergl', mode = 'markers', hoverinfo = 'y+text', height = 1000 * 2)

    yaxis = list(title = 'BAF (%)', zeroline = F, range = c(-15,125), fixedrange = T)
    if (which(chrs == chr) %% 4 != 1) {
      yaxis = list(title = '', showticklabels = F, zeroline = F, range = c(-15,125), fixedrange = T)
    }
    baf <- baf %>% layout(xaxis = list(title = '',
                                       showticklabels = F, zeroline = F, showgrid = F),
                          showlegend = F, yaxis = yaxis,
                          annotations = list(list(
                            x = chr_lengths[[chr]] / 2, y = -10,
                            text = chr, showarrow = F, font = list(size = 11)
                          )))

    ## add region

    if (length(args$regions)){
      for (region in args$regions){
        if (chr == strsplit(region, ':')[[1]][1]){
          tmp <- 1 ; names(tmp) <- chr
          baf <- mark_region(baf, tmp, c(-5, 130), region, chr_lengths)
        }
      }
    }

    ## add cytobands

    if (length(args$cytoband_file)){
      baf <- add_cytoband(baf, chr, 120)
    } else {
      baf <- add_locus_bar(baf, chr, chr_lengths[[chr]], 120)
    }

    bafs[[chr]] <- baf
  }
  return(bafs)
}

# -----
# Parent mapping
# -----

#' Build parent-mapping figures.
#' @param child A sample identifier.
#' @param father,mother Optional parent identifiers.
#' @return A chromosome-indexed list of Plotly htmlwidgets.
get_pm <- function(child, father, mother){
  vcf_child <- vcfs_filtered[[child]]

  annot_list <- c('father 0/1 --- mother 0/0|1/1 --- child 0/1',
                  'father 0/1 --- mother 0/0|1/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/0|1/1')

  if (length(father) & length(mother)){
    vcf_fat <- vcfs_filtered[[father]]
    vcf_mot <- vcfs_filtered[[mother]]
    m1 <- vcf_fat$GT == '0/1' & vcf_mot$GT %in% c('0/0', '1/1')
    m2 <- vcf_mot$GT == '0/1' & vcf_fat$GT %in% c('0/0', '1/1')
  }
  if (length(father) & !length(mother)){
    vcf_fat <- vcfs_filtered[[father]]
    m1 <- vcf_fat$GT == '0/1'
    m2 <- vcf_fat$GT %in% c('0/0', '1/1')

    annot_list <- c('father 0/1 --- child 0/1',
                    'father 0/1 --- child 0/0|1/1',
                    'father 0/0|1/1 --- child 0/1',
                    'father 0/0|1/1 --- child 0/0|1/1')
  }
  if (!length(father) & length(mother)){
    vcf_mot <- vcfs_filtered[[mother]]
    m1 <- vcf_mot$GT %in% c('0/0', '1/1')
    m2 <- vcf_mot$GT == '0/1'

    annot_list <- c('mother 0/0|1/1 --- child 0/1',
                    'mother 0/0|1/1 --- child 0/0|1/1',
                    'mother 0/1 --- child 0/1',
                    'mother 0/1 --- child 0/0|1/1')
  }

  vcf_child$tracks[m1][vcf_child$GT[m1] == '0/1'] <- 5
  vcf_child$tracks[m1][vcf_child$GT[m1] %in% c('0/0', '1/1')] <- 4

  vcf_child$tracks[m2][vcf_child$GT[m2] == '0/1'] <- 2
  vcf_child$tracks[m2][vcf_child$GT[m2] %in% c('0/0', '1/1')] <- 1

  vcf_child$col <- NA
  vcf_child$col[which(vcf_child$tracks %in% 4:5)] <- colors[1]
  vcf_child$col[which(vcf_child$tracks %in% 1:2)] <- colors[2]

  chr_lengths <- sapply(chrs, function(x) max(vcfs_filtered[[1]]$POS[vcfs_filtered[[1]]$CHROM == x]))
  upds <- list()
  for (chr in chrs){
    chr_m <- vcfs_filtered[[1]]$CHROM == chr
    dat <- data.frame(paste0(vcf_child$CHROM[chr_m], ':', vcf_child$pos_out[chr_m]),
                      vcf_child$POS[chr_m], vcf_child$tracks[chr_m], vcf_child$col[chr_m])
    colnames(dat) <- c('id', 'index', 'track', 'col')
    dat <- dat[!is.na(dat$track),]

    if(args$limit_pm_to_p) dat <- dat[sort(sample(nrow(dat),round(nrow(dat) * args$value_of_p))),]

    ## raw data

    upd <- plot_ly(dat, x = ~index, y = ~track, text =~id,
                   marker = list(color =~ col, alpha = .5, size = args$dot_factor * 3,
                                 line = list(color =~ col, alpha = .5), symbol = 'cross-thin-open'),
                   type = 'scatter', mode = 'markers', hoverinfo = 'text', height = 1000,
                   hoverlabel=list(bgcolor=~col))

    upd <- upd %>% layout(xaxis = list(title = chr,
                                       showticklabels = F, zeroline = F, showgrid = F),
                          yaxis = list(title = '', showticklabels = F, zeroline = F,
                                       range = c(.5,6), fixedrange = T, showgrid = F),
                          showlegend = F)

    ## add region

    if (length(args$regions)){
      for (region in args$regions){
        if (chr == strsplit(region, ':')[[1]][1]){
          tmp <- 1 ; names(tmp) <- chr
          upd <- mark_region(upd, tmp, c(.5,5.5), region, chr_lengths)
        }
      }
    }

    ## add cytobands

    if (length(args$cytoband_file)){
      upd <- add_cytoband(upd, chr, 3)
    } else {
      upd <- add_locus_bar(upd, chr, chr_lengths[[chr]], 3)
    }

    upds[[chr]] <- upd
  }

  upd <- plot_ly(dat[1,], x = ~index, y = ~track, text =~id,
                 marker = list(color =~ 'white'),
                 type = 'scatter', mode = 'markers', hoverinfo = 'none', height = 1000)

  upd <- upd %>% layout(xaxis = list(title = '',
                                     showticklabels = F, zeroline = F, showgrid = F),
                        yaxis = list(title = '', showticklabels = F, zeroline = F,
                                     range = c(.5,6), fixedrange = T, showgrid = F),
                        showlegend = F,
                        annotations = list(list(x = chr_lengths[[chr]] / 2, y = 5, font = list(color = colors[1]),
                                                text = annot_list[1], showarrow = F),
                                           list(x = chr_lengths[[chr]] / 2, y = 4, font = list(color = colors[1]),
                                                text = annot_list[2], showarrow = F),
                                           list(x = chr_lengths[[chr]] / 2, y = 2, font = list(color = colors[2]),
                                                text = annot_list[3], showarrow = F),
                                           list(x = chr_lengths[[chr]] / 2, y = 1, font = list(color = colors[2]),
                                                text = annot_list[4], showarrow = F)))

  if (length(args$cytoband_file)){
    upd <- add_cytoband(upd, chr, 3)
  } else {
    upd <- add_locus_bar(upd, chr, chr_lengths[[chr]], 3)
  }

  upds[[24]] <- upd
  return(upds)
}
