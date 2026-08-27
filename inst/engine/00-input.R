# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                  Functions: parameter & vcf loading and parsing
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Parameter parsing
# -----

#' Trim leading and trailing whitespace.
#' @param x A character vector.
#' @return A character vector.
trim_whitespace <- function (x) gsub("^\\s+|\\s+$", "", x)

#' Split phased genotype strings into two strands.
#' @param x A character vector containing `|`.
#' @return A two-element list of character vectors.
split_strands <- function(x){
  stopifnot(is.character(x))
  data.table::tstrsplit(x, '|', fixed = T, keep = 1:2)
}

array_args <- c(
  'sample_ids', 'father_ids', 'mother_ids', 'genders',
  'dp_hard_limit_ids', 'af_hard_limit_ids', 'dp_soft_limit_ids',
  'keep_informative_ids', 'keep_hetero_ids', 'regions', 'reference_ids',
  'carrier_ids', 'affected_ids', 'nonaffected_ids', 'info', 'baf_ids'
)

#' Print command-line help.
#' @return Invisible `NULL`.
print_help <- function(){
  cat('Usage: hopla-run.R SETTINGS.{yaml,yml,json} VCF OUT_DIR [CYTOBAND]\n\n')
  cat('The settings file is validated against hopla.schema.json before analysis.\n')
  cat('VCF, OUT_DIR, and CYTOBAND are command-line paths and must already exist.\n')
  cat('The hg38 cytoband table is downloaded from UCSC when CYTOBAND is omitted.\n')
  cat('Use YAML or JSON arrays for list options such as sample_ids and regions.\n\n')
  cat('  -h, --help       Show this help and exit\n')
  cat('  -V, --version    Show the version and exit\n')
  invisible(NULL)
}

#' Read and validate a Hopla YAML or JSON settings file.
#' @param settings_file Path to a settings file.
#' @param defaults A named list of default values.
#' @param schema_file Path to the Hopla JSON Schema.
#' @return A validated argument list overlaid on the defaults.
get_settings_args <- function(settings_file, defaults, schema_file){
  if (!file.exists(settings_file)){
    hopla_fail('Settings file does not exist: ', settings_file, status = 2)
  }
  if (!file.exists(schema_file)){
    hopla_fail('Settings schema does not exist: ', schema_file, status = 2)
  }

  extension <- tolower(tools::file_ext(settings_file))
  if (!(extension %in% c('yaml', 'yml', 'json'))){
    hopla_fail('Settings file must use a .yaml, .yml, or .json extension.', status = 2)
  }

  if (extension == 'json'){
    json <- paste(readLines(settings_file, warn = F), collapse = '\n')
  } else {
    yaml_settings <- yaml::read_yaml(settings_file)
    if (!is.list(yaml_settings) || is.null(names(yaml_settings))){
      hopla_fail('YAML settings must contain a mapping at the document root.', status = 2)
    }
    for (arg in intersect(names(yaml_settings), array_args)){
      if (!is.list(yaml_settings[[arg]])) yaml_settings[[arg]] <- as.list(yaml_settings[[arg]])
    }
    json <- jsonlite::toJSON(yaml_settings, auto_unbox = T, null = 'null', na = 'null')
  }

  valid <- jsonvalidate::json_validate(json, schema_file, verbose = T)
  if (!isTRUE(valid)){
    errors <- attr(valid, 'errors')
    hopla_fail('Settings validation failed:\n', paste(capture.output(print(errors)), collapse = '\n'), status = 2)
  }

  settings <- jsonlite::fromJSON(json, simplifyVector = T)
  for (arg in names(settings)){
    value <- settings[[arg]]
    if (arg %in% array_args && is.list(value)){
      value <- vapply(value, function(x) if (is.null(x)) NA_character_ else as.character(x), character(1))
    }
    defaults[[arg]] <- unname(value)
  }
  defaults
}

