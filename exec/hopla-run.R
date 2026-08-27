#!/usr/bin/env Rscript

version <- 'v2.0.0'
minimum_r_version <- '4.4.0'

# Structure:
## - Functions for ...
### -> parameter & vcf loading and parsing
### -> running Merlin & correcting Merlin haplotypes
### -> running specific analyses & creating visualizations
### -> writing to HTML output
## - Main code










# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                  Functions: parameter & vcf loading and parsing
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Parameter parsing
# -----

#' Trim leading and trailing whitespace.
#' @param x A character vector.
#' @return A character vector.
trim <- function (x) gsub("^\\s+|\\s+$", "", x)

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
  cat('Usage: hopla SETTINGS.{yaml,yml,json}\n\n')
  cat('The settings file is validated against hopla.schema.json before analysis.\n')
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
    cat(paste0('ERROR: Settings file does not exist: ', settings_file, '\n'), file = stderr())
    quit(status=2)
  }
  if (!file.exists(schema_file)){
    cat(paste0('ERROR: Settings schema does not exist: ', schema_file, '\n'), file = stderr())
    quit(status=2)
  }

  extension <- tolower(tools::file_ext(settings_file))
  if (!(extension %in% c('yaml', 'yml', 'json'))){
    cat('ERROR: Settings file must use a .yaml, .yml, or .json extension.\n', file = stderr())
    quit(status=2)
  }

  if (extension == 'json'){
    json <- paste(readLines(settings_file, warn = F), collapse = '\n')
  } else {
    yaml_settings <- yaml::read_yaml(settings_file)
    if (!is.list(yaml_settings) || is.null(names(yaml_settings))){
      cat('ERROR: YAML settings must contain a mapping at the document root.\n', file = stderr())
      quit(status=2)
    }
    for (arg in intersect(names(yaml_settings), array_args)){
      if (!is.list(yaml_settings[[arg]])) yaml_settings[[arg]] <- as.list(yaml_settings[[arg]])
    }
    json <- jsonlite::toJSON(yaml_settings, auto_unbox = T, null = 'null', na = 'null')
  }

  valid <- jsonvalidate::json_validate(json, schema_file, verbose = T)
  if (!isTRUE(valid)){
    cat('ERROR: Settings validation failed:\n', file = stderr())
    errors <- attr(valid, 'errors')
    cat(paste(capture.output(print(errors)), collapse = '\n'), '\n', file = stderr())
    quit(status=2)
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
  
  man_args <- c('vcf_file', 'sample_ids')
  for (arg in names(args)){
    if (!length(args[[arg]]) & arg %in% man_args){
      cat(paste0('ERROR: Argument --', arg, ' is mandatory. Please provide.\n'))
      quit(status=1)
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
      cat(paste0('ERROR: Value from setting ', arg, ', \'', not_in(args[[arg]], args$sample_ids),
                 '\' could not be found in sample_ids. Please correct.\n'))
      quit(status=1)
    }
  }
  
  cat('Selected parameters ...\n')
  for (arg in names(args)[!(names(args) %in% c('samples_u', 'samples_no_u'))]){
    if (!length(args[[arg]])) next
    cat(paste0('  ... ', arg, ': ', paste(args[[arg]], collapse = ','), '\n'))
    
    if (any(is.na(args[[arg]])) & !(arg %in% c('father_ids', 'mother_ids', 'genders'))){
      cat(paste0('ERROR: No \'NA\' allowed in argument --', arg,'. Please correct.\n'))
      quit(status=1)
    }
    
    if (arg == 'sample_ids'){
      if (length(args$sample_ids) > 1){
        if (!length(which(!is.na(args$mother_ids))) & !length(which(!is.na(args$father_ids)))){
          cat('ERROR: More than one sample is given in sample_ids. Provide their relation using ',
              'father_ids and/or mother_ids. Otherwise, run separately.\n')
          quit(status=1)
        }
      }
    }
    
    if (arg == 'genders'){
      if (!all(args$genders %in% c('M', 'F', NA))){
        cat("ERROR: Setting 'genders' should be coded as 'M', 'F' or 'NA'. Please correct.\n")
        quit(status=1)
      }
    }
    
    for (same_length_arg in c('father_ids', 'mother_ids', 'genders')){
      if (arg == same_length_arg){
        if (!(length(args$sample_ids) == length(args[[same_length_arg]]))){
          cat(paste0('ERROR: Settings sample_ids and ', same_length_arg,' should be of the same length. Please correct.\n'))
          quit(status=1)
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
        cat(paste0('ERROR: \'U\' IDs not allowed in --', arg, '. Please correct.\n'))
        quit(status=1)
      }
    }
    
    if (arg == 'run_merlin' & args$run_merlin){
      if (length(args$sample_ids) == 1){
        cat(paste0('WARNING: Only one sample provided. Setting run_merlin FALSE.\n'))
        args$run_merlin = F
      }
      if ((Sys.which('merlin') == '' | Sys.which('minx') == '') & args$run_merlin){
        cat(paste0('WARNING: Merlin executables folder could not be located in $PATH. Setting run_merlin FALSE.\n'))
        args$run_merlin = F
      }
    }
    
    if (arg == 'keep_informative_ids'){
      if (!(length(args[[arg]]) %in% c(0,2))){
        cat(paste0('ERROR: No or two samples should be given at keep_informative_ids. Please correct.\n'))
        quit(status=1)
      }
    }
    
    if (arg == 'merlin_model'){
      if (!(args$merlin_model %in% c('sample', 'best'))){
        cat('ERROR: Argument merlin_model should be coded as \'sample\' or \'best\'. Please correct.\n')
        quit(status=1)
      }
    }
    
    if (arg == 'vcf_file'){
      if (!file.exists(args$vcf_file)){
        cat('ERROR: The file given by vcf_file does not exist. Please correct.\n')
        quit(status=1)
      }
    }
    if (arg == 'cytoband_file'){
      if (length(args$cytoband_file) & !file.exists(args$cytoband_file)){
        cat('ERROR: The file given by cytoband_file does not exist. Please correct.\n')
        quit(status=1)
      }
    }
    if (arg == 'value_of_p'){
      if (args$value_of_p <= 0 | args$value_of_p > 1){
        cat('ERROR: value_of_p should be within ]0, 1]. Please correct.\n')
        quit(status=1)
      }
    }
    if (arg == 'af_hard_limit'){
      if (args$af_hard_limit < 0 | args$af_hard_limit >= 1){
        cat('ERROR: af_hard_limit should be within [0, 1[. Please correct.\n')
        quit(status=1)
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

#' Load chromosome cytobands.
#' @param file Path to a tab-separated cytoband file.
#' @return A named list of cytoband records.
get_cytobands <- function(file){
  cytobands <- list()
  chrs_to_index <- sapply(chrs, function(x) which(chrs == x))
  cat('Loading and parsing cytoband file ...\n')
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
  cat('Loading vcf.gz ...\n')
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
  cat('  ... available samples in vcf_file: ', paste0(available_samples, collapse = ','), '\n')
  missing_samples <- args$samples_no_u[!(args$samples_no_u %in% available_samples)]
  if (length(missing_samples)){
    cat(paste0('ERROR: Sample(s) not found in vcf_file: ', paste(missing_samples, collapse = ', '), '.\n'))
    quit(status=1)
  }

  vcf_a <- vcf_a[snp_mask,]
  genotypes <- extract.gt(vcf, element = 'GT', convertNA = F)[snp_mask, args$samples_no_u, drop = F]
  allele_depths <- extract.gt(vcf, element = 'AD', convertNA = F)[snp_mask, args$samples_no_u, drop = F]
  depths <- extract.gt(vcf, element = 'DP', as.numeric = T)[snp_mask, args$samples_no_u, drop = F]
  rm(vcf)
  invisible(gc())

  vcfs <- list()
  pos_out <- scales::comma(vcf_a$POS, accuracy = 1)
  cat('Parsing variants, working ...\n')

  for (sample in args$samples_no_u){
    cat(paste0('  ... at ', sample, '\n'))
    ad <- data.table::tstrsplit(allele_depths[,sample], ',', fixed = T, type.convert = as.numeric, keep = 1:2)
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
  cat('Predicting genders ...\n')
  
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
      cat(paste0('  ... ', s, ' is included in mother_ids, setting gender: F\n'))
      genders[args$sample_ids == s] = 'F'
      next
    }
    if (s %in% args$father_ids){
      cat(paste0('  ... ', s, ' is included in father_ids, setting gender: M\n'))
      genders[args$sample_ids == s] = 'M'
      next
    }
    if (s %in% args$samples_u){
      cat(paste0('ERROR: gender of ', s, ' cannot be derived (no data), please provide manually using --genders.\n'))
      quit(status=1)
    }
    x_gender = x_model[args$samples_no_u == s]
    y_gender = y_model[args$samples_no_u == s]
    if (!is.na(y_gender) & !is.na(x_gender)){
      if (x_gender == y_gender){
        cat(paste0('  ... predicted gender of ', s, ': ', x_gender, '\n'))
        genders[args$sample_ids == s] <- x_gender
      } else {
        cat(paste0('WARNING: X & Y model do not correspond in ', s, ', it is advised to provide this gender manually using --genders\n'))
        cat(paste0('  ... defaulting to Y model: ', y_gender, '\n'))
        genders[args$sample_ids == s] <- y_gender
      }
    }
    if (is.na(y_gender) & !is.na(x_gender)){
      cat(paste0('WARNING: for ', s, ', there is not enough data to predict gender based on the Y model.\n'))
      cat(paste0('  ... defaulting to X model: ', x_gender, '\n'))
      genders[args$sample_ids == s] <- x_gender
    }
    if (!is.na(y_gender) & is.na(x_gender)){
      cat(paste0('WARNING: for ', s, ', there is not enough data to predict gender based on the X model.\n'))
      cat(paste0('  ... defaulting to Y model: ', y_gender, '\n'))
      genders[args$sample_ids == s] <- y_gender
    }
    if (is.na(y_gender) & is.na(x_gender)){
      cat(paste0('ERROR: gender of ', s, ' cannot be derived (not enough data at sex chromosomes), please provide manually using --genders.\n'))
      quit(status=1)
    }
  }
  cat(paste0('  ... values of X model (~ X copies):\n'))
  cat(paste0('         ',paste0(names(x_copies), '=', paste0(round(x_copies, 2)), collapse = '; '), '\n'))
  cat(paste0('  ... values of Y model (~ Y copies):\n'))
  cat(paste0('         ',paste0(names(y_copies), '=', paste0(round(y_copies, 2)), collapse = '; '), '\n'))
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
  cat('Applying filter 1 ...\n')
  
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
    cat('ERROR: No variants remain after applying filter 1.\n')
    quit(status=1)
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
      cat(paste0('ERROR: No variants remain for sample ', sample ,' after applying filter 1.\n'))
      quit(status=1)
    }
    
    vcf_list[[sample]] <- x
  }
  return(vcf_list)
}

#' Apply informative and heterozygous variant filters.
#' @param vcf_list A named list of sample data frames.
#' @return A filtered list of sample data frames.
apply_filter2 <- function(vcf_list){
  cat('Applying filter 2 ...\n')
  
  new_mask <- rep(T, nrow(vcf_list[[1]]))
  if (length(args$keep_informative_ids) == 2){
    informative_mask <- rep(F, length(new_mask))
    for (sample in args$keep_informative_ids){
      other = args$keep_informative_ids[args$keep_informative_ids != sample]
      informative_mask[which(vcf_list[[sample]]$GT == '0/1' & vcf_list[[other]]$GT %in% c('0/0', '1/1'))] <- T
    }
    if (all(args$genders[args$sample_ids %in% args$keep_informative_ids] == 'M')){
      cat(paste0('WARNING: parameter keep_informative_ids contains male samples only, will only apply to autosomes.\n'))
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
    cat('ERROR: No variants remain in at least one of the chromosomes after applying filter 2.\n')
    quit(status=1)
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












# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                               Functions: running Merlin & correcting Merlin haplotypes
# ---------------------------------------------------------------------------------------------------------------------------------------------------

#' Run Merlin error detection and haplotyping.
#' @param args A validated argument list.
#' @param vcfs_filtered2 A named list of filtered sample data frames.
#' @return A chromosome-indexed list of marker maps.
run_merlin <- function(args, vcfs_filtered2){
  ## prepare run 1
  
  ped_1 <- cbind(rep(1, length(args$sample_ids)), args$sample_ids, args$father_ids, args$mother_ids, args$genders)
  ped_1[is.na(ped_1)] <- '0' ; ped_1[,5][ped_1[,5] == 'M'] <- '1' ; ped_1[,5][ped_1[,5] == 'F'] <- '2'
  
  ped_2 <- matrix(ncol = nrow(vcfs_filtered2[[1]]), nrow = nrow(ped_1))
  for (s in args$sample_ids){
    if (s %in% args$samples_u){
      ped_2[which(args$sample_ids == s),] <- rep('N/N', ncol(ped_2))
    } else {
      ped_2[which(args$sample_ids == s),] <- vcfs_filtered2[[s]]$GENO
    }
  }
  
  dat <- cbind('M', vcfs_filtered2[[1]]$ID)
  map <- cbind(substr(vcfs_filtered2[[1]]$CHROM, 4, 10), vcfs_filtered2[[1]]$ID)
  map <- cbind(map, vcfs_filtered2[[1]]$POS / 1000000)
  autosome_m <- map[,1] %in% as.character(1:22)
  
  dir.create(args$merlin_dir, showWarnings = F, recursive = T)
  
  suppressMessages(fwrite(cbind(ped_1, ped_2[,autosome_m]), paste0(args$merlin_dir, 'merlin.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[autosome_m,], paste0(args$merlin_dir, 'merlin.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[autosome_m,], paste0(args$merlin_dir, 'merlin.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  suppressMessages(fwrite(cbind(ped_1, ped_2[,!autosome_m]), paste0(args$merlin_dir, 'merlinX.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[!autosome_m,], paste0(args$merlin_dir, 'merlinX.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[!autosome_m,], paste0(args$merlin_dir, 'merlinX.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  
  ## execute 1
  
  cat('Running Merlin --error ...\n')
  system(paste0('"', as.character(Sys.which("merlin")), '"',
                ' -d "', args$merlin_dir, 'merlin.dat"',
                ' -p "', args$merlin_dir, 'merlin.ped"',
                ' -m "', args$merlin_dir, 'merlin.map"',
                ' --error --prefix "',
                args$merlin_dir, 'merlin" > "', args$merlin_dir, 'merlin.o" && ',
                '"', as.character(Sys.which("minx")), '"',
                ' -d "', args$merlin_dir, 'merlinX.dat"',
                ' -p "', args$merlin_dir, 'merlinX.ped"',
                ' -m "', args$merlin_dir, 'merlinX.map"',
                ' --error --prefix "',
                args$merlin_dir, 'merlinX" > "', args$merlin_dir, 'merlinX.o"'))
  
  ## prepare run 2
  
  cat('Parsing & removing unlikely variants ...\n')
  
  unl_var <- as.character(read.table(paste0(args$merlin_dir, 'merlin.err'), header = T)[,3])
  unl_var_x <- as.character(read.table(paste0(args$merlin_dir, 'merlinX.err'), header = T)[,3])
  
  unl_mask <- !(map[,2] %in% unl_var)
  unl_mask_x <- !(map[,2] %in% unl_var_x)
  
  overall_map <- map[unl_mask & unl_mask_x,]
  map_list <- list()
  for (chr in chrs){
    map_list[[chr]] <- data.frame(overall_map[overall_map[,1] == substr(chr, 4, 10),c(2,3)],
                                  stringsAsFactors = F)
    map_list[[chr]][,2] <- as.numeric(map_list[[chr]][,2]) * 1000000
    colnames(map_list[[chr]]) <- c('id', 'pos')
    map_list[[chr]]$pos_out <- scales::comma(map_list[[chr]]$pos, accuracy = 1)
  }
  
  suppressMessages(fwrite(cbind(ped_1, ped_2[,autosome_m & unl_mask]),
                          paste0(args$merlin_dir, 'merlin.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[autosome_m & unl_mask,], paste0(args$merlin_dir, 'merlin.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[autosome_m & unl_mask,], paste0(args$merlin_dir, 'merlin.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  suppressMessages(fwrite(cbind(ped_1, ped_2[,!autosome_m & unl_mask_x]),
                          paste0(args$merlin_dir, 'merlinX.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[!autosome_m & unl_mask_x,], paste0(args$merlin_dir, 'merlinX.dat'),
              col.names = F, row.names = F, quote = F, sep = '\t')
  write.table(map[!autosome_m & unl_mask_x,], paste0(args$merlin_dir, 'merlinX.map'),
              col.names = F, row.names = F, quote = F, sep = '\t')
  
  ## run 2
  
  
  cat(paste0('Running Merlin --', args$merlin_model,' ...\n'))
  
  system(paste0('"', as.character(Sys.which("merlin")), '"',
                ' -d "', args$merlin_dir, 'merlin.dat"',
                ' -p "', args$merlin_dir, 'merlin.ped"',
                ' -m "', args$merlin_dir, 'merlin.map"',
                ' --', args$merlin_model,' --prefix "',
                args$merlin_dir, 'merlin" > "', args$merlin_dir, 'merlin.o" && ',
                '"', as.character(Sys.which("minx")), '"',
                ' -d "', args$merlin_dir, 'merlinX.dat"',
                ' -p "', args$merlin_dir, 'merlinX.ped"',
                ' -m "', args$merlin_dir, 'merlinX.map"',
                ' --', args$merlin_model,' --prefix "',
                args$merlin_dir, 'merlinX" > "', args$merlin_dir, 'merlinX.o"'))
  
  return(map_list)
}

# -----
# Parse Merlin output
# -----

#' Parse Merlin genotype and flow output.
#' @param args A validated argument list.
#' @return A list containing genotype, flow, and marker-map lists.
parse_merlin <- function(args){
  
  cat('Loading & parsing Merlin output ...\n')
  
  get_table_order <- function(file){
    all_chr <- readLines(file)
    starts <- which(grepl('FAMILY', all_chr))
    ends <- c(starts[-1] - 1, length(all_chr))
    per_chr = all_chr[starts[1]:ends[1]]
    per_chr = per_chr[per_chr != '']
    lines = per_chr[-1]
    
    header = paste0(lines[which(grepl('(', lines, fixed = T))], collapse = '')
    header = gsub("\\s*\\([^\\)]+\\)", "", header)
    header = strsplit(header, ' ')[[1]]
    header = header[header != '']
    return(match(args$sample_ids, header))
  }
  
  zip_lists <- function(x, y){
    lapply(1:min(length(x), length(y)), function(i) c(x[[i]], y[[i]]))
  }
  
  lines_to_frame <- function(lines){
    starts_i <- which(grepl('(', lines, fixed = T)) + 1
    ends_i <- c(starts_i[-1] - 2, length(lines))
    lines <- gsub("?", "NA", lines, fixed = T)
    lines <- gsub(",", "ABBA", lines, fixed = T)
    lines <- gsub("[[:punct:]]", "|", lines)
    lines <- gsub("ABBA", ",", lines)
    lines <- gsub("   |", "|", lines, fixed = T) ; lines <- gsub("  |", "|", lines, fixed = T)
    lines <- gsub(" |", "|", lines, fixed = T)
    lines <- gsub("|   ", "|", lines, fixed = T) ; lines <- gsub("|  ", "|", lines, fixed = T)
    lines <- gsub("| ", "|", lines, fixed = T)
    lines <- gsub("^[ ]+|[ ]+$", "", lines, perl = T)
    lines <- gsub("[ ]+", "-", lines, perl = T)
    lines <- gsub("||", "|", lines, fixed = T)
    
    lines <- strsplit(lines, '-')
    
    final_lines <- lines[starts_i[1]:ends_i[1]]
    if (length(starts_i) > 1){
      for (i in 2:length(starts_i)){
        final_lines <- zip_lists(final_lines, lines[starts_i[i]:ends_i[i]])
      }
    }
    return(matrix(unlist(final_lines), ncol = length(final_lines[[1]]), byrow = TRUE))
  }
  
  parse <- function(file, chrs, o){
    all_chr <- readLines(file)
    starts <- which(grepl('FAMILY', all_chr))
    ends <- c(starts[-1] - 1, length(all_chr))
    parsed <- list()
    for (chr in chrs){
      i = which(chrs == chr)
      per_chr = all_chr[starts[i]:ends[i]]
      per_chr = per_chr[per_chr != '']
      per_chr = per_chr[-1]
      table <- lines_to_frame(per_chr)[,o]
      parsed[[chr]] <- table
    }
    return(parsed)
  }
  
  table_order = get_table_order(paste0(args$merlin_dir, 'merlin.chr'))
  table_order_x = get_table_order(paste0(args$merlin_dir, 'merlinX.chr'))
  
  parsed_geno <- parse(paste0(args$merlin_dir, 'merlin.chr'), chrs[1:22], table_order)
  parsed_flow <- parse(paste0(args$merlin_dir, 'merlin.flow'), chrs[1:22], table_order)
  parsed_geno_x <- parse(paste0(args$merlin_dir, 'merlinX.chr'), chrs[23], table_order_x)
  parsed_flow_x <- parse(paste0(args$merlin_dir, 'merlinX.flow'), chrs[23], table_order_x)
  
  for (i in which(args$genders == 'M')){
    parsed_geno_x$chrX[,i] <- paste0(parsed_geno_x$chrX[,i], 'X')
    parsed_flow_x$chrX[,i] <- paste0(parsed_flow_x$chrX[,i], 'X')
  }
  
  parsed_geno$chrX <- parsed_geno_x$chrX
  parsed_flow$chrX <- parsed_flow_x$chrX
  
  for (chr in chrs){
    bad_inhs <- sapply(1:nrow(parsed_geno[[chr]]), function(i) all(grepl('NA', parsed_geno[[chr]][i,])))
    parsed_geno[[chr]] <- parsed_geno[[chr]][!bad_inhs,]
    parsed_flow[[chr]] <- parsed_flow[[chr]][!bad_inhs,]
    map_list[[chr]] <- map_list[[chr]][!bad_inhs,]
  }
  
  for (chr in chrs){
    parsed_geno[[chr]] <- parsed_geno[[chr]][,which(args$sample_ids %in% args$samples_no_u)]
    parsed_flow[[chr]] <- parsed_flow[[chr]][,which(args$sample_ids %in% args$samples_no_u)]
  }
  
  return(list(parsed_geno = parsed_geno, parsed_flow = parsed_flow, map_list = map_list))
}

# -----
# Don't make N/N inferences, keep actual data
# -----

#' Restore filtered raw genotypes in parsed Merlin output.
#' @param parsed_geno A chromosome-indexed list of genotype matrices.
#' @return An updated genotype list.
update_geno <- function(parsed_geno){
  for (chr in chrs){
    js <- match(map_list[[chr]]$id, vcfs_filtered2[[1]]$ID)
    for (sample in args$samples_no_u){
      i = which(sample == args$samples_no_u)
      x <- vcfs_filtered2[[sample]]$GENO[js]
      if (any(grepl('X', parsed_geno[[chr]][,i]))){
        parsed_geno[[chr]][x == 'N/N', i] <- 'NA|X'
      } else {
        parsed_geno[[chr]][x == 'N/N', i] <- 'NA|NA'
      }
    }
  }
  return(parsed_geno)
}

# -----
# Correct by window voting
# -----

#' Correct short or locally inconsistent haplotype segments.
#' @param args A validated argument list.
#' @param parsed_flow A chromosome-indexed list of flow matrices.
#' @return A list with corrected flow matrices and correction masks.
correct_profiles <- function(args, parsed_flow){
  is_corrected <- list()
  for (chr in chrs){
    is_corrected[[chr]] <- matrix(nrow = nrow(map_list[[chr]]), ncol = length(args$samples_no_u) * 2)
    for (i in 1:length(args$samples_no_u)){
      is_corrected[[chr]][,(i*2)-1] <- F
      is_corrected[[chr]][,i*2] <- F
    }
  }
  
  correct_vector_1 <- function(v, pos, max_distance){
    letters <- unique(v)
    if (length(letters) < 2 || max_distance == 0) return(v)

    left <- 1L
    right <- 0L
    corrected <- character(length(v))
    for (i in seq_along(v)){
      while (left < i && pos[i] - pos[left] > max_distance) left <- left + 1L
      while (right < length(pos) && pos[right + 1L] - pos[i] <= max_distance) right <- right + 1L

      neighbours <- left:right
      weights <- (max_distance * 2) / (abs(pos[neighbours] - pos[i]) + max_distance) - 1
      votes <- vapply(letters, function(letter) sum(weights[v[neighbours] == letter], na.rm = T), numeric(1))
      corrected[i] <- letters[which.max(votes)]
    }
    corrected
  }
  
  correct_vector_2 <- function(flow, geno, min_seg_var){
    breakpoints <- which(c('ZZ', flow) != c(flow, 'ZZ'))
    for (i in 1:(length(breakpoints)-1)){
      sequence <- breakpoints[i]:c(breakpoints[i+1]-1)
      if (length(which(geno[sequence] != 'NA')) > min_seg_var) next
      if (breakpoints[i]-1 != 0){
        letter = flow[breakpoints[i]-1] # previous segment when possible
      } else {
        letter = flow[breakpoints[i+1]] # next segment otherwise
      }
      flow[sequence] <- rep(letter, length(sequence))
    }
    return(flow)
  }
  
  if (args$window_size_voting != 0 | args$min_seg_var != 0){
    cat('Correcting haplotypes, working ...\n')
    for (chr in chrs[1:22]){
      cat(paste0('  ... at ', chr, '\n'))
      pos = map_list[[chr]][,2]
      for (i in 1:length(args$samples_no_u)){
        v = parsed_flow[[chr]][,i]
        strands <- split_strands(v)
        a <- strands[[1]]
        b <- strands[[2]]
        c_a = a
        c_b = b
        if (args$min_seg_var != 0){
          geno_strands <- split_strands(parsed_geno[[chr]][,i])
          c_a <- correct_vector_2(c_a, geno_strands[[1]], args$min_seg_var)
          c_b <- correct_vector_2(c_b, geno_strands[[2]], args$min_seg_var)
        }
        if (args$window_size_voting != 0){
          c_a <- correct_vector_1(c_a, pos, args$window_size_voting / 2)
          c_b <- correct_vector_1(c_b, pos, args$window_size_voting / 2)
        }
        parsed_flow[[chr]][,i] <- paste0(c_a, '|', c_b)
        is_corrected[[chr]][,(i*2)-1] <- a != c_a
        is_corrected[[chr]][,i*2] <- b != c_b
      }
    }
  }
  
  if (args$window_size_voting_x != 0 | args$min_seg_var_x != 0){
    if (args$window_size_voting == 0 & args$min_seg_var == 0) cat('Correcting haplotypes, working ...\n')
    chr = chrs[23]
    cat(paste0('  ... at ', chr, '\n'))
    pos = map_list[[chr]][,2]
    for (i in 1:length(args$samples_no_u)){
      v = parsed_flow[[chr]][,i]
      strands <- split_strands(v)
      a <- strands[[1]]
      b <- strands[[2]]
      c_a = a
      c_b = b
      if (args$min_seg_var_x != 0){
        geno_strands <- split_strands(parsed_geno[[chr]][,i])
        c_a <- correct_vector_2(c_a, geno_strands[[1]], args$min_seg_var_x)
        c_b <- correct_vector_2(c_b, geno_strands[[2]], args$min_seg_var_x)
      }
      if (args$window_size_voting_x != 0){
        c_a <- correct_vector_1(c_a, pos, args$window_size_voting_x / 2)
        c_b <- correct_vector_1(c_b, pos, args$window_size_voting_x / 2)
      }
      parsed_flow[[chr]][,i] <- paste0(c_a, '|', c_b)
      is_corrected[[chr]][,(i*2)-1] <- a != c_a
      is_corrected[[chr]][,i*2] <- b != c_b
    }
  }
  return(list(parsed_flow = parsed_flow, is_corrected = is_corrected))
}













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
  
  add_trace <- function(fig, xs, text, size = 1/2){
    fig <- fig %>% add_trace(x = xs, y = ylim, name = 'region',
                             hoverinfo = "text", line = list(color = colors[length(letters) + 1], width = args$dot_factor * size),
                             text = text, type='scatter', marker = list(color = colors[length(letters) + 1], size = .1),
                             mode='lines+markers', hoverlabel=list(bgcolor=colors[length(letters) + 1]), inherit = F)
    return(fig)
  }
  
  fig <- add_trace(fig, c(chr_cs[c] + s, chr_cs[c] + s), paste0(region_start, ' (region start)'))
  fig <- add_trace(fig, c(chr_cs[c] + e, chr_cs[c] + e), paste0(region_end, ' (region end)'))
  
  if (plot_flanks){
    fig <- add_trace(fig, rep(chr_cs[c] + flank_s, 2), paste0(flank_start, ' (flank start)'), 1/4)
    fig <- add_trace(fig, rep(chr_cs[c] + flank_e, 2), paste0(flank_end, ' (flank end)'), 1/4)
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

# -----
# Merlin
# -----

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
    
    p <- p %>% layout(xaxis = list(title = list(text=c, standoff=10), showticklabels = F,
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
                                                                             trim(gsub(x, '', args$samples_out[args$sample_ids == x]))),
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
  fig <- fig %>% layout(autosize = T)
  return(fig)
}

# -----
# Tables
# -----

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
                                                                      x, trim(gsub(x, '', args$samples_out[args$sample_ids == x])))))), table)
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
  fig <- fig %>% layout(autosize = T)
  
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
  
  var_dis <- var_dis %>% layout(xaxis = list(title = list(text='', standoff = 1), showticklabels = F,
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
  varhists <- list()
  for (s in args$samples_no_u){
    hist <- plot_ly(x = ~vcf_list[[s]]$DP[!is.na(vcf_list[[s]]$DP) & vcf_list[[s]]$DP !=0], type = "histogram", hoverinfo = 'x+y',
                    marker = list(color = colors[1]), height = 200 * ceiling(length(args$samples_no_u) / 4))
    hist <- hist %>% layout(xaxis = list(title = list(text= args$samples_out[args$sample_ids == s] , standoff = 1),
                                         zeroline = F, showgrid = F),
                            yaxis = list(range = 0),
                            showlegend = F, yaxis = list(title = 'density', zeroline = F))
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
                     dat_cn$start[dat_cn$mask], data_type = "logratio", sampleid = "X")
    capture.output(
      segmented_cd_object <- segment(cd_object, verbose=1, weights = dat_cn$weight[dat_cn$mask]),
      file = nullfile()
    )
    
    dat_seg <- segmented_cd_object$output
    dat_seg$loc_end <- dat_seg$loc_end + args$window_size - 1
    
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
      st <- dat_seg$loc_start[i] + chr_cs[as.character(dat_seg$chrom[i])]
      e <- dat_seg$loc_end[i] + chr_cs[as.character(dat_seg$chrom[i])]
      h <- dat_seg$seg_mean[i]
      text <- paste0(as.character(dat_seg$chrom[i]), ':', dat_seg$loc_start[i], '-', dat_seg$loc_end[i])
      cn_plot <- cn_plot %>%
        add_trace(x = c(st,e), y = c(h, h), name = text,
                  line = list(color = colors[2], width = args$dot_factor),
                  text = paste0('segment: ', text), type='scatter', hoverinfo = 'y+text',
                  marker = list(color = colors[2], size = .1),
                  mode='lines+markers', inherit = T)
    }
    
    cn_plot <- cn_plot %>% layout(xaxis = list(title = list(text=args$samples_out[args$sample_ids == s],
                                                            standoff = 1),
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
  
  me_plot <- me_plot %>% layout(xaxis = list(title = list(text=args$samples_out[args$sample_ids == child], standoff = 5),
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
      
      baf <- plot_ly(dat, x =~index, y =~AF, text =~id, height = 200 * ceiling(length(args$samples_no_u) / 4),
                     marker = list(color = colors[1], alpha = .5,
                                   size = args$dot_factor * 2, line = list(color = colors[1], alpha = .5)),
                     type = 'scatter', mode = 'markers', hoverinfo = 'y+text')
      
      yaxis = list(title = 'BAF (%)', zeroline = F, range = c(-15,115), fixedrange = T)
      if (which(args$samples_no_u == s) %% 4 != 1) {
        yaxis = list(title = '', showticklabels = F, zeroline = F, range = c(-15,115), fixedrange = T)
      }
      baf <- baf %>% layout(xaxis = list(title = list(text=args$samples_out[args$sample_ids == s], standoff = 1),
                                         showticklabels = F, zeroline = F, showgrid = F),
                            showlegend = F, yaxis = yaxis)
      
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
                   type = 'scattergl', mode = 'markers', hoverinfo = 'y+text', height = 1000 * 1.5)
    
    yaxis = list(title = 'BAF (%)', zeroline = F, range = c(-15,125), fixedrange = T)
    if (which(chrs == chr) %% 4 != 1) {
      yaxis = list(title = '', showticklabels = F, zeroline = F, range = c(-15,125), fixedrange = T)
    }
    baf <- baf %>% layout(xaxis = list(title = list(text=chr, standoff = 1),
                                       showticklabels = F, zeroline = F, showgrid = F),
                          showlegend = F, yaxis = yaxis)
    
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
    
    upd <- upd %>% layout(xaxis = list(title = list(text=chr, standoff = 1),
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
  
  upd <- upd %>% layout(xaxis = list(title = list(text='', standoff = 1),
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















# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                       Functions: writing to HTML output
# ---------------------------------------------------------------------------------------------------------------------------------------------------

#' Assemble the complete interactive report.
#' @return An htmltools tag list containing Plotly htmlwidgets.
get_html_list <- function(){
  cat('Generating visualizations, working ...\n')
  
  html_list <- list()
  append_list <- function(list, x){
    l <- list
    l[[length(l) + 1]] <- x
    return(l)
  }
  
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
    cat('  ... at pedigree \n')
    
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
  
  cat('  ... at total number of variants (raw) \n')
  
  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs)
  
  cat('  ... at number of variants table (raw) \n')
  
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
  
  cat('  ... at variant depth (raw) \n')
  
  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs), n_col = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (raw) \n')
  
  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs))))
  
  ## copy number
  
  cat('  ... at vcf-based copy number (raw) \n')
  
  html_list <- append_list(html_list, tags$h3("Vcf-based copy number (bam-based verification recommended)"))
  html_list <- append_list(html_list, do_subplot(get_cn_fig()))
  
  # filtered 1
  
  html_list <- add_main_header(html_list, "Filter 1: filter 0, --dp_hard_limit, af_hard_limit and --dp_soft_limit")
  
  ## variant statistics
  
  html_list <- append_list(html_list, tags$h3("Variant statistics"))
  
  cat('  ... at total number of variants (filter 1) \n')
  
  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs_filtered)
  
  cat('  ... at number of variants table (filter 1) \n')
  
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
  
  cat('  ... at variant depth (filter 1) \n')
  
  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs_filtered), n_col = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (filter 1) \n')
  
  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs_filtered))))
  
  ## BAF
  
  if (length(args$regions)){
    cat('  ... at B-allele frequency (regions; filter 1) \n')
    html_list <- append_list(html_list, tags$h3("B-allele frequency (BAF), region(s) of interest"))
    regions_baf <- get_region_baf()
    for (region in names(regions_baf)){
      html_list <- append_list(html_list, tags$h4(region))
      html_list <- append_list(html_list, do_subplot(regions_baf[[region]], n_col = 4))
    }
  }
  
  ## BAF detail
  
  if (length(args$baf_ids)){
    cat('  ... at B-allele frequency (genome-wide; filter 1) \n')
    if (args$limit_baf_to_p){
      html_list <- append_list(html_list,
                               tags$h3(paste0("B-allele frequency (BAF), genome-wide, only ", args$value_of_p * 100,"% of data")))
    } else {
      html_list <- append_list(html_list, tags$h3("B-allele frequency (BAF), genome-wide"))
    }
    for (s in args$baf_ids){
      html_list <- append_list(html_list, tags$h4(args$samples_out[args$sample_ids == s]))
      html_list <- append_list(html_list, do_subplot(get_genome_baf(s), n_col = 2, panning = .015, margin = .012))
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
      cat('  ... at mendelian errors (filter 1) \n')
      
      html_list <- append_list(html_list, tags$h3("Mendelian errors"))
      html_list <- append_list(html_list, do_subplot(men_err_plots, n_col = 1))
    }
  }
  
  ## Parent mapping
  
  if (length(args$sample_ids) > 1){
    cat('  ... at parent mapping (filter 1) \n')
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
  
  cat('  ... at total number of variants (filter 2) \n')
  
  html_list <- append_list(html_list, tags$h4("Total number of variants"))
  html_list <- add_tot_number_of_variants(html_list, vcfs_filtered2)
  
  cat('  ... at number of variants table (filter 2) \n')
  
  html_list <- append_list(html_list, tags$h4("Number of variants table"))
  html_list <- append_list(html_list, get_plotly_table(vcfs_filtered2))
  
  ## var depth
  
  cat('  ... at variant depth (filter 2) \n')
  
  html_list <- append_list(html_list, tags$h4("Variant depth"))
  html_list <- append_list(html_list, do_subplot(get_var_depth_hist(vcfs_filtered2), n_col = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (filter 2) \n')
  
  html_list <- append_list(html_list, tags$h4("Number of variants profile"))
  html_list <- append_list(html_list, do_subplot(list(get_var_dis_fig(vcfs_filtered2))))
  
  ## Merlin
  
  if (args$run_merlin){
    
    cat('  ... at Merlin (filter 2) \n')
    
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

#' Inline local report dependencies without Pandoc.
#' @return Invisible `NULL`.
transform_to_selfcontained <- function(){
  cat('Converting to self-contained HTML ...\n')

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

  temporary_file <- paste0(output_file, '.selfcontained')
  writeLines(html, temporary_file, useBytes = T)
  if (!file.rename(temporary_file, output_file)){
    unlink(temporary_file)
    stop('Could not replace HTML with self-contained output.')
  }
  unlink(paste0(args$out_bs, 'output_files'), recursive = T)
}














# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                               Main code
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Parameters
# -----

args <- list(
  ## mandatory arguments
  vcf_file=c(),
  sample_ids=c(),
  
  ## important optional arguments
  father_ids=c(),
  mother_ids=c(),
  genders=c(),
  run_merlin=T,
  cytoband_file=c(),
  
  ## variant inclusion arguments: filter 1
  dp_hard_limit_ids=c(),
  dp_hard_limit=10,
  af_hard_limit_ids=c(),
  af_hard_limit=0,
  dp_soft_limit_ids=c(),
  dp_soft_limit=10,
  
  ## variant inclusion arguments: filter 2
  keep_informative_ids=c(),
  keep_hetero_ids=c(),
  
  ## sample/disease annotation
  regions=c(),
  reference_ids=c(),
  carrier_ids=c(),
  affected_ids=c(),
  nonaffected_ids=c(),
  info=c(),
  
  ## BAF profiles
  baf_ids=c(),
  
  ## merlin profiles
  merlin_model='best',
  min_seg_var=5,
  min_seg_var_x=15,
  window_size_voting=10000000,
  window_size_voting_x=c(),
  keep_chromosomes_only=T,
  keep_regions_only=F,
  concordance_table=T,
  
  ## remaining features
  out_dir=c('./'),
  fam_id='hopla',
  x_cutoff=1.5,
  y_cutoff=.6,
  window_size=1000000,
  regions_flanking_size=2000000,
  limit_baf_to_p=F,
  limit_pm_to_p=F,
  value_of_p=.25,
  color_palette='Paired',
  dot_factor=2,
  self_contained=F,
  cairo=F
)

cmd_args <- commandArgs(trailingOnly=T)
if ('--version' %in% cmd_args | '-V' %in% cmd_args){
  cat(version, '\n')
  quit(status=0)
}

if ('--help' %in% cmd_args | '-h' %in% cmd_args){
  print_help()
  quit(status=0)
}
if (getRversion() < minimum_r_version){
  cat(paste0('ERROR: Hopla requires R >= ', minimum_r_version, '; found ', getRversion(), '.\n'), file = stderr())
  quit(status=2)
}

if (length(cmd_args) != 1){
  cat('ERROR: Provide exactly one YAML or JSON settings file. Run -h for usage.\n', file = stderr())
  quit(status=2)
}

script_arg <- grep('^--file=', commandArgs(trailingOnly = F), value = T)
script_file <- if (length(script_arg)) sub('^--file=', '', script_arg[1]) else 'exec/hopla-run.R'
schema_candidates <- c(
  file.path(dirname(normalizePath(script_file)), '..', 'schema', 'hopla.schema.json'),
  file.path(dirname(normalizePath(script_file)), '..', 'inst', 'schema', 'hopla.schema.json')
)
schema_file <- schema_candidates[file.exists(schema_candidates)][1]
args <- get_settings_args(cmd_args[1], args, schema_file)
args <- post_process_args(args)
rm(cmd_args, schema_candidates, schema_file, script_arg, script_file)

# -----
# Library
# -----

suppressMessages(library('vcfR'))
suppressMessages(library('data.table'))
suppressMessages(library('RColorBrewer'))
suppressMessages(library('kinship2'))
suppressMessages(library('plotly'))
suppressMessages(library('htmltools'))
suppressMessages(library('GenomicRanges'))
suppressMessages(library('DNAcopy'))

# -----
# Overall options & constants
# -----

options(scipen=999)
if (args$cairo) options(bitmaptype='cairo')

colors = brewer.pal(brewer.pal.info[args$color_palette,]$maxcolors, args$color_palette)
chrs <- paste0('chr', c(1:22, 'X'))

# -----
# Initialize
# -----

dir.create(args$out_dir, showWarnings = F, recursive = T)
args$out_dir <- normalizePath(args$out_dir)

args$fam_id <- gsub("[[:punct:]]", ".", args$fam_id)
args$out_bs <- paste0(args$out_dir, '/', args$fam_id, '-')
args$merlin_dir <- paste0(args$out_bs, 'merlin/')
if (length(args$cytoband_file)) cytobands <- get_cytobands(args$cytoband_file)

# -----
# Vcf loading & parsing
# -----

vcfs <- load_samples(args)

if (any(is.na(args$genders))) args$genders <- predict_genders(args$genders)

vcfs <- lapply(vcfs, function(x) x[vcfs[[1]]$CHROM %in% chrs,])
for (s in args$sample_ids[args$genders == 'M']){
  if (s %in% args$samples_u) next
  vcfs[[s]]$GT[which(vcfs[[s]]$CHROM == 'chrX' & vcfs[[s]]$GT == '0/1')] <- './.'
}

args <- add_ghosts(args)

vcfs_filtered <- apply_filter1(vcfs)
vcfs_filtered2 <- apply_filter2(vcfs_filtered)

# -----
# Merlin
# -----

if (args$run_merlin){
  map_list <- run_merlin(args, vcfs_filtered2)

  merlin_out <- parse_merlin(args)
  parsed_geno <- merlin_out$parsed_geno
  parsed_flow <- merlin_out$parsed_flow
  map_list <- merlin_out$map_list
  rm(merlin_out)
  
  parsed_geno <- update_geno(parsed_geno)

  corrected_data <- correct_profiles(args, parsed_flow)
  parsed_flow = corrected_data$parsed_flow
  is_corrected = corrected_data$is_corrected
  rm(corrected_data)
  
  letters <- unique(unlist(strsplit(unique(unlist(parsed_flow)), '')))
  letters <- letters[!(letters %in% c('|', 'X'))]
  letter_colors <- c(colors[1:length(letters)], 'white')
  names(letter_colors) <- c(letters, 'X')
} else{
  letters <- c('A', 'B', 'C', 'D') # no merlin -> four letters (ie, colors) required
}

# -----
# Write output
# -----

html_list <- get_html_list()

cat('Saving to HTML ...\n')
save_html(html_list, file = paste0(args$out_bs, 'output.html'), libdir = paste0(args$out_bs, 'output_files'))
rm(html_list)
invisible(gc())
if (args$self_contained) transform_to_selfcontained()

# -----
# tmp (for validation purposes)
# -----

if (args$run_merlin){
  cat('Saving Merlin output to tables ...\n')
  for (sample in args$samples_no_u){
    i = which(args$samples_no_u == sample)
    geno_values <- unlist(lapply(chrs, function(chr) parsed_geno[[chr]][,i]), use.names = F)
    geno_strands <- split_strands(geno_values)
    geno_table <- cbind(unlist(sapply(chrs, function(chr) rep(chr, nrow(map_list[[chr]])))),
                        unlist(sapply(chrs, function(chr) map_list[[chr]]$pos)),
                        geno_strands[[1]],
                        geno_strands[[2]])
    colnames(geno_table) <- c('chr', 'pos', 'genoA', 'genoB')
    write.table(geno_table, paste0(args$merlin_dir, sample, '-geno.txt'), sep = '\t', row.names = F, quote = F)
    flow_values <- unlist(lapply(chrs, function(chr) parsed_flow[[chr]][,i]), use.names = F)
    flow_strands <- split_strands(flow_values)
    flow_table <- cbind(unlist(sapply(chrs, function(chr) rep(chr, nrow(map_list[[chr]])))),
                        unlist(sapply(chrs, function(chr) map_list[[chr]]$pos)),
                        flow_strands[[1]],
                        as.character(letter_colors[flow_strands[[1]]]),
                        unlist(sapply(chrs, function(chr) is_corrected[[chr]][,(i*2)-1])),
                        
                        flow_strands[[2]],
                        as.character(letter_colors[flow_strands[[2]]]),
                        unlist(sapply(chrs, function(chr) is_corrected[[chr]][,(i*2)])))
    colnames(flow_table) <- c('chr', 'pos', 'flowA', 'flowA.hexcol', 'flowA.iscorrected', 'flowB', 'flowB.hexcol', 'flowB.iscorrected')
    write.table(flow_table, paste0(args$merlin_dir, sample, '-flow.txt'), sep = '\t', row.names = F, quote = F)
  }
}
