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

  hopla_log('info', 'Running Merlin --error ...')
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

  hopla_log('info', 'Parsing & removing unlikely variants ...')

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


  hopla_log('info', 'Running Merlin --', args$merlin_model,' ...')

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

  hopla_log('info', 'Loading & parsing Merlin output ...')

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

  parse_chromosome_tables <- function(file, chrs, o){
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

  parsed_geno <- parse_chromosome_tables(paste0(args$merlin_dir, 'merlin.chr'), chrs[1:22], table_order)
  parsed_flow <- parse_chromosome_tables(paste0(args$merlin_dir, 'merlin.flow'), chrs[1:22], table_order)
  parsed_geno_x <- parse_chromosome_tables(paste0(args$merlin_dir, 'merlinX.chr'), chrs[23], table_order_x)
  parsed_flow_x <- parse_chromosome_tables(paste0(args$merlin_dir, 'merlinX.flow'), chrs[23], table_order_x)

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
    hopla_log('info', 'Correcting haplotypes, working ...')
    for (chr in chrs[1:22]){
      hopla_log('debug', '  ... at ', chr)
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
    if (args$window_size_voting == 0 & args$min_seg_var == 0) hopla_log('info', 'Correcting haplotypes, working ...')
    chr = chrs[23]
    hopla_log('debug', '  ... at ', chr)
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