#' Validate and derive dependent arguments.
#' @param args A named argument list.
#' @return A validated argument list.
post_process_args <- function(args){
  stopifnot(is.list(args))
  no_u_mask <- !sapply(args$sample_ids, function(x) toupper(substr(x,1,1)) == 'U' &
                         !is.na(suppressWarnings(as.numeric(substr(x,2,999)))))

  if (!length(args$genders)) args$genders = rep(NA, length(args$sample_ids))
  if (!length(args$mother_ids)) args$mother_ids = rep(NA, length(args$sample_ids))
  if (!length(args$father_ids)) args$father_ids = rep(NA, length(args$sample_ids))

  args$samples_no_u <- args$sample_ids[no_u_mask]
  args$samples_u <- args$sample_ids[!no_u_mask]

  not_last_in_line <- unique(c(args$mother_ids, args$father_ids))
  not_last_in_line <- not_last_in_line[not_last_in_line %in% args$samples_no_u]
  last_in_line <- args$samples_no_u[!args$samples_no_u %in% not_last_in_line]

  if (length(args$samples_no_u) == 1){
    not_last_in_line = args$samples_no_u
    last_in_line = args$samples_no_u
  }

  if (!length(args$dp_hard_limit_ids)) args$dp_hard_limit_ids = not_last_in_line
  if (!length(args$af_hard_limit_ids)) args$af_hard_limit_ids = not_last_in_line
  if (!length(args$dp_soft_limit_ids)) args$dp_soft_limit_ids = last_in_line
  if (!length(args$window_size_voting_x)) args$window_size_voting_x = args$window_size_voting
  if (!length(args$min_seg_var_x)) args$min_seg_var_x = args$min_seg_var

  man_args <- c('sample_ids')
  for (arg in names(args)){
    if (!length(args[[arg]]) & arg %in% man_args){
      hopla_fail('Setting ', arg, ' is mandatory. Please provide.')
    }
  }

  not_in_error <- function(arg){
    not_in <- function(xs, ys){
      for (x in xs){
        if (!(x %in% ys) & !is.na(x)){
          return(x)
        }
      }
      return(NULL)
    }
    if (length(not_in(args[[arg]], args$sample_ids))){
      hopla_fail('Value from setting ', arg, ', \'', not_in(args[[arg]], args$sample_ids),
                 '\' could not be found in sample_ids. Please correct.')
    }
  }

  hopla_log('info', 'Selected parameters ...')
  for (arg in names(args)[!(names(args) %in% c('samples_u', 'samples_no_u'))]){
    if (!length(args[[arg]])) next
    hopla_log('info', '  ... ', arg, ': ', paste(args[[arg]], collapse = ','))

    if (any(is.na(args[[arg]])) & !(arg %in% c('father_ids', 'mother_ids', 'genders'))){
      hopla_fail('No NA allowed in setting ', arg, '. Please correct.')
    }

    if (arg == 'sample_ids'){
      if (length(args$sample_ids) > 1){
        if (!length(which(!is.na(args$mother_ids))) & !length(which(!is.na(args$father_ids)))){
          hopla_fail('More than one sample is given in sample_ids. Provide their relation using ',
              'father_ids and/or mother_ids. Otherwise, run separately.')
        }
      }
    }

    if (arg == 'genders'){
      if (!all(args$genders %in% c('M', 'F', NA))){
        hopla_fail("Setting 'genders' should be coded as 'M', 'F' or 'NA'. Please correct.")
      }
    }

    for (same_length_arg in c('father_ids', 'mother_ids', 'genders')){
      if (arg == same_length_arg){
        if (!(length(args$sample_ids) == length(args[[same_length_arg]]))){
          hopla_fail('Settings sample_ids and ', same_length_arg,' should be of the same length. Please correct.')
        }
      }
    }

    if (arg %in% c('father_ids', 'mother_ids', 'dp_hard_limit_ids', 'af_hard_limit_ids',
                  'dp_soft_limit_ids', 'keep_informative_ids', 'keep_hetero_ids',
                  'reference_ids', 'carrier_ids', 'affected_ids',
                  'nonaffected_ids', 'baf_ids')){
      not_in_error(arg)
    }

    if (arg %in% c('dp_hard_limit_ids', 'af_hard_limit_ids', 'dp_soft_limit_ids',
                   'keep_informative_ids', 'keep_hetero_ids', 'baf_ids')){
      if (length(intersect(args[[arg]], args$samples_u))){
        hopla_fail("'U' IDs not allowed in setting ", arg, '. Please correct.')
      }
    }

    if (arg == 'run_merlin' & args$run_merlin){
      if (length(args$sample_ids) == 1){
        hopla_log('warn', 'Only one sample provided. Setting run_merlin FALSE.')
        args$run_merlin = F
      }
      if ((Sys.which('merlin') == '' | Sys.which('minx') == '') & args$run_merlin){
        hopla_log('warn', 'Merlin executables folder could not be located in $PATH. Setting run_merlin FALSE.')
        args$run_merlin = F
      }
    }

    if (arg == 'keep_informative_ids'){
      if (!(length(args[[arg]]) %in% c(0,2))){
        hopla_fail('No or two samples should be given at keep_informative_ids. Please correct.')
      }
    }

    if (arg == 'merlin_model'){
      if (!(args$merlin_model %in% c('sample', 'best'))){
        hopla_fail('Setting merlin_model should be coded as \'sample\' or \'best\'. Please correct.')
      }
    }

    if (arg == 'value_of_p'){
      if (args$value_of_p <= 0 | args$value_of_p > 1){
        hopla_fail('value_of_p should be within ]0, 1]. Please correct.')
      }
    }
    if (arg == 'af_hard_limit'){
      if (args$af_hard_limit < 0 | args$af_hard_limit >= 1){
        hopla_fail('af_hard_limit should be within [0, 1[. Please correct.')
      }
    }
  }

  add_annot <- function(letter, annot = NULL){
    if (!is.null(annot)){
      args$samples_out[args$sample_ids %in% args[[annot]]] <- paste0(args$samples_out[args$sample_ids %in% args[[annot]]],
                                                                     ' (', letter, ')')
    } else {
      known_set <- unique(c(args$reference_ids, args$carrier_ids, args$affected_ids, args$nonaffected_ids))
      args$samples_out[!(args$sample_ids %in% known_set)] <- paste0(args$samples_out[!(args$sample_ids %in% known_set)],
                                                                    ' (', letter, ')')
    }
    return(args)
  }
  args$samples_out <- args$sample_ids
  args <- add_annot('R', 'reference_ids')
  args <- add_annot('C', 'carrier_ids')
  args <- add_annot('A', 'affected_ids')
  args <- add_annot('N', 'nonaffected_ids')

  return(args)
}

