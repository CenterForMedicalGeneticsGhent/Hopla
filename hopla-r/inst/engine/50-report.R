# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                       Functions: writing to HTML output
# ---------------------------------------------------------------------------------------------------------------------------------------------------

#' Assemble the complete interactive report.
#' @return An htmltools tag list containing Plotly htmlwidgets.
get_html_list <- function(){
  hopla_log('info', 'Generating visualizations, working ...')

  html_list <- list()
  append_list <- function(list, x){
    l <- list
    l[[length(l) + 1]] <- x
    return(l)
  }

  html_list <- append_list(html_list, tags$style(paste0('body{font-family:', report_font, ';}')))

  add_main_header <- function(html_list, h){
    html_list <- append_list(html_list, tags$hr())
    html_list <- append_list(html_list, tags$hr())
    html_list <- append_list(html_list, tags$h2(h))
    html_list <- append_list(html_list, tags$hr())
    html_list <- append_list(html_list, tags$hr())
    return(html_list)
  }

  get_empty <- function(){
    p <- plot_ly(x = 0, y = 0, name = NULL, type = 'scatter', mode = 'markers',
                 marker = list(color = 'white', size = .01), hoverinfo='skip')
    p <- p %>% layout(xaxis = list(title = '', showticklabels = F, zeroline = F, showgrid = F, fixedrange = T),
                      yaxis = list(title = '', showticklabels = F, zeroline = F, showgrid = F, fixedrange = T),
                      showlegend = F)
    return(p)
  }

  do_subplot <- function(plot_list, n_col = 1, panning = .03, margin = .02, override_hover_mode = NULL){
    n_row <- ceiling(length(plot_list) / n_col)

    plot_list_ap <- lapply(1:(n_col + 2), function(x) get_empty())
    for (i in 1:n_row){
      plot_list_ap <- c(plot_list_ap, lapply(1, function(x) get_empty()))
      s <- (1 + (i - 1) * n_col)
      e <- (n_col + (i - 1) * n_col)
      real_e <- length(plot_list)
      plot_list_ap <- c(plot_list_ap, plot_list[s:min(real_e, e)])
      plot_list_ap <- c(plot_list_ap, lapply(1, function(x) get_empty()))
    }
    plot_list_ap <- c(plot_list_ap, lapply((length(plot_list_ap)+1):((n_col+2)*(n_row+2)), function(x) get_empty()))

    heights <- c(panning, rep((1 - 2*panning) / n_row, n_row), panning)
    widths <- c(panning, rep((1 - 2*panning) / n_col, n_col), panning)
    this_subplot <- subplot(plot_list_ap, nrows=n_row+2, margin=margin, titleY=T, titleX=T,
                            heights=heights, widths = widths)
    this_subplot$x$layout$font$family <- report_font
    if (!is.null(override_hover_mode)) this_subplot$x$layout$hovermode <- override_hover_mode
    return(this_subplot)
  }

  get_ado <- function(vcf_list, mother, father, child){
    ado_set <- vcf_list[[1]]$ID[which((vcf_list[[mother]]$GT == '0/0' & vcf_list[[father]]$GT == '1/1') |
                                        (vcf_list[[father]]$GT == '0/0' & vcf_list[[mother]]$GT == '1/1'))]
    ado_table <- table(vcf_list[[child]]$GT[which(vcf_list[[child]]$ID %in% ado_set)])
    ado = round(sum(ado_table[which(names(ado_table) %in% c('0/0', '1/1'))]) /
                  sum(ado_table[which(names(ado_table) %in% c('0/0', '0/1', '1/1'))]) * 100, 2)
    return(paste0(ado, '%'))
  }

  get_adi <- function(vcf_list, mother, father, child){
    adi_set <- vcf_list[[1]]$ID[which((vcf_list[[mother]]$GT == '1/1' & vcf_list[[father]]$GT == '1/1'))]
    adi_table <- table(vcf_list[[child]]$GT[which(vcf_list[[child]]$ID %in% adi_set)])
    adi = round(sum(adi_table[which(names(adi_table) %in% c('0/1'))]) /
                  sum(adi_table[which(names(adi_table) %in% c('0/0', '0/1', '1/1'))]) * 100, 2)
    return(paste0(adi, '%'))
  }

  ## info

  if (length(args$info)){
    html_list <- add_main_header(html_list, "Family/disease information")
    for (part in args$info){
      html_list <- append_list(html_list, tags$p(part))
    }
  }

  ## pedigree

  if (length(args$samples_no_u) > 1){
    hopla_log('debug', '  ... at pedigree')

    html_list <- add_main_header(html_list, "Family tree")

    write_pedigree(paste0(args$out_bs, 'ped.tree.png'))
    x <- htmltools::img(src = file_data_uri(paste0(args$out_bs, 'ped.tree.png')),
                        style = paste0('height:',5*100,'px;width:',log(length(args$sample_ids)) * 4 * 100,'px'))
    invisible(file.remove(paste0(args$out_bs, 'ped.tree.png')))
    html_list <- append_list(html_list, x)
  }

  # raw

  html_list <- add_main_header(html_list, "Filter 0: single nucleotide variants")

  ## variant statistics

  html_list <- append_list(html_list, tags$h3("Variant statistics"))

  add_tot_number_of_variants <- function(html_list, vcf_list){
    nvars <- c()
    for (s in args$samples_no_u){
      nvars <- c(nvars, paste0(s, ': ', scales::comma(nrow(vcf_list[[s]][vcf_list[[s]]$GT %in% c('0/0', '0/1', '1/1'),]), accuracy = 1)))
    }
    html_list <- append_list(html_list, tags$p(paste0('° overall; ', paste0(nvars, collapse = ' | '))))

    get_vars_in_region <- function(vcf_list, sample, region){
      r_split <- strsplit(region, ':')[[1]]
      c = r_split[1]
      s <- as.numeric(strsplit(r_split[2],'-')[[1]][1])
      e <- as.numeric(strsplit(r_split[2],'-')[[1]][2])
      x <- vcf_list[[sample]]
      n1 <- length(which(x$CHROM == c & x$POS >= s & x$POS <= e & x$GT %in% c('0/0', '0/1', '1/1')))
      s_flank <- s - args$regions_flanking_size
      e_flank <- e + args$regions_flanking_size
      n2 <- length(which(x$CHROM == c & x$POS >= s_flank & x$POS <= s & x$GT %in% c('0/0', '0/1', '1/1')))
      n3 <- length(which(x$CHROM == c & x$POS >= e & x$POS <= e_flank & x$GT %in% c('0/0', '0/1', '1/1')))
      return(list(n1 = n1, n2 = n2, n3 = n3))
    }

    for (region in args$regions){
      nvars <- c()
      for (s in args$samples_no_u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get_vars_in_region(vcf_list, s, region)$n1, accuracy = 1)))
      }
      html_list <- append_list(html_list, tags$p(paste0('° in ', region, '; ', paste0(nvars, collapse = ' | '))))

      nvars <- c()
      for (s in args$samples_no_u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get_vars_in_region(vcf_list, s, region)$n2, accuracy = 1)))
      }
      html_list <- append_list(html_list, tags$p(paste0('° in ', region, ' (left flank); ', paste0(nvars, collapse = ' | '))))

      nvars <- c()
      for (s in args$samples_no_u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get_vars_in_region(vcf_list, s, region)$n3, accuracy = 1)))
      }
      html_list <- append_list(html_list, tags$p(paste0('° in ', region, ' (right flank); ', paste0(nvars, collapse = ' | '))))
    }
    return(html_list)
  }

  hopla_log('debug', '  ... at total number of variants (raw)')

  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs)

  hopla_log('debug', '  ... at number of variants table (raw)')

  html_list <- append_list(html_list, tags$h4("Number of variants table"))
  html_list <- append_list(html_list, get_plotly_table(vcfs))

  if (length(args$samples_no_u) > 1){
    html_list <- append_list(html_list, tags$h4("Allelic drop-out (ADO) & allelic drop-in (ADI)"))
    for (child in args$samples_no_u){
      father <- args$father_ids[args$sample_ids == child]
      mother <- args$mother_ids[args$sample_ids == child]

      has_father <- !is.na(father) & !(father %in% args$samples_u)
      has_mother <- !is.na(mother) & !(mother %in% args$samples_u)

      html_list <- append_list(html_list, tags$h5(child))

      if (has_mother & has_father){
        html_list <- append_list(html_list, tags$p(paste0(
          'ADO = ', get_ado(vcfs, mother, father, child))))
        html_list <- append_list(html_list, tags$p(paste0(
          'ADI = ', get_adi(vcfs, mother, father, child))))
      } else {
        html_list <- append_list(html_list, tags$p('no two parents provided'))
      }
    }
  }

  ## var depth

  hopla_log('debug', '  ... at variant depth (raw)')

  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs), n_col = 4))

  ## number of variants

  hopla_log('debug', '  ... at number of variants profile (raw)')

  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs))))

  ## copy number

  hopla_log('debug', '  ... at vcf-based copy number (raw)')

  html_list <- append_list(html_list, tags$h3("Vcf-based copy number (bam-based verification recommended)"))
  html_list <- append_list(html_list, do_subplot(get_cn_fig()))

  # filtered 1

  html_list <- add_main_header(html_list, "Filter 1: filter 0, --dp_hard_limit, af_hard_limit and --dp_soft_limit")

  ## variant statistics

  html_list <- append_list(html_list, tags$h3("Variant statistics"))

  hopla_log('debug', '  ... at total number of variants (filter 1)')

  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs_filtered)

  hopla_log('debug', '  ... at number of variants table (filter 1)')

  html_list <- append_list(html_list, tags$h4("Number of variants table"))
  html_list <- append_list(html_list, get_plotly_table(vcfs_filtered))

  n_rel <- 0
  if (length(args$samples_no_u) > 1){
    html_list <- append_list(html_list, tags$h4("Allelic drop-out (ADO) & allelic drop-in (ADI)"))
    for (child in args$samples_no_u){
      father <- args$father_ids[args$sample_ids == child]
      mother <- args$mother_ids[args$sample_ids == child]

      has_father <- !is.na(father) & !(father %in% args$samples_u)
      has_mother <- !is.na(mother) & !(mother %in% args$samples_u)

      html_list <- append_list(html_list, tags$h5(child))

      if (has_mother | has_father) n_rel <- n_rel + 1

      if (has_mother & has_father){
        html_list <- append_list(html_list, tags$p(paste0(
          'ADO = ', get_ado(vcfs_filtered, mother, father, child))))
        html_list <- append_list(html_list, tags$p(paste0(
          'ADI = ', get_adi(vcfs_filtered, mother, father, child))))
      } else {
        html_list <- append_list(html_list, tags$p('no two parents provided'))
      }
    }
  }

  ## var depth

  hopla_log('debug', '  ... at variant depth (filter 1)')

  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs_filtered), n_col = 4))

  ## number of variants

  hopla_log('debug', '  ... at number of variants profile (filter 1)')

  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs_filtered))))

  ## BAF

  if (length(args$regions)){
    hopla_log('debug', '  ... at B-allele frequency (regions; filter 1)')
    html_list <- append_list(html_list, tags$h3("B-allele frequency (BAF), region(s) of interest"))
    regions_baf <- get_region_baf()
    for (region in names(regions_baf)){
      html_list <- append_list(html_list, tags$h4(region))
      html_list <- append_list(html_list, do_subplot(regions_baf[[region]], n_col = 4,
                                                     panning = .06, margin = .05))
    }
  }

  ## BAF detail

  if (length(args$baf_ids)){
    hopla_log('debug', '  ... at B-allele frequency (genome-wide; filter 1)')
    if (args$limit_baf_to_p){
      html_list <- append_list(html_list,
                               tags$h3(paste0("B-allele frequency (BAF), genome-wide, only ", args$value_of_p * 100,"% of data")))
    } else {
      html_list <- append_list(html_list, tags$h3("B-allele frequency (BAF), genome-wide"))
    }
    for (s in args$baf_ids){
      html_list <- append_list(html_list, tags$h4(args$samples_out[args$sample_ids == s]))
      html_list <- append_list(html_list, do_subplot(get_genome_baf(s), n_col = 2,
                                                     panning = .03, margin = .02))
    }
  }

  ## Mendelian errors

  if (length(args$sample_ids) > 1){

    men_err_plots <- list()
    for (s in args$samples_no_u){
      father <- args$father_ids[args$sample_ids == s]
      mother <- args$mother_ids[args$sample_ids == s]

      has_father <- !is.na(father) & !(father %in% args$samples_u)
      has_mother <- !is.na(mother) & !(mother %in% args$samples_u)

      if (length(father[has_father]) | length(mother[has_mother])){
        men_err_plots[[s]] <- get_men_err_fig(s, father[has_father], mother[has_mother], n_rel)
      }
    }
    if (length(men_err_plots)){
      hopla_log('debug', '  ... at mendelian errors (filter 1)')

      html_list <- append_list(html_list, tags$h3("Mendelian errors"))
      html_list <- append_list(html_list, do_subplot(men_err_plots, n_col = 1))
    }
  }

  ## Parent mapping

  if (length(args$sample_ids) > 1){
    hopla_log('debug', '  ... at parent mapping (filter 1)')
    if (args$limit_pm_to_p){
      html_list <- append_list(html_list, tags$h3(paste0("Parent mapping, only", args$value_of_p * 100,"% of data")))
    } else {
      html_list <- append_list(html_list, tags$h3("Parent mapping"))
    }
    for (s in args$samples_no_u){
      father <- args$father_ids[args$sample_ids == s]
      mother <- args$mother_ids[args$sample_ids == s]

      has_father <- !is.na(father) & !(father %in% args$samples_u)
      has_mother <- !is.na(mother) & !(mother %in% args$samples_u)

      if (length(father[has_father]) | length(mother[has_mother])){
        html_list <- append_list(html_list, tags$h4(args$samples_out[args$sample_ids == s]))
        html_list <- append_list(html_list, do_subplot(get_pm(s, father[has_father], mother[has_mother]), n_col = 4))
      }
    }
  }

  # filtered 2

  html_list <- add_main_header(html_list, "Filter 2: filter 0, filter 1, keep_informative_ids and --keep_hetero_ids")

  ## variant statistics

  html_list <- append_list(html_list, tags$h3("Variant statistics"))

  hopla_log('debug', '  ... at total number of variants (filter 2)')

  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs_filtered2)

  hopla_log('debug', '  ... at number of variants table (filter 2)')

  html_list <- append_list(html_list, tags$h4("Number of variants table"))
  html_list <- append_list(html_list, get_plotly_table(vcfs_filtered2))

  ## var depth

  hopla_log('debug', '  ... at variant depth (filter 2)')

  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs_filtered2), n_col = 4))

  ## number of variants

  hopla_log('debug', '  ... at number of variants profile (filter 2)')

  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs_filtered2))))

  ## Merlin

  if (args$run_merlin){

    hopla_log('debug', '  ... at Merlin (filter 2)')

    html_list <- append_list(html_list, tags$h3("Haplotyping by Merlin"))
    html_list <- append_list(html_list, do_subplot(get_haplo_profiles(), n_col = 2, panning = .015, margin = .007,
                                                   override_hover_mode = 'X unified'))

    if (args$concordance_table){
      html_list <- append_list(html_list, tags$h3("Haplotyping by Merlin: strand concordance"))
      html_list <- append_list(html_list, get_haplo_tables())
    }
  }

  return(html_list)
}

