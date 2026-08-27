#!/usr/bin/env Rscript

version <- 'v2.0.0'
minimum_r_version <- '4.4.0'

script_arg <- grep('^--file=', commandArgs(trailingOnly = FALSE), value = TRUE)
script_file <- if (length(script_arg)) sub('^--file=', '', script_arg[1]) else 'exec/hopla-run.R'
hopla_log_source <- file.path(dirname(normalizePath(script_file, mustWork = FALSE)), '..', 'R', 'log.R')
if (file.exists(hopla_log_source)) {
  source(hopla_log_source)
} else {
  hopla_namespace <- tryCatch(asNamespace('hopla'), error = function(error) NULL)
  if (is.null(hopla_namespace)){
    cat('ERROR: Could not load the Hopla logging helpers.\n', file = stderr())
    quit(status = 1)
  }
  for (helper in c('hopla_log', 'hopla_fail', 'hopla_log_level', 'hopla_init_log_level', 'hopla_with_debug_warnings')){
    assign(helper, get(helper, envir = hopla_namespace))
  }
}
hopla_init_log_level()

engine_dir <- dirname(normalizePath(script_file, mustWork = FALSE))
engine_module_dir <- file.path(engine_dir, 'lib')
engine_modules <- file.path(
  engine_module_dir,
  c(
    '00-input.R',
    '10-merlin.R',
    '20-plot-helpers.R',
    '30-haplotype-plots.R',
    '40-analysis-plots.R',
    '50-report.R'
  )
)
missing_modules <- engine_modules[!file.exists(engine_modules)]
if (length(missing_modules)){
  hopla_fail('Could not load Hopla engine module(s): ', paste(basename(missing_modules), collapse = ', '))
}
for (module in engine_modules) sys.source(module, envir = globalenv())
rm(engine_module_dir, engine_modules, missing_modules, module)


# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                               Main code
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Parameters
# -----

args <- list(
  ## mandatory arguments
  sample_ids=c(),

  ## command-line paths
  vcf_file=c(),
  cytoband_file=c(),

  ## important optional arguments
  father_ids=c(),
  mother_ids=c(),
  genders=c(),
  run_merlin=T,

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
  out_dir=c(),
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
  hopla_fail('Hopla requires R >= ', minimum_r_version, '; found ', getRversion(), '.', status = 2)
}

if (!length(cmd_args) %in% 3:4){
  hopla_fail('Provide a settings file, VCF path, output directory, and optional cytoband file. Run -h for usage.',
             status = 2)
}

script_arg <- grep('^--file=', commandArgs(trailingOnly = F), value = T)
script_file <- if (length(script_arg)) sub('^--file=', '', script_arg[1]) else 'exec/hopla-run.R'
schema_candidates <- c(
  file.path(dirname(normalizePath(script_file)), '..', 'schema', 'hopla.schema.json'),
  file.path(dirname(normalizePath(script_file)), '..', 'inst', 'schema', 'hopla.schema.json')
)
schema_file <- schema_candidates[file.exists(schema_candidates)][1]
args <- get_settings_args(cmd_args[1], args, schema_file)
args$vcf_file <- cmd_args[2]
args$out_dir <- cmd_args[3]
args$cytoband_file <- if (length(cmd_args) == 4 && nzchar(cmd_args[4])) cmd_args[4] else c()
if (!file.exists(args$vcf_file) || dir.exists(args$vcf_file)){
  hopla_fail('VCF file does not exist: ', args$vcf_file)
}
if (!dir.exists(args$out_dir)){
  hopla_fail('Output directory does not exist: ', args$out_dir)
}
if (length(args$cytoband_file) && !file.exists(args$cytoband_file)){
  hopla_fail('Cytoband file does not exist: ', args$cytoband_file)
}
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

# Resolved by the browser, so the report stays self-contained without web fonts.
report_font <- 'system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif'

# -----
# Initialize
# -----

args$out_dir <- normalizePath(args$out_dir)

args$fam_id <- gsub("[[:punct:]]", ".", args$fam_id)
args$out_bs <- paste0(args$out_dir, '/', args$fam_id, '-')
args$merlin_dir <- paste0(args$out_bs, 'merlin/')
if (!length(args$cytoband_file) || !nzchar(args$cytoband_file[1])) {
  args$cytoband_file <- fetch_hg38_cytoband_file()
}
cytobands <- get_cytobands(args$cytoband_file)

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

hopla_log('info', 'Saving to HTML ...')
save_html(html_list, file = paste0(args$out_bs, 'output.html'), libdir = paste0(args$out_bs, 'output_files'))
rm(html_list)
invisible(gc())
if (args$self_contained) transform_to_selfcontained()

# -----
# tmp (for validation purposes)
# -----

if (args$run_merlin){
  hopla_log('info', 'Saving Merlin output to tables ...')
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