# -----
# Cytobands
# -----

default_cytoband_url <- 'https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/cytoBand.txt.gz'

#' Download and decompress the default hg38 UCSC cytoband table.
#' @param url Source URL for a gzip-compressed cytoband table.
#' @return Path to the uncompressed cytoband file.
fetch_hg38_cytoband_file <- function(url = default_cytoband_url){
  stopifnot(is.character(url), length(url) == 1)
  hopla_log('info', 'No cytoband_file given; downloading hg38 cytoBand.txt.gz from UCSC ...')
  compressed <- tempfile('hopla-cytoBand', fileext = '.txt.gz')
  uncompressed <- tempfile('hopla-cytoBand', fileext = '.txt')
  status <- tryCatch(
    utils::download.file(url, compressed, mode = 'wb', quiet = TRUE),
    error = function(error) {
      hopla_fail('Could not download the default cytoband file from UCSC: ',
                  conditionMessage(error))
    }
  )
  if (!identical(as.integer(status), 0L) || !file.exists(compressed) ||
      isTRUE(file.info(compressed)$size == 0)) {
    hopla_fail('Could not download the default cytoband file from UCSC.')
  }

  input <- gzfile(compressed, open = 'rt')
  lines <- readLines(input, warn = FALSE)
  close(input)
  unlink(compressed)
  if (!length(lines)) {
    hopla_fail('Downloaded cytoband file is empty.')
  }
  writeLines(lines, uncompressed)
  uncompressed
}

#' Load chromosome cytobands.
#' @param file Path to a tab-separated cytoband file.
#' @return A named list of cytoband records.
get_cytobands <- function(file){
  cytobands <- list()
  chrs_to_index <- sapply(chrs, function(x) which(chrs == x))
  hopla_log('info', 'Loading and parsing cytoband file ...')
  cyto <- read.csv(file, sep = '\t', header = F, stringsAsFactors = F)
  if (substr(cyto$V1[1], 1, 3) != 'chr') cyto$V1 <- paste0('chr', cyto$V1)
  cyto$V4[cyto$V4 == ''] <- cyto$V5[cyto$V4 == '']
  cyto$V4[grepl('acen', cyto$V5)] <- paste0(cyto$V4[grepl('acen', cyto$V5)], ' (acen)')
  cyto$V4[grepl('gvar', cyto$V5)] <- paste0(cyto$V4[grepl('gvar', cyto$V5)], ' (gvar)')
  cyto$V4[grepl('stalk', cyto$V5)] <- paste0(cyto$V4[grepl('stalk', cyto$V5)], ' (stalk)')
  cyto <- cyto[cyto$V1 %in% chrs,] ; cyto <- cyto[order(chrs_to_index[cyto$V1], cyto$V2),]
  cyto$V2 <- cyto$V2 + 1
  for(i in 1:nrow(cyto)){
    cytobands[[cyto$V1[i]]][[length(cytobands[[cyto$V1[i]]]) + 1]] <- list('name'=cyto$V4[i], 'start'=cyto$V2[i],
                                                                           'end'=cyto$V3[i])
  }
  return(cytobands)
}