#' Replace all regular-expression matches in a string.
#' @param text A character scalar.
#' @param pattern A Perl-compatible regular expression.
#' @param replacement A function that transforms one match.
#' @return The transformed string.
replace_matches <- function(text, pattern, replacement){
  match <- gregexpr(pattern, text, perl = T)[[1]]
  if (match[1] == -1) return(text)
  lengths <- attr(match, 'match.length')
  for (i in rev(seq_along(match))){
    value <- substr(text, match[i], match[i] + lengths[i] - 1)
    text <- paste0(
      substr(text, 1, match[i] - 1),
      replacement(value),
      substr(text, match[i] + lengths[i], nchar(text))
    )
  }
  text
}

#' Compress htmlwidget JSON payloads for browser-side inflation.
#' @param html A complete HTML document.
#' @return The HTML document with compressed widget data.
compress_widget_data <- function(html){
  compressed_count <- 0L
  html <- replace_matches(
    html,
    '<script(?=[^>]*\\btype=[\"\']application/json[\"\'])(?=[^>]*\\bdata-for=[\"\'][^\"\']+[\"\'])[^>]*>.*?</script>',
    function(tag){
      opening_end <- regexpr('>', tag, fixed = T)[1]
      opening <- substr(tag, 1, opening_end)
      payload <- substr(tag, opening_end + 1L, nchar(tag) - nchar('</script>'))
      encoded <- base64enc::base64encode(memCompress(charToRaw(enc2utf8(payload)), type = 'gzip'))
      if (nchar(encoded) >= nchar(payload)) return(tag)
      compressed_count <<- compressed_count + 1L
      opening <- sub(
        'type=[\"\']application/json[\"\']',
        'type=\"application/gzip+json\"',
        opening
      )
      paste0(opening, encoded, '</script>')
    }
  )
  if (!compressed_count) return(html)

  bootstrap <- paste0(
    '<script>(function(){',
    'var original=window.HTMLWidgets.staticRender,preparation;',
    'function inflate(element){',
    'var binary=atob(element.textContent.trim()),bytes=new Uint8Array(binary.length);',
    'for(var i=0;i<binary.length;i++)bytes[i]=binary.charCodeAt(i);',
    'var stream=new Blob([bytes]).stream().pipeThrough(new DecompressionStream(\"deflate\"));',
    'return new Response(stream).text().then(function(json){',
    'element.textContent=json;element.type=\"application/json\";',
    '});',
    '}',
    'window.HTMLWidgets.staticRender=function(){',
    'var context=this,args=arguments;',
    'if(!preparation)preparation=Promise.all(Array.from(document.querySelectorAll(',
    '\"script[type=\\\"application/gzip+json\\\"][data-for]\"',
    ')).map(inflate));',
    'return preparation.then(function(){return original.apply(context,args);}).catch(function(error){',
    'console.error(\"Could not decompress Hopla report data\",error);',
    '});',
    '};',
    '})();</script>'
  )
  sub('</head>', paste0(bootstrap, '\n</head>'), html, fixed = T)
}