# -----
# Load
# -----

#' Load selected samples from a VCF.
#' @param args A validated argument list.
#' @return A named list of sample data frames.
load_samples <- function(args){
  hopla_log('info', 'Loading vcf.gz ...')
  vcf <- read.vcfR(args$vcf_file, verbose = F)

  ## vcf_a (annot)
  vcf_a <- as.data.frame(vcf@fix)
  if (substr(vcf_a$CHROM[1], 1, 3) != 'chr') vcf_a$CHROM <- paste0('chr', vcf_a$CHROM)
  vcf_a$ID <- as.character(paste0('id', 1:nrow(vcf_a)))

  vcf_a <- vcf_a[,c('CHROM', 'POS', 'ID', 'REF', 'ALT')]
  vcf_a$POS <- as.numeric(as.character(vcf_a$POS))
  for (x in c('CHROM', 'ID', 'REF', 'ALT')) vcf_a[[x]] <- as.character(vcf_a[[x]])

  snp_mask <- nchar(vcf_a$REF) == 1 & nchar(vcf_a$ALT) == 1 & vcf_a$CHROM %in% c(chrs, 'chrY')
  available_samples <- colnames(vcf@gt)[-1]
  hopla_log('info', '  ... available samples in vcf_file: ', paste0(available_samples, collapse = ','))
  missing_samples <- args$samples_no_u[!(args$samples_no_u %in% available_samples)]
  if (length(missing_samples)){
    hopla_fail('Sample(s) not found in vcf_file: ', paste(missing_samples, collapse = ', '), '.')
  }

  vcf_a <- vcf_a[snp_mask,]
  genotypes <- extract.gt(vcf, element = 'GT', convertNA = F)[snp_mask, args$samples_no_u, drop = F]
  allele_depths <- extract.gt(vcf, element = 'AD', convertNA = F)[snp_mask, args$samples_no_u, drop = F]
  depths <- extract.gt(vcf, element = 'DP', as.numeric = T)[snp_mask, args$samples_no_u, drop = F]
  rm(vcf)
  invisible(gc())

  vcfs <- list()
  pos_out <- scales::comma(vcf_a$POS, accuracy = 1)
  hopla_log('info', 'Parsing variants, working ...')

  for (sample in args$samples_no_u){
    hopla_log('debug', '  ... at ', sample)
    ad <- hopla_with_debug_warnings(
      data.table::tstrsplit(allele_depths[,sample], ',', fixed = T, type.convert = as.numeric, keep = 1:2)
    )
    total_ad <- ad[[1]] + ad[[2]]
    vcf_b <- data.frame(
      GT = genotypes[,sample],
      AD = total_ad,
      DP = depths[,sample],
      stringsAsFactors = F
    )

    vcf_b$GT[vcf_b$GT == '0' & vcf_a$CHROM == 'chrX'] <- '0/0'
    vcf_b$GT[vcf_b$GT == '1' & vcf_a$CHROM == 'chrX'] <- '1/1'
    vcf_b$GT <- gsub('|', '/', vcf_b$GT, fixed = T)
    vcf_b$DP[is.na(vcf_b$DP)] <- 0
    vcf_b$AF <- suppressWarnings(round(ad[[2]] / total_ad, 3))

    sample_vcf <- cbind(vcf_a, vcf_b)
    sample_vcf$pos_out <- pos_out
    vcfs[[sample]] <- sample_vcf
  }
  return(vcfs)
}

# -----
# Gender prediction
# -----

#' Predict missing sample genders from chromosome depth.
#' @param genders A character vector containing M, F, or NA.
#' @return A completed character vector.
predict_genders <- function(genders){
  hopla_log('info', 'Predicting genders ...')

  x_pos_mask <- which(vcfs[[1]]$CHROM %in% 'chrX')
  x_copies <- sapply(args$samples_no_u, function(s) mean(vcfs[[s]]$DP[x_pos_mask]) /
                       mean(vcfs[[s]]$DP[vcfs[[1]]$CHROM %in% chrs[-23]])) * 2

  x_model <- ifelse(x_copies < args$x_cutoff, 'M', 'F')

  y_pos_mask <- which(vcfs[[1]]$CHROM %in% 'chrY' &
                        ((vcfs[[1]]$POS > 11700001 & vcfs[[1]]$POS < 21800000)))
  y_copies <- sapply(args$samples_no_u, function(s) mean(vcfs[[s]]$DP[y_pos_mask]) /
                       mean(vcfs[[s]]$DP[vcfs[[1]]$CHROM %in% chrs[-23]])) * 2

  y_model <- ifelse(y_copies < args$y_cutoff, 'F', 'M')

  for (s in args$sample_ids[is.na(genders)]){
    if (s %in% args$mother_ids){
      hopla_log('debug', '  ... ', s, ' is included in mother_ids, setting gender: F')
      genders[args$sample_ids == s] = 'F'
      next
    }
    if (s %in% args$father_ids){
      hopla_log('debug', '  ... ', s, ' is included in father_ids, setting gender: M')
      genders[args$sample_ids == s] = 'M'
      next
    }
    if (s %in% args$samples_u){
      hopla_fail('gender of ', s, ' cannot be derived (no data), please provide manually using genders.')
    }
    x_gender = x_model[args$samples_no_u == s]
    y_gender = y_model[args$samples_no_u == s]
    if (!is.na(y_gender) & !is.na(x_gender)){
      if (x_gender == y_gender){
        hopla_log('debug', '  ... predicted gender of ', s, ': ', x_gender)
        genders[args$sample_ids == s] <- x_gender
      } else {
        hopla_log('warn', 'X & Y model do not correspond in ', s, ', it is advised to provide this gender manually using genders')
        hopla_log('debug', '  ... defaulting to Y model: ', y_gender)
        genders[args$sample_ids == s] <- y_gender
      }
    }
    if (is.na(y_gender) & !is.na(x_gender)){
      hopla_log('warn', 'for ', s, ', there is not enough data to predict gender based on the Y model.')
      hopla_log('debug', '  ... defaulting to X model: ', x_gender)
      genders[args$sample_ids == s] <- x_gender
    }
    if (!is.na(y_gender) & is.na(x_gender)){
      hopla_log('warn', 'for ', s, ', there is not enough data to predict gender based on the X model.')
      hopla_log('debug', '  ... defaulting to Y model: ', y_gender)
      genders[args$sample_ids == s] <- y_gender
    }
    if (is.na(y_gender) & is.na(x_gender)){
      hopla_fail('gender of ', s, ' cannot be derived (not enough data at sex chromosomes), please provide manually using genders.')
    }
  }
  hopla_log('debug', '  ... values of X model (~ X copies):')
  hopla_log('debug', '         ', paste0(names(x_copies), '=', paste0(round(x_copies, 2)), collapse = '; '))
  hopla_log('debug', '  ... values of Y model (~ Y copies):')
  hopla_log('debug', '         ', paste0(names(y_copies), '=', paste0(round(y_copies, 2)), collapse = '; '))
  return(genders)
}

# -----
# Add ghost parents (if necessary), requires non-NA genders
# -----

#' Add identifiers for missing pedigree parents.
#' @param args A validated argument list.
#' @return An updated argument list.
add_ghosts <- function(args){
  u = 0
  if (length(args$samples_u)) u = max(as.numeric(substr(args$samples_u, 2, 999)))
  for (s in args$sample_ids[is.na(args$father_ids) + is.na(args$mother_ids) == 1]){
    i = which(args$sample_ids == s)
    u = u + 1
    new_s = paste0('U', u)
    if (is.na(args$mother_ids[i])){
      args$mother_ids[i] <- new_s
      args$genders <- c(args$genders, 'F')
    }
    if (is.na(args$father_ids[i])){
      args$father_ids[i] <- new_s
      args$genders <- c(args$genders, 'M')
    }
    args$mother_ids <- c(args$mother_ids, NA)
    args$father_ids <- c(args$father_ids, NA)
    args$sample_ids <- c(args$sample_ids, new_s)
    args$samples_out <- c(args$samples_out, new_s)
    args$samples_u <- c(args$samples_u, new_s)
  }
  return(args)
}

# -----
# Filtering
# -----