#' Inline local report dependencies without Pandoc.
#' @return Invisible `NULL`.
transform_to_selfcontained <- function(){
  hopla_log('info', 'Converting to self-contained HTML ...')

  attribute_path <- function(tag, attribute){
    sub(
      paste0('.*\\b', attribute, '=[\"\']([^\"\']+)[\"\'].*'),
      '\\1',
      tag,
      perl = T
    )
  }

  output_file <- paste0(args$out_bs, 'output.html')
  output_dir <- dirname(output_file)
  html <- paste(readLines(output_file, warn = F), collapse = '\n')

  html <- replace_matches(
    html,
    '<script[^>]+src=[\"\'][^\"\']+[\"\'][^>]*>\\s*</script>',
    function(tag){
      file <- file.path(output_dir, attribute_path(tag, 'src'))
      if (!file.exists(file)) return(tag)
      javascript <- paste(readLines(file, warn = F), collapse = '\n')
      javascript <- gsub('</script', '<\\\\/script', javascript, fixed = T)
      paste0('<script>', javascript, '</script>')
    }
  )

  html <- replace_matches(
    html,
    '<link[^>]+href=[\"\'][^\"\']+[\"\'][^>]*>',
    function(tag){
      file <- file.path(output_dir, attribute_path(tag, 'href'))
      if (!file.exists(file)) return(tag)
      css <- paste(readLines(file, warn = F), collapse = '\n')
      css <- replace_matches(
        css,
        'url\\([\"\']?[^)\"\']+[\"\']?\\)',
        function(url){
          relative <- sub('^url\\([\"\']?([^\"\')]+)[\"\']?\\)$', '\\1', url, perl = T)
          asset <- file.path(dirname(file), relative)
          if (!file.exists(asset) || grepl('^(data:|https?:)', relative)) return(url)
          paste0('url(\"', file_data_uri(asset), '\")')
        }
      )
      paste0('<style>', css, '</style>')
    }
  )

  html <- replace_matches(
    html,
    '(src|href)=[\"\'][^\"\'#]+[\"\']',
    function(attribute){
      name <- sub('=.*$', '', attribute)
      relative <- sub('^[^=]+=[\"\']([^\"\']+)[\"\']$', '\\1', attribute, perl = T)
      file <- file.path(output_dir, relative)
      if (!file.exists(file) || grepl('^(data:|https?:)', relative)) return(attribute)
      paste0(name, '=\"', file_data_uri(file), '\"')
    }
  )
  html <- compress_widget_data(html)

  temporary_file <- paste0(output_file, '.selfcontained')
  writeLines(html, temporary_file, useBytes = T)
  if (!file.rename(temporary_file, output_file)){
    unlink(temporary_file)
    stop('Could not replace HTML with self-contained output.')
  }
  unlink(paste0(args$out_bs, 'output_files'), recursive = T)
}