#' Apply depth and allele-fraction filters.
#' @param vcf_list A named list of sample data frames.
#' @return A filtered list of sample data frames.
apply_filter1 <- function(vcf_list){
  hopla_log('info', 'Applying filter 1 ...')

  ## hard filters
  ### AF
  if (!length(args$af_hard_limit_ids)){
    keep_these_1 <- rep(T, nrow(vcf_list[[1]]))
  } else {
    af_filter_matrix <- sapply(vcf_list[args$af_hard_limit_ids], function(x) x$AF >= args$af_hard_limit)
    keep_these_1 <- rowSums(af_filter_matrix, na.rm = T) > 0
  }
  ### DP
  if (!length(args$dp_hard_limit_ids)){
    keep_these_2 <- rep(T, nrow(vcf_list[[1]]))
  } else {
    dp_filter_matrix <- sapply(vcf_list[args$dp_hard_limit_ids], function(x) x$DP >= args$dp_hard_limit)
    keep_these_2 <- rowSums(dp_filter_matrix, na.rm = T) == length(args$dp_hard_limit_ids)
  }

  hard_mask <- keep_these_1 & keep_these_2
  if (!any(hard_mask)){
    hopla_fail('No variants remain after applying filter 1.')
  }

  for (sample in args$samples_no_u){
    x <- vcf_list[[sample]][which(hard_mask),]
    if (sample %in% args$dp_soft_limit_ids){
      soft_mask <- x$DP >= args$dp_soft_limit
      if (!all(soft_mask)){
        x$GT[!soft_mask] <- './.'
        for (n in c('AF', 'DP')) x[[n]][!soft_mask] <- NA
      }
    }

    hom_ref <- which(x$GT == '0/0')
    het_alt <- which(x$GT == '0/1')
    hom_alt <- which(x$GT == '1/1')

    x$GENO <- 'N/N'
    x$GENO[hom_ref] <- paste0(x$REF, '/', x$REF)[hom_ref]
    x$GENO[het_alt] <- paste0(x$REF, '/', x$ALT)[het_alt]
    x$GENO[hom_alt] <- paste0(x$ALT, '/', x$ALT)[hom_alt]

    if (all(x$GENO == 'N/N')){
      hopla_fail('No variants remain for sample ', sample ,' after applying filter 1.')
    }

    vcf_list[[sample]] <- x
  }
  return(vcf_list)
}

#' Apply informative and heterozygous variant filters.
#' @param vcf_list A named list of sample data frames.
#' @return A filtered list of sample data frames.
apply_filter2 <- function(vcf_list){
  hopla_log('info', 'Applying filter 2 ...')

  new_mask <- rep(T, nrow(vcf_list[[1]]))
  if (length(args$keep_informative_ids) == 2){
    informative_mask <- rep(F, length(new_mask))
    for (sample in args$keep_informative_ids){
      other = args$keep_informative_ids[args$keep_informative_ids != sample]
      informative_mask[which(vcf_list[[sample]]$GT == '0/1' & vcf_list[[other]]$GT %in% c('0/0', '1/1'))] <- T
    }
    if (all(args$genders[args$sample_ids %in% args$keep_informative_ids] == 'M')){
      hopla_log('warn', 'parameter keep_informative_ids contains male samples only, will only apply to autosomes.')
      informative_mask[vcf_list[[1]]$CHROM == chrs[23]] = T
    }
    new_mask <- new_mask & informative_mask
  }

  if (length(args$keep_hetero_ids)){
    hetero_mask <- rep(F, length(new_mask))
    for (sample in args$keep_hetero_ids){
      hetero_mask[which(vcf_list[[sample]]$GT == '0/1' | vcf_list[[sample]]$CHROM %in% c('X', 'chrX'))] <- T
    }
    new_mask <- new_mask & hetero_mask
  }

  if (!all(chrs %in% unique(vcf_list[[1]]$CHROM[new_mask]))){
    hopla_fail('No variants remain in at least one of the chromosomes after applying filter 2.')
  }

  for (sample in args$samples_no_u){
    vcf_list[[sample]] <- vcf_list[[sample]][new_mask,]
  }

  ## set remaining non-hetero to missing data

  if (length(args$keep_hetero_ids)){
    for (sample in args$keep_hetero_ids){
      is <- which(vcf_list[[sample]]$GT %in% c('0/0', '1/1') & vcf_list[[sample]]$CHROM %in% chrs[1:22])
      if (length(is) > 0){
        vcf_list[[sample]]$GENO[is] <- 'N/N'
        vcf_list[[sample]]$GT[is] <- './.'
        for (n in c('AF', 'DP')) vcf_list[[sample]][[n]][is] <- NA
      }
    }
  }

  return(vcf_list)
}
