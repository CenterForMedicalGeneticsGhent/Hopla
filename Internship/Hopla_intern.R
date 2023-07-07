# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                  Functions: parameter & vcf loading and parsing
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Parameter parsing
# -----

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

format.value <- function(arg, value){
  if (!(arg %in% names(args))){
    cat(paste0('ERROR: Argument --', arg, ' does not exist.\n'))
    quit(status=0)
  }
  
  numeric.args <- c('dp.hard.limit', 'af.hard.limit', 'dp.soft.limit',
                    'min.seg.var', 'min.seg.var.X', 'window.size.voting',
                    'window.size.voting.X', 'X.cutoff', 'Y.cutoff', 'window.size',
                    'regions.flanking.size', 'value.of.P', 'dot.factor')
  boolean.args <- c('run.merlin', 'keep.chromosomes.only', 'keep.regions.only',
                    'concordance.table', 'limit.baf.to.P', 'limit.pm.to.P',
                    'self.contained', 'cairo')
  
  value = sapply(strsplit(value, ',')[[1]], function(x) trim(x))
  
  ## replace NAs
  value[value %in% c('', 'NA')] = NA
  
  ## tranform when needed
  if (arg %in% numeric.args) value = as.numeric(value)
  if (arg %in% boolean.args) value = as.logical(value)
  return(value)
}

get.cmd.args <- function(cmd.args){
  for (i in which(grepl('^--', cmd.args))){
    arg <- gsub('--', '', cmd.args[i])
    value <- format.value(arg, cmd.args[i+1])
    args[[arg]] <- value
  }
  return(args)
}

get.file.args <- function(settings.file){
  if (!file.exists(settings.file)){
    cat('ERROR: File given by --settings does not exist. Please Correct.\n')
    quit(status=0)
  }
  at.info = F
  for (line in suppressWarnings(readLines(settings.file))){
    ## info parsing
    if (!at.info) line = gsub("'", '', gsub('"', '', line))
    if (at.info) line = gsub('\t', '    ', line)
    if (line == 'end.info'){ at.info = F ; next }
    if (at.info){ args$info <- c(args$info, line) ; next }
    if (line == 'start.info'){ at.info = T ; next }
    
    ## skip comments
    if (substr(trim(line), 1, 1) %in% c('#', '')) next
    line <- trim(strsplit(line, '#', fixed = T)[[1]][1])
    
    ## parse argument
    arg <- trim(strsplit(line, '=')[[1]][1])
    value <- strsplit(line, '=')[[1]][2]
    value <- format.value(arg, value)
    
    if (substr(line, nchar(line), nchar(line)) != '=' & 
        grepl('=', line, fixed = T)) args[[arg]] <- value
  }
  return(args)
}

post.process.args <- function(args){
  no.u.mask <- !sapply(args$sample.ids, function(x) toupper(substr(x,1,1)) == 'U' &
                         !is.na(suppressWarnings(as.numeric(substr(x,2,999)))))
  
  if (!length(args$genders)) args$genders = rep(NA, length(args$sample.ids))
  if (!length(args$mother.ids)) args$mother.ids = rep(NA, length(args$sample.ids))
  if (!length(args$father.ids)) args$father.ids = rep(NA, length(args$sample.ids))
  
  args$samples.no.u <- args$sample.ids[no.u.mask]
  args$samples.u <- args$sample.ids[!no.u.mask]
  
  not.last.in.line <- unique(c(args$mother.ids, args$father.ids))
  not.last.in.line <- not.last.in.line[not.last.in.line %in% args$samples.no.u]
  last.in.line <- args$samples.no.u[!args$samples.no.u %in% not.last.in.line]
  
  if (length(args$samples.no.u) == 1){
    not.last.in.line = args$samples.no.u
    last.in.line = args$samples.no.u
  }
  
  if (!length(args$dp.hard.limit.ids)) args$dp.hard.limit.ids = not.last.in.line
  if (!length(args$af.hard.limit.ids)) args$af.hard.limit.ids = not.last.in.line
  if (!length(args$dp.soft.limit.ids)) args$dp.soft.limit.ids = last.in.line
  if (!length(args$window.size.voting.X)) args$window.size.voting.X = args$window.size.voting
  if (!length(args$min.seg.var.X)) args$min.seg.var.X = args$min.seg.var
  
  man.args <- c('vcf.file', 'sample.ids')
  for (arg in names(args)){
    if (!length(args[[arg]]) & arg %in% man.args){
      cat(paste0('ERROR: Argument --', arg, ' is mandatory. Please provide.\n'))
      quit(status=0)
    }
  }
  
  not.in.error <- function(arg){
    not.in <- function(xs, ys){
      for (x in xs){
        if (!(x %in% ys) & !is.na(x)){
          return(x)
        }
      }
      return(NULL)
    }
    if (length(not.in(args[[arg]], args$sample.ids))){
      cat(paste0('ERROR: Fetched from argument --', arg,', \'', not.in(args[[arg]], args$sample.ids),
                 '\' could not be found in the provided --sample.ids. Please correct.\n'))
      quit(status=0)
    }
  }
  
  cat('Selected parameters ...\n')
  for (arg in names(args)[!(names(args) %in% c('samples.u', 'samples.no.u'))]){
    if (!length(args[[arg]])) next
    cat(paste0('  ... ', arg, ': ', paste(args[[arg]], collapse = ','), '\n'))
    
    if (any(is.na(args[[arg]])) & !(arg %in% c('father.ids', 'mother.ids', 'genders'))){
      cat(paste0('ERROR: No \'NA\' allowed in argument --', arg,'. Please correct.\n'))
      quit(status=0)
    }
    
    if (arg == 'sample.ids'){
      if (length(args$sample.ids) > 1){
        if (!length(which(!is.na(args$mother.ids))) & !length(which(!is.na(args$father.ids)))){
          cat('ERROR: More than one sample is given in --sample.ids. Please provide their relation using argument(s)', 
              '--father.ids and/or --mother.ids. Otherwise, run separately.\n')
          quit(status=0)
        }
      }
    }
    
    if (arg == 'genders'){
      if (!all(args$genders %in% c('M', 'F', NA))){
        cat('ERROR: Argument --genders should be coded as \'M\', \'F\' or \'NA\'. Please correct.\n')
        quit(status=0)
      }
    }
    
    for (same.length.arg in c('father.ids', 'mother.ids', 'genders')){
      if (arg == same.length.arg){
        if (!(length(args$sample.ids) == length(args[[same.length.arg]]))){
          cat(paste0('ERROR: Arguments --sample.ids and --', same.length.arg,' should be of the same length. Please correct.\n'))
          quit(status=0)
        }
      }
    }
    
    if (arg %in% c('father.ids', 'mother.ids', 'dp.hard.limit.ids', 'af.hard.limit.ids',
                   'dp.soft.limit.ids', 'keep.informative.ids', 'keep.hetero.ids',
                   'reference.ids', 'carrier.ids', 'affected.ids',
                   'nonaffected.ids', 'baf.ids')){
      not.in.error(arg)
    }
    
    if (arg %in% c('dp.hard.limit.ids', 'af.hard.limit.ids', 'dp.soft.limit.ids',
                   'keep.informative.ids', 'keep.hetero.ids', 'baf.ids')){
      if (length(intersect(args[[arg]], args$samples.u))){
        cat(paste0('ERROR: \'U\' IDs not allowed in --', arg, '. Please correct.\n'))
        quit(status=0)
      }
    }
    
    if (arg == 'run.merlin' & args$run.merlin){
      if (length(args$sample.ids) == 1){
        cat(paste0('WARNING: Only one sample provided. Setting --run.merlin FALSE.\n'))
        args$run.merlin = F
      }
      if ((Sys.which('merlin') == '' | Sys.which('minx') == '') & args$run.merlin){
        cat(paste0('WARNING: Merlin executables folder could not be located in $PATH. Setting --run.merlin FALSE.\n'))
        args$run.merlin = F
      }
    }
    
    if (arg == 'keep.informative.ids'){
      if (!(length(args[[arg]]) %in% c(0,2))){
        cat(paste0('ERROR: No or two samples should be given at --keep.informative.ids. Please correct.\n'))
        quit(status=0)
      }
    }
    
    if (arg == 'merlin.model'){
      if (!(args$merlin.model %in% c('sample', 'best'))){
        cat('ERROR: Argument --merlin.model should be coded as \'sample\' or \'best\'. Please correct.\n')
        quit(status=0)
      }
    }
    
    if (arg == 'vcf.file'){
      if (!file.exists(args$vcf.file)){
        cat('ERROR: the file given by --vcf.file does not exist. Please correct.\n')
        quit(status=0)
      }
    }
    if (arg == 'cytoband.file'){
      if (length(args$cytoband.file) & !file.exists(args$cytoband.file)){
        cat('ERROR: the file given by --vcf.file does not exist. Please correct.\n')
        quit(status=0)
      }
    }
    if (arg == 'value.of.P'){
      if (args$value.of.P <= 0 | args$value.of.P > 1){
        cat('ERROR: --value.of.P should be within ]0, 1]. Please correct.\n')
        quit(status=0)
      }
    }
    if (arg == 'af.hard.limit'){
      if (args$af.hard.limit < 0 | args$af.hard.limit >= 1){
        cat('ERROR: --af.hard.limit should be within [0, 1[. Please correct.\n')
        quit(status=0)
      }
    }
  }
  
  add.annot <- function(letter, annot = NULL){
    if (!is.null(annot)){
      args$samples.out[args$sample.ids %in% args[[annot]]] <- paste0(args$samples.out[args$sample.ids %in% args[[annot]]],
                                                                     ' (', letter, ')')
    } else {
      known.set <- unique(c(args$reference.ids, args$carrier.ids, args$affected.ids, args$nonaffected.ids))
      args$samples.out[!(args$sample.ids %in% known.set)] <- paste0(args$samples.out[!(args$sample.ids %in% known.set)],
                                                                    ' (', letter, ')')
    }
    return(args)
  }
  args$samples.out <- args$sample.ids
  args <- add.annot('R', 'reference.ids')
  args <- add.annot('C', 'carrier.ids')
  args <- add.annot('A', 'affected.ids')
  args <- add.annot('N', 'nonaffected.ids')
  
  return(args)
}

# -----
# Cytobands
# -----

get.cytobands <- function(file){
  cytobands <- list()
  chrs.to.index <- sapply(chrs, function(x) which(chrs == x))
  cat('Loading and parsing cytoband file ...\n')
  cyto <- read.csv(file, sep = '\t', header = F, stringsAsFactors = F)
  if (substr(cyto$V1[1], 1, 3) != 'chr') cyto$V1 <- paste0('chr', cyto$V1)
  cyto$V4[cyto$V4 == ''] <- cyto$V5[cyto$V4 == '']
  cyto$V4[grepl('acen', cyto$V5)] <- paste0(cyto$V4[grepl('acen', cyto$V5)], ' (acen)')
  cyto$V4[grepl('gvar', cyto$V5)] <- paste0(cyto$V4[grepl('gvar', cyto$V5)], ' (gvar)')
  cyto$V4[grepl('stalk', cyto$V5)] <- paste0(cyto$V4[grepl('stalk', cyto$V5)], ' (stalk)')
  cyto <- cyto[cyto$V1 %in% chrs,] ; cyto <- cyto[order(chrs.to.index[cyto$V1], cyto$V2),]
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

load.samples <- function(args){
  cat('Loading vcf.gz ...\n')
  vcf <- read.vcfR(args$vcf.file, verbose = F)
  
  ## vcf.A (annot)
  vcf.A <- as.data.frame(vcf@fix)
  if (substr(vcf.A$CHROM[1], 1, 3) != 'chr') vcf.A$CHROM <- paste0('chr', vcf.A$CHROM)
  vcf.A$ID <- as.character(paste0('id', 1:nrow(vcf.A)))
  
  vcf.A <- vcf.A[,c('CHROM', 'POS', 'ID', 'REF', 'ALT')]
  vcf.A$POS <- as.numeric(as.character(vcf.A$POS))
  for (x in c('CHROM', 'ID', 'REF', 'ALT')) vcf.A[[x]] <- as.character(vcf.A[[x]])
  
  snp.mask <- nchar(vcf.A$REF) == 1 & nchar(vcf.A$ALT) == 1 & vcf.A$CHROM %in% c(chrs, 'chrY')
  
  ## vcf.B (data)
  vcf.B.tmp <- as.data.frame(vcf@gt)
  cnames <- strsplit(as.character(vcf.B.tmp$FORMAT[1]), ':')[[1]]
  vcfs <- list()
  once = T
  cat('  ... available samples in --vcf.file: ', paste0(colnames(vcf.B.tmp)[-1], collapse = ','), '\n')
  cat('Parsing variants, working ...\n')
  
  for (sample in args$samples.no.u){
    if (!(sample %in% colnames(vcf.B.tmp))){
      cat(paste0('ERROR: Fetched from argument --sample.ids, \'',  sample,
                 '\' could not be found in the provided --vcf.file. Please correct.\n'))
      quit(status=0)
    }
    cat(paste0('  ... at ', sample, '\n'))
    vcf.B <- suppressWarnings(as.data.frame(do.call(rbind, strsplit(as.character(vcf.B.tmp[[sample]]), ':')))[,1:length(cnames)])
    colnames(vcf.B) <- cnames
    
    vcf.B <- vcf.B[,c('GT', 'AD', 'DP')]
    vcf.B$DP <- suppressWarnings(as.numeric(as.character(vcf.B$DP)))
    for (x in c('GT', 'AD')) vcf.B[[x]] <- as.character(vcf.B[[x]])
    
    vcf.B$GT[vcf.B$GT == '0' & vcf.A$CHROM == 'chrX'] <- '0/0'
    vcf.B$GT[vcf.B$GT == '1' & vcf.A$CHROM == 'chrX'] <- '1/1'
    vcf.B$GT <- gsub('|', '/', vcf.B$GT, fixed = T)
    vcf.B$DP[is.na(vcf.B$DP)] <- 0
    vcf.B$AF <- suppressWarnings(round(as.numeric(sapply(strsplit(vcf.B$AD, ','), function(x) x[2])) / 
                                         sapply(strsplit(vcf.B$AD, ','), function(x) sum(as.numeric(x))), 3))
    vcf.B$AD <- suppressWarnings(sapply(strsplit(vcf.B$AD, ','), function(x) sum(as.numeric(x))))
    
    vcf <- cbind(vcf.A[which(snp.mask),], vcf.B[which(snp.mask),])
    if (once){
      pos.out <- scales::comma(vcf$POS, accuracy = 1)
      once = F
    }
    vcf$POS.out <- pos.out ; vcfs[[sample]] <- vcf
  }
  return(vcfs)
}

# -----
# Gender prediction
# -----

predict.genders <- function(genders){
  cat('Predicting genders ...\n')
  
  X.pos.mask <- which(vcfs[[1]]$CHROM %in% 'chrX')
  X.copies <- sapply(args$samples.no.u, function(s) mean(vcfs[[s]]$DP[X.pos.mask]) /
                       mean(vcfs[[s]]$DP[vcfs[[1]]$CHROM %in% chrs[-23]])) * 2
  
  X.model <- ifelse(X.copies < args$X.cutoff, 'M', 'F')
  
  Y.pos.mask <- which(vcfs[[1]]$CHROM %in% 'chrY' &
                        ((vcfs[[1]]$POS > 11700001 & vcfs[[1]]$POS < 21800000)))
  Y.copies <- sapply(args$samples.no.u, function(s) mean(vcfs[[s]]$DP[Y.pos.mask]) /
                       mean(vcfs[[s]]$DP[vcfs[[1]]$CHROM %in% chrs[-23]])) * 2
  
  Y.model <- ifelse(Y.copies < args$Y.cutoff, 'F', 'M')
  
  for (s in args$sample.ids[is.na(genders)]){
    if (s %in% args$mother.ids){
      cat(paste0('  ... ', s, ' is included in --mother.ids, setting gender: F\n'))
      genders[args$sample.ids == s] = 'F'
      next
    }
    if (s %in% args$father.ids){
      cat(paste0('  ... ', s, ' is included in --father.ids, setting gender: M\n'))
      genders[args$sample.ids == s] = 'M'
      next
    }
    if (s %in% args$samples.u){
      cat(paste0('ERROR: gender of ', s, ' cannot be derived (no data), please provide manually using --genders.\n'))
      quit(status=0)
    }
    X.gender = X.model[args$samples.no.u == s]
    Y.gender = Y.model[args$samples.no.u == s]
    if (!is.na(Y.gender) & !is.na(X.gender)){
      if (X.gender == Y.gender){
        cat(paste0('  ... predicted gender of ', s, ': ', X.gender, '\n'))
        genders[args$sample.ids == s] <- X.gender
      } else {
        cat(paste0('WARNING: X & Y model do not correspond in ', s, ', it is advised to provide this gender manually using --genders\n'))
        cat(paste0('  ... defaulting to Y model: ', Y.gender, '\n'))
        genders[args$sample.ids == s] <- Y.gender
      }
    }
    if (is.na(Y.gender) & !is.na(X.gender)){
      cat(paste0('WARNING: for ', s, ', there is not enough data to predict gender based on the Y model.\n'))
      cat(paste0('  ... defaulting to X model: ', X.gender, '\n'))
      genders[args$sample.ids == s] <- X.gender
    }
    if (!is.na(Y.gender) & is.na(X.gender)){
      cat(paste0('WARNING: for ', s, ', there is not enough data to predict gender based on the X model.\n'))
      cat(paste0('  ... defaulting to Y model: ', Y.gender, '\n'))
      genders[args$sample.ids == s] <- Y.gender
    }
    if (is.na(Y.gender) & is.na(X.gender)){
      cat(paste0('ERROR: gender of ', s, ' cannot be derived (not enough data at sex chromosomes), please provide manually using --genders.\n'))
      quit(status=0)
    }
  }
  cat(paste0('  ... values of X model (~ X copies):\n'))
  cat(paste0('         ',paste0(names(X.copies), '=', paste0(round(X.copies, 2)), collapse = '; '), '\n'))
  cat(paste0('  ... values of Y model (~ Y copies):\n'))
  cat(paste0('         ',paste0(names(Y.copies), '=', paste0(round(Y.copies, 2)), collapse = '; '), '\n'))
  return(genders)
}

# -----
# Add ghost parents (if necessary), requires non-NA genders
# -----

add.ghosts <- function(args){
  u = 0
  if (length(args$samples.u)) u = max(as.numeric(substr(args$samples.u, 2, 999)))
  for (s in args$sample.ids[is.na(args$father.ids) + is.na(args$mother.ids) == 1]){
    i = which(args$sample.ids == s)
    u = u + 1
    new.s = paste0('U', u)
    if (is.na(args$mother.ids[i])){
      args$mother.ids[i] <- new.s
      args$genders <- c(args$genders, 'F')
    }
    if (is.na(args$father.ids[i])){
      args$father.ids[i] <- new.s
      args$genders <- c(args$genders, 'M')
    }
    args$mother.ids <- c(args$mother.ids, NA)
    args$father.ids <- c(args$father.ids, NA)
    args$sample.ids <- c(args$sample.ids, new.s)
    args$samples.out <- c(args$samples.out, new.s)
    args$samples.u <- c(args$samples.u, new.s)
  }
  return(args)
}

# -----
# Filtering
# -----

apply.filter1 <- function(vcf.list){
  cat('Applying filter 1 ...\n')
  
  ## hard filters
  ### AF
  if (!length(args$af.hard.limit.ids)){
    keep.these.1 <- rep(T, nrow(vcf.list[[1]]))
  } else {
    AF.filter.matrix <- sapply(vcf.list[args$af.hard.limit.ids], function(x) x$AF >= args$af.hard.limit)
    keep.these.1 <- rowSums(AF.filter.matrix, na.rm = T) > 0
  }
  ### DP
  if (!length(args$dp.hard.limit.ids)){
    keep.these.2 <- rep(T, nrow(vcf.list[[1]]))
  } else {
    DP.filter.matrix <- sapply(vcf.list[args$dp.hard.limit.ids], function(x) x$DP >= args$dp.hard.limit)
    keep.these.2 <- rowSums(DP.filter.matrix, na.rm = T) == length(args$dp.hard.limit.ids)
  }
  
  hard.mask <- keep.these.1 & keep.these.2
  if (!any(hard.mask)){
    cat('ERROR: No variants remain after applying filter 1.\n')
    quit(status=0)
  }
  
  for (sample in args$samples.no.u){
    x <- vcf.list[[sample]][which(hard.mask),]
    if (sample %in% args$dp.soft.limit.ids){
      soft.mask <- x$DP >= args$dp.soft.limit
      if (!all(soft.mask)){
        x$GT[!soft.mask] <- './.'
        for (n in c('AF', 'DP')) x[[n]][!soft.mask] <- NA
      }
    }
    
    hom.ref <- which(x$GT == '0/0')
    het.alt <- which(x$GT == '0/1')
    hom.alt <- which(x$GT == '1/1')
    
    x$GENO <- 'N/N'
    x$GENO[hom.ref] <- paste0(x$REF, '/', x$REF)[hom.ref]
    x$GENO[het.alt] <- paste0(x$REF, '/', x$ALT)[het.alt]
    x$GENO[hom.alt] <- paste0(x$ALT, '/', x$ALT)[hom.alt]
    
    if (all(x$GENO == 'N/N')){
      cat(paste0('ERROR: No variants remain for sample ', sample ,' after applying filter 1.\n'))
      quit(status=0)
    }
    
    vcf.list[[sample]] <- x
  }
  return(vcf.list)
}

apply.filter2 <- function(vcf.list){
  cat('Applying filter 2 ...\n')
  
  new.mask <- rep(T, nrow(vcf.list[[1]]))
  if (length(args$keep.informative.ids) == 2){
    informative.mask <- rep(F, length(new.mask))
    for (sample in args$keep.informative.ids){
      other = args$keep.informative.ids[args$keep.informative.ids != sample]
      informative.mask[which(vcf.list[[sample]]$GT == '0/1' & vcf.list[[other]]$GT %in% c('0/0', '1/1'))] <- T
    }
    if (all(args$genders[args$sample.ids %in% args$keep.informative.ids] == 'M')){
      cat(paste0('WARNING: parameter --keep.informative.ids contains male samples only, will only apply to autosomes.\n'))
      informative.mask[vcf.list[[1]]$CHROM == chrs[23]] = T
    }
    new.mask <- new.mask & informative.mask
  }
  
  if (length(args$keep.hetero.ids)){
    hetero.mask <- rep(F, length(new.mask))
    for (sample in args$keep.hetero.ids){
      hetero.mask[which(vcf.list[[sample]]$GT == '0/1' | vcf.list[[sample]]$CHROM %in% c('X', 'chrX'))] <- T
    }
    new.mask <- new.mask & hetero.mask
  }
  
  if (!all(chrs %in% unique(vcf.list[[1]]$CHROM[new.mask]))){
    cat('ERROR: No variants remain in at least one of the chromosomes after applying filter 2.\n')
    quit(status=0)
  }
  
  for (sample in args$samples.no.u){
    vcf.list[[sample]] <- vcf.list[[sample]][new.mask,]
  }
  
  ## set remaining non-hetero to missing data
  
  if (length(args$keep.hetero.ids)){
    for (sample in args$keep.hetero.ids){
      is <- which(vcf.list[[sample]]$GT %in% c('0/0', '1/1') & vcf.list[[sample]]$CHROM %in% chrs[1:22])
      if (length(is) > 0){
        vcf.list[[sample]]$GENO[is] <- 'N/N'
        vcf.list[[sample]]$GT[is] <- './.'
        for (n in c('AF', 'DP')) vcf.list[[sample]][[n]][is] <- NA
      }
    }
  }
  
  return(vcf.list)
}












# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                               Functions: running Merlin & correcting Merlin haplotypes
# ---------------------------------------------------------------------------------------------------------------------------------------------------

run.merlin <- function(args, vcfs.filtered2){
  ## prepare run 1
  
  ped.1 <- cbind(rep(1, length(args$sample.ids)), args$sample.ids, args$father.ids, args$mother.ids, args$genders)
  ped.1[is.na(ped.1)] <- '0' ; ped.1[,5][ped.1[,5] == 'M'] <- '1' ; ped.1[,5][ped.1[,5] == 'F'] <- '2'
  
  ped.2 <- matrix(ncol = nrow(vcfs.filtered2[[1]]), nrow = nrow(ped.1))
  for (s in args$sample.ids){
    if (s %in% args$samples.u){
      ped.2[which(args$sample.ids == s),] <- rep('N/N', ncol(ped.2))
    } else {
      ped.2[which(args$sample.ids == s),] <- vcfs.filtered2[[s]]$GENO
    }
  }
  
  dat <- cbind('M', vcfs.filtered2[[1]]$ID)
  map <- cbind(substr(vcfs.filtered2[[1]]$CHROM, 4, 10), vcfs.filtered2[[1]]$ID)
  map <- cbind(map, vcfs.filtered2[[1]]$POS / 1000000)
  autosome.m <- map[,1] %in% as.character(1:22)
  
  dir.create(args$merlin.dir, showWarnings = F, recursive = T)
  
  suppressMessages(fwrite(cbind(ped.1, ped.2[,autosome.m]), paste0(args$merlin.dir, 'merlin.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[autosome.m,], paste0(args$merlin.dir, 'merlin.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[autosome.m,], paste0(args$merlin.dir, 'merlin.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  suppressMessages(fwrite(cbind(ped.1, ped.2[,!autosome.m]), paste0(args$merlin.dir, 'merlinX.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[!autosome.m,], paste0(args$merlin.dir, 'merlinX.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[!autosome.m,], paste0(args$merlin.dir, 'merlinX.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  
  ## execute 1
  
  cat('Running Merlin --error ...\n')
  system(paste0('"', as.character(Sys.which("merlin")), '"',
                ' -d "', args$merlin.dir, 'merlin.dat"',
                ' -p "', args$merlin.dir, 'merlin.ped"',
                ' -m "', args$merlin.dir, 'merlin.map"',
                ' --error --prefix "',
                args$merlin.dir, 'merlin" > "', args$merlin.dir, 'merlin.o" && ',
                '"', as.character(Sys.which("minx")), '"',
                ' -d "', args$merlin.dir, 'merlinX.dat"',
                ' -p "', args$merlin.dir, 'merlinX.ped"',
                ' -m "', args$merlin.dir, 'merlinX.map"',
                ' --error --prefix "',
                args$merlin.dir, 'merlinX" > "', args$merlin.dir, 'merlinX.o"'))
  
  ## prepare run 2
  
  cat('Parsing & removing unlikely variants ...\n')
  
  unl.var <- as.character(read.table(paste0(args$merlin.dir, 'merlin.err'), header = T)[,3])
  unl.var.X <- as.character(read.table(paste0(args$merlin.dir, 'merlinX.err'), header = T)[,3])
  
  unl.mask <- !(map[,2] %in% unl.var)
  unl.mask.X <- !(map[,2] %in% unl.var.X)
  
  overall.map <- map[unl.mask & unl.mask.X,]
  map.list <- list()
  for (chr in chrs){
    map.list[[chr]] <- data.frame(overall.map[overall.map[,1] == substr(chr, 4, 10),c(2,3)],
                                  stringsAsFactors = F)
    map.list[[chr]][,2] <- as.numeric(map.list[[chr]][,2]) * 1000000
    colnames(map.list[[chr]]) <- c('id', 'pos')
    map.list[[chr]]$pos.out <- scales::comma(map.list[[chr]]$pos, accuracy = 1)
  }
  
  
  suppressMessages(fwrite(cbind(ped.1, ped.2[,autosome.m & unl.mask]),
                          paste0(args$merlin.dir, 'merlin.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[autosome.m & unl.mask,], paste0(args$merlin.dir, 'merlin.dat'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  write.table(map[autosome.m & unl.mask,], paste0(args$merlin.dir, 'merlin.map'), col.names = F,
              row.names = F, quote = F, sep = '\t')
  suppressMessages(fwrite(cbind(ped.1, ped.2[,!autosome.m & unl.mask.X]),
                          paste0(args$merlin.dir, 'merlinX.ped'),
                          col.names = F, row.names = F, quote = F, sep = '\t'))
  write.table(dat[!autosome.m & unl.mask.X,], paste0(args$merlin.dir, 'merlinX.dat'),
              col.names = F, row.names = F, quote = F, sep = '\t')
  write.table(map[!autosome.m & unl.mask.X,], paste0(args$merlin.dir, 'merlinX.map'),
              col.names = F, row.names = F, quote = F, sep = '\t')
  
  ## run 2
  
  
  cat(paste0('Running Merlin --', args$merlin.model,' ...\n'))
  
  system(paste0('"', as.character(Sys.which("merlin")), '"',
                ' -d "', args$merlin.dir, 'merlin.dat"',
                ' -p "', args$merlin.dir, 'merlin.ped"',
                ' -m "', args$merlin.dir, 'merlin.map"',
                ' --', args$merlin.model,' --prefix "',
                args$merlin.dir, 'merlin" > "', args$merlin.dir, 'merlin.o" && ',
                '"', as.character(Sys.which("minx")), '"',
                ' -d "', args$merlin.dir, 'merlinX.dat"',
                ' -p "', args$merlin.dir, 'merlinX.ped"',
                ' -m "', args$merlin.dir, 'merlinX.map"',
                ' --', args$merlin.model,' --prefix "',
                args$merlin.dir, 'merlinX" > "', args$merlin.dir, 'merlinX.o"'))
  
  return(map.list)
}

# -----
# Parse Merlin output
# -----

parse.merlin <- function(args){
  
  cat('Loading & parsing Merlin output ...\n')
  
  get.table.order <- function(file){
    all.chr <- readLines(file)
    starts <- which(grepl('FAMILY', all.chr))
    ends <- c(starts[-1] - 1, length(all.chr))
    per.chr = all.chr[starts[1]:ends[1]]
    per.chr = per.chr[per.chr != '']
    lines = per.chr[-1]
    
    header = paste0(lines[which(grepl('(', lines, fixed = T))], collapse = '')
    header = gsub("\\s*\\([^\\)]+\\)", "", header)
    header = strsplit(header, ' ')[[1]]
    header = header[header != '']
    return(match(args$sample.ids, header))
  }
  
  zip.lists <- function(x, y){
    lapply(1:min(length(x), length(y)), function(i) c(x[[i]], y[[i]]))
  }
  
  lines.to.frame <- function(lines){
    starts.i <- which(grepl('(', lines, fixed = T)) + 1
    ends.i <- c(starts.i[-1] - 2, length(lines))
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
    
    final.lines <- lines[starts.i[1]:ends.i[1]]
    if (length(starts.i) > 1){
      for (i in 2:length(starts.i)){
        final.lines <- zip.lists(final.lines, lines[starts.i[i]:ends.i[i]])
      }
    }
    return(matrix(unlist(final.lines), ncol = length(final.lines[[1]]), byrow = TRUE))
  }
  
  parse <- function(file, chrs, o){
    all.chr <- readLines(file)
    starts <- which(grepl('FAMILY', all.chr))
    ends <- c(starts[-1] - 1, length(all.chr))
    parsed <- list()
    for (chr in chrs){
      i = which(chrs == chr)
      per.chr = all.chr[starts[i]:ends[i]]
      per.chr = per.chr[per.chr != '']
      per.chr = per.chr[-1]
      table <- lines.to.frame(per.chr)[,o]
      parsed[[chr]] <- table
    }
    return(parsed)
  }
  
  table.order = get.table.order(paste0(args$merlin.dir, 'merlin.chr'))
  table.orderX = get.table.order(paste0(args$merlin.dir, 'merlinX.chr'))
  
  parsed.geno <- parse(paste0(args$merlin.dir, 'merlin.chr'), chrs[1:22], table.order)
  parsed.flow <- parse(paste0(args$merlin.dir, 'merlin.flow'), chrs[1:22], table.order)
  parsed.genoX <- parse(paste0(args$merlin.dir, 'merlinX.chr'), chrs[23], table.orderX)
  parsed.flowX <- parse(paste0(args$merlin.dir, 'merlinX.flow'), chrs[23], table.orderX)
  
  for (i in which(args$genders == 'M')){
    parsed.genoX$chrX[,i] <- paste0(parsed.genoX$chrX[,i], 'X')
    parsed.flowX$chrX[,i] <- paste0(parsed.flowX$chrX[,i], 'X')
  }
  
  parsed.geno$chrX <- parsed.genoX$chrX
  parsed.flow$chrX <- parsed.flowX$chrX
  
  for (chr in chrs){
    bad.inhs <- sapply(1:nrow(parsed.geno[[chr]]), function(i) all(grepl('NA', parsed.geno[[chr]][i,])))
    parsed.geno[[chr]] <- parsed.geno[[chr]][!bad.inhs,]
    parsed.flow[[chr]] <- parsed.flow[[chr]][!bad.inhs,]
    map.list[[chr]] <- map.list[[chr]][!bad.inhs,]
  }
  
  for (chr in chrs){
    parsed.geno[[chr]] <- parsed.geno[[chr]][,which(args$sample.ids %in% args$samples.no.u)]
    parsed.flow[[chr]] <- parsed.flow[[chr]][,which(args$sample.ids %in% args$samples.no.u)]
  }
  
  return(list(parsed.geno = parsed.geno, parsed.flow = parsed.flow, map.list = map.list))
}

# -----
# Don't make N/N inferences, keep actual data
# -----

update.geno <- function(parsed.geno){
  for (chr in chrs){
    js <- match(map.list[[chr]]$id, vcfs.filtered2[[1]]$ID)
    for (sample in args$samples.no.u){
      i = which(sample == args$samples.no.u)
      x <- vcfs.filtered2[[sample]]$GENO[js]
      if (any(grepl('X', parsed.geno[[chr]][,i]))){
        parsed.geno[[chr]][x == 'N/N', i] <- 'NA|X'
      } else {
        parsed.geno[[chr]][x == 'N/N', i] <- 'NA|NA'
      }
    }
  }
  return(parsed.geno)
}

# -----
# Correct by window voting
# -----

correct.profiles <- function(args, parsed.flow){
  is.corrected <- list()
  for (chr in chrs){
    is.corrected[[chr]] <- matrix(nrow = nrow(map.list[[chr]]), ncol = length(args$samples.no.u) * 2)
    for (i in 1:length(args$samples.no.u)){
      is.corrected[[chr]][,(i*2)-1] <- F
      is.corrected[[chr]][,i*2] <- F
    }
  }
  
  correct.vector.1 <- function(v, pos, max.distance){
    letters = unique(v)
    neighbours.i <- lapply(pos, function(p) c(which(abs(pos - p) <= max.distance)))
    neighbours.letters <- lapply(1:length(v), function(i) v[neighbours.i[[i]]])
    neighbours.pos <- lapply(1:length(v), function(i) abs(pos - pos[i])[neighbours.i[[i]]])
    neighbours.weights <- lapply(neighbours.pos, function(x) (max.distance * 2) / (x + max.distance) - 1)
    if (max.distance == 0) neighbours.weights <- lapply(1:length(v), function(x) 1)
    c.v <- sapply(1:length(v), function(i)
      letters[which.max(c(sum(neighbours.weights[[i]][neighbours.letters[[i]] == letters[1]]),
                          sum(neighbours.weights[[i]][neighbours.letters[[i]] == letters[2]], na.rm = T)))])
    return(c.v)
  }
  
  correct.vector.2 <- function(flow, geno, min.seg.var){
    breakpoints <- which(c('ZZ', flow) != c(flow, 'ZZ'))
    for (i in 1:(length(breakpoints)-1)){
      sequence <- breakpoints[i]:c(breakpoints[i+1]-1)
      if (length(which(geno[sequence] != 'NA')) > min.seg.var) next
      if (breakpoints[i]-1 != 0){
        letter = flow[breakpoints[i]-1] # previous segment when possible
      } else {
        letter = flow[breakpoints[i+1]] # next segment otherwise
      }
      flow[sequence] <- rep(letter, length(sequence))
    }
    return(flow)
  }
  
  if (args$window.size.voting != 0 | args$min.seg.var != 0){
    cat('Correcting haplotypes, working ...\n')
    for (chr in chrs[1:22]){
      cat(paste0('  ... at ', chr, '\n'))
      pos = map.list[[chr]][,2]
      for (i in 1:length(args$samples.no.u)){
        v = parsed.flow[[chr]][,i]
        a <- sapply(strsplit(v, '|', fixed = T), function(x) x[1])
        b <- sapply(strsplit(v, '|', fixed = T), function(x) x[2])
        c.a = a
        c.b = b
        if (args$min.seg.var != 0){
          c.a <- correct.vector.2(c.a, sapply(strsplit(parsed.geno[[chr]][,i], '|', fixed = T), function(x) x[1]),
                                  args$min.seg.var)
          c.b <- correct.vector.2(c.b, sapply(strsplit(parsed.geno[[chr]][,i], '|', fixed = T), function(x) x[2]),
                                  args$min.seg.var)
        }
        if (args$window.size.voting != 0){
          c.a <- correct.vector.1(c.a, pos, args$window.size.voting / 2)
          c.b <- correct.vector.1(c.b, pos, args$window.size.voting / 2)
        }
        parsed.flow[[chr]][,i] <- paste0(c.a, '|', c.b)
        is.corrected[[chr]][,(i*2)-1] <- a != c.a
        is.corrected[[chr]][,i*2] <- b != c.b
      }
    }
  }
  
  if (args$window.size.voting.X != 0 | args$min.seg.var.X != 0){
    if (args$window.size.voting == 0 & args$min.seg.var == 0) cat('Correcting haplotypes, working ...\n')
    chr = chrs[23]
    cat(paste0('  ... at ', chr, '\n'))
    pos = map.list[[chr]][,2]
    for (i in 1:length(args$samples.no.u)){
      v = parsed.flow[[chr]][,i]
      a <- sapply(strsplit(v, '|', fixed = T), function(x) x[1])
      b <- sapply(strsplit(v, '|', fixed = T), function(x) x[2])
      c.a = a
      c.b = b
      if (args$min.seg.var.X != 0){
        c.a <- correct.vector.2(c.a, sapply(strsplit(parsed.geno[[chr]][,i], '|', fixed = T), function(x) x[1]),
                                args$min.seg.var.X)
        c.b <- correct.vector.2(c.b, sapply(strsplit(parsed.geno[[chr]][,i], '|', fixed = T), function(x) x[2]),
                                args$min.seg.var.X)
      }
      if (args$window.size.voting.X != 0){
        c.a <- correct.vector.1(c.a, pos, args$window.size.voting.X / 2)
        c.b <- correct.vector.1(c.b, pos, args$window.size.voting.X / 2)
      }
      parsed.flow[[chr]][,i] <- paste0(c.a, '|', c.b)
      is.corrected[[chr]][,(i*2)-1] <- a != c.a
      is.corrected[[chr]][,i*2] <- b != c.b
    }
  }
  return(list(parsed.flow = parsed.flow, is.corrected = is.corrected))
}













# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                           Functions: running specific analyses & creating visualizations
# ---------------------------------------------------------------------------------------------------------------------------------------------------

# -----
# Overall
# -----

mark.region <- function(fig, chr.cs, ylim, region, chr.lengths, plot.flanks = T){
  c <- strsplit(region, ':')[[1]][1]
  s <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][1]) ; s <- max(s, 1)
  flank.s <- s - args$regions.flanking.size ; flank.s <- max(flank.s, 1)
  e <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][2]) ; e <- min(e, chr.lengths[c])
  flank.e <- e + args$regions.flanking.size ; flank.e <- min(flank.e, chr.lengths[c])
  
  region.start <- paste0(c, ':', scales::comma(s, accuracy = 1))
  region.end <- paste0(c, ':', scales::comma(e, accuracy = 1))
  flank.start <- paste0(c, ':', scales::comma(flank.s, accuracy = 1))
  flank.end <- paste0(c, ':', scales::comma(flank.e, accuracy = 1))
  
  add.trace <- function(fig, xs, text, size = 1/2){
    fig <- fig %>% add_trace(x = xs, y = ylim, name = 'region',
                             hoverinfo = "text", line = list(color = colors[length(letters) + 1], width = args$dot.factor * size),
                             text = text, type='scatter', marker = list(color = colors[length(letters) + 1], size = .1),
                             mode='lines+markers', hoverlabel=list(bgcolor=colors[length(letters) + 1]), inherit = F)
    return(fig)
  }
  
  fig <- add.trace(fig, c(chr.cs[c] + s, chr.cs[c] + s), paste0(region.start, ' (region start)'))
  fig <- add.trace(fig, c(chr.cs[c] + e, chr.cs[c] + e), paste0(region.end, ' (region end)'))
  
  if (plot.flanks){
    fig <- add.trace(fig, rep(chr.cs[c] + flank.s, 2), paste0(flank.start, ' (flank start)'), 1/4)
    fig <- add.trace(fig, rep(chr.cs[c] + flank.e, 2), paste0(flank.end, ' (flank end)'), 1/4)
  }
  return(fig)
}

add.cytoband <- function(fig, chr, y, line.width = 4){
  s <- c()
  names <- c()
  cols <- c()
  for (i in 1:length(cytobands[[chr]])){
    xs <- c(cytobands[[chr]][[i]]$start, cytobands[[chr]][[i]]$end)
    col <- c('lightgrey', 'darkgrey')[[i %% 2 + 1]]
    if (any(sapply(c('acen', 'gvar', 'stalk'), function(x) grepl(x, cytobands[[chr]][[i]]$name)))) col <- 'black'
      fig <- add_trace(fig, x = xs, y = rep(y, 2),
                       name = NULL, hoverinfo = "none",
                       line = list(color = col, width = args$dot.factor * line.width),
                       type='scatter', mode='lines', inherit = F)
      seq <- seq(xs[1], xs[2], 10000000)
      s <- c(s, seq)
      names <- c(names, paste0(cytobands[[chr]][[i]]$name, ' (',
                               scales::comma(seq, accuracy = 1), ')'))
      cols <- c(cols, rep(col, length(seq)))
  }
  
  fig <- add_markers(fig, x = s, y = rep(y, length(s)), text=names, name = NULL,
                     hoverinfo='text', marker = list(color = cols, size = args$dot.factor * .1),
                     type='scatter', mode='marker', inherit = F)
  return(fig)
}

add.locus.bar <- function(fig, chr, end, y, line.width = 4){
  s <- c(seq(1, end, 10000000), end)
  names <- c(scales::comma(s, accuracy = 1))
  cols <- c()
  for (i in 1:c(length(s)-1)){
    col <- c('lightgrey', 'darkgrey')[[i %% 2 + 1]]
    fig <- add_trace(fig, x = c(s[i], s[i+1]), y = rep(y, 2),
                     name = NULL, hoverinfo = "none",
                     line = list(color = col, width = args$dot.factor * line.width),
                     type='scatter', mode='lines', inherit = F)
    cols <- c(cols, col)
  }
  cols <- c(cols, c('lightgrey', 'darkgrey')[c('lightgrey', 'darkgrey') != col])
  fig <- add_markers(fig, x = s, y = rep(y, length(s)), text=names, name = NULL,
                     hoverinfo='text', marker = list(color = cols, size = args$dot.factor * .1),
                     type='scatter', mode='marker', inherit = F)
  return(fig)
}

add.chr.lines <- function(fig, chr.cs, ylim){
  for (c in names(chr.cs)){
    fig <- fig %>%
      add_trace(x = c(chr.cs[c], chr.cs[c]), y = ylim,
                hoverinfo = "text",
                line = list(color = 'black', width = .5),
                text = c, type='scatter',
                marker = list(color = 'black', size = .1),
                mode='lines+markers', inherit = F)
  }
  return(fig)
}

fill.matrix <- function(matrix, fill = 'white'){
  for (i in 1:ncol(matrix)){
    matrix[,i] <- rep(fill, nrow(matrix))
  }
  return(matrix)
}

# -----
# Merlin
# -----

get.haplo.profiles <- function(){
  get.breaks <- function(f, pos){
    changes <- cumsum(rle(f)$lengths)
    colors <- letter.colors[rle(f)$values]
    breakpoints <- sapply(changes, function(x) pos[x] + (pos[x+1] - pos[x]) / 2)
    breakpoints <- breakpoints[-length(breakpoints)]
    return(list(breakpoints = breakpoints, colors = colors))
  }
  
  filter.region <- function(frame, chr, whole.chromosome = F){
    if (length(args$regions)){
      for (region in args$regions){
        r.split <- strsplit(region, ':')[[1]]
        if (chr == r.split[1]){
          if (whole.chromosome) return(frame)
          s <- as.numeric(strsplit(r.split[2],'-')[[1]][1])
          s <- s - args$regions.flanking.size
          e <- as.numeric(strsplit(r.split[2],'-')[[1]][2])
          e <- e + args$regions.flanking.size
          return(frame[frame$x >= s & frame$x <= e,])
        }
      }
    }
    return(frame[-(1:nrow(frame)),])
  }
  
  add.marker.and.trace <- function(fig, y, f = 'f1', mar = 'y-down-open', symbol.offset = .3){
    for (i in 1:(length(breaks[[s]][[f]])-1)){
      if (i != 1){
        fig <- add_markers(fig, x = breaks[[s]][[f]][i], y = rep(y + symbol.offset, 2),
                           name = NULL, hoverinfo = "none",
                           marker = list(symbol = mar, color = colors[length(letters) + 1],
                                         size = args$dot.factor * 8),
                           type='scatter', mode='marker', inherit = F)
      }
      fig <- add_trace(fig, x = c(breaks[[s]][[f]][i], breaks[[s]][[f]][i+1]), y = rep(y, 2),
                       name = NULL, hoverinfo = "none",
                       line = list(color = breaks[[s]][[paste0(f, 'cols')]][i], width = args$dot.factor * 2),
                       type='scatter', mode='lines', inherit = F)
    }
    return(fig)
  }
  
  chr.lengths <- sapply(chrs, function(x) max(vcfs.filtered2[[1]]$POS[vcfs.filtered2[[1]]$CHROM == x]))
  
  haplo.profiles <- list()
  for (c in chrs){
    haplo.frame <- matrix(nrow = 0, ncol = 9)
    annot.list <- list()
    breaks <- list()
    for (s in args$samples.no.u){
      x <- map.list[[c]]$pos
      f1 <- sapply(strsplit(parsed_flow[[c]][,which(args$samples.no.u == s)], '|', fixed = T), function(x) x[1])
      f2 <- sapply(strsplit(parsed_flow[[c]][,which(args$samples.no.u == s)], '|', fixed = T), function(x) x[2])
      g1 <- sapply(strsplit(parsed_geno[[c]][,which(args$samples.no.u == s)], '|', fixed = T), function(x) x[1])
      g2 <- sapply(strsplit(parsed_geno[[c]][,which(args$samples.no.u == s)], '|', fixed = T), function(x) x[2])
      c1 <- is.corrected[[c]][,which(args$samples.no.u == s) * 2 - 1]
      c2 <- is.corrected[[c]][,which(args$samples.no.u == s) * 2]
      breaks[[s]]$f1 <- c(x[1], get.breaks(f1, x)$breakpoints, x[length(x)])
      breaks[[s]]$f1cols <- get.breaks(f1, x)$colors
      breaks[[s]]$f2 <- c(x[1], get.breaks(f2, x)$breakpoints, x[length(x)])
      breaks[[s]]$f2cols <- get.breaks(f2, x)$colors
      symbol <- rep(1, length(c1) * 2)
      symbol[c(c1,c2)] <- 0
      symbol[c(g1,g2) == 'NA'] <- 101 ## will show nothing
      id1 <- paste0(c, ':', map.list[[c]]$pos.out, ' (', g1, ')')
      id2 <- paste0(c, ':', map.list[[c]]$pos.out, ' (', g2, ')')
      y1 <- length(args$samples.no.u) * 3 - which(args$samples.no.u == s) * 3 + 1
      y2 <- length(args$samples.no.u) * 3 - which(args$samples.no.u == s) * 3
      haplo.frame.sub <- data.frame(c(x, x), c(rep(y1, length(x)), rep(y2, length(x))),
                                    c(id1, id2), c(letter.colors[f1],  letter.colors[f2]), symbol,
                                    stringsAsFactors = F, c(rep(which(args$samples.no.u == s) * 2 - 1, length(x)),
                                                            rep(which(args$samples.no.u == s) * 2, length(x))))
      annot.list[[which(args$samples.no.u == s)]] <- list(x = 1, y = y1 + 1,
                                                          text = args$samples.out[args$sample.ids == s], showarrow = F)
      if (all(c(g1, g2) == 'NA')) next
      haplo.frame <- rbind(haplo.frame, haplo.frame.sub)
    }
    
    ## raw data points
    
    colnames(haplo.frame) <- c('x', 'y', 'id', 'col', 'symbol', 'name')
    haplo.frame.for.plotly <- haplo.frame
    if (args$keep.chromosomes.only) haplo.frame.for.plotly <- filter.region(haplo.frame, c, whole.chromosome = T)
    if (args$keep.regions.only) haplo.frame.for.plotly <- filter.region(haplo.frame, c)
    p <- plot_ly(haplo.frame.for.plotly, x =~x, y =~y, text =~id, name=~name, marker = list(color=~col,
                                                                                            symbol=~symbol,
                                                                                            size = args$dot.factor * 4,
                                                                                            line=list(color=~col)),
                 type = 'scattergl', mode = 'markers', hoverinfo = 'text', height = 900 * length(args$samples.no.u),
                 hoverlabel=list(bgcolor=~col))
    
    ## layout
    
    p <- p %>% layout(xaxis = list(title = list(text=c, standoff=10), showticklabels = F,
                                   zeroline = F, showgrid = F), showlegend = F,
                      yaxis = list(title = '',showticklabels = F, zeroline = F, showgrid = F,
                                   fixedrange = T, range = c(-1, length(args$samples.no.u) * 3 + 1)),
                      annotations = annot.list)
    
    ## add traces and recombination points
    
    for (s in args$samples.no.u){
      y2 <- length(args$samples.no.u) * 3 - which(args$samples.no.u == s) * 3
      p <- add.marker.and.trace(p, length(args$samples.no.u) * 3 - which(args$samples.no.u == s) * 3 + 1)
      p <- add.marker.and.trace(p, length(args$samples.no.u) * 3 - which(args$samples.no.u == s) * 3, 'f2', 'y-up-open', symbol.offset = -.3)
    }
    
    ## add regions
    
    if (length(args$regions)){
      for (region in args$regions){
        if (c == strsplit(region, ':')[[1]][1]){
          tmp <- 1 ; names(tmp) <- c
          p <- mark.region(p, tmp, c(-.5, length(args$samples.no.u) * 3 + 1), region, chr.lengths)
        }
      }
    }
    
    ## add cytobands
    
    if (length(args$cytoband.file)){
      p <- add.cytoband(p, c, max(haplo.frame$y) + 2)
    } else {
      p <- add.locus.bar(p, c, chr.lengths[[c]], max(haplo.frame$y) + 2)
    }
    
    haplo.profiles[[c]] <- p
  }
  return(haplo.profiles)
}

get.haplo.tables <- function(){
  rows <- list()
  for (s1 in args$samples.no.u){
    for (i1 in c(1,2)){
      row <- c()
      for (s2 in args$samples.no.u){
        for (i2 in c(1,2)){
          if ((which(args$samples.no.u == s2) > which(args$samples.no.u == s1)) |
              (s1 == s2 & i1 != i2)){
            row <- c(row, '')
          } else {
            obs <- c()
            exp <- c()
            for (chr in chrs){
              strand1 <- sapply(parsed.flow[[chr]][,args$samples.no.u == s1], function(x) strsplit(x, '|', fixed = T)[[1]][i1])
              strand2 <- sapply(parsed.flow[[chr]][,args$samples.no.u == s2], function(x) strsplit(x, '|', fixed = T)[[1]][i2])
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
  
  table <- rbind(rep(c('1', '2'), length(args$samples.no.u)), sapply(rows, cbind))
  table <- cbind(c('', rep(c('1', '2'), length(args$samples.no.u))), table)
  table <- cbind(c('', unlist(lapply(args$samples.no.u, function(x) c(paste0('(', which(args$samples.no.u == x), ') ',
                                                                             trim(gsub(x, '', args$samples.out[args$sample.ids == x]))),
                                                                      args$samples.no.u[args$samples.no.u == x])))), table)
  table <- rbind(c('', '', unlist(lapply(args$samples.no.u, function(x) rep(paste0('(', which(args$samples.no.u == x), ')'),2)))), table)
  table <- cbind(table, rep('', nrow(table)))
  
  cols.fill <- fill.matrix(table, 'white')
  cols.fill[1:2,] <- colors[1] ; cols.fill[,1:2] <- colors[1]
  cols.fill[1:2,1:2] <- 'white'
    for (i in seq(1, length(args$samples.no.u)*2, 4)){
      cols.fill[1:2, (i+2):(i+3)] <- colors[2]
      cols.fill[(i+2):(i+3), 1:2] <- colors[2]
    }
  cols.fill[,ncol(cols.fill)] <- 'white'
    cols.line <- fill.matrix(table, 'grey')
    cols.line[2,] <- 'white' ; cols.line[,2] <- 'white'
      for (i in seq(1, length(args$samples.no.u)*2, 4)){
        cols.line[1, (i+2):(i+3)] <- colors[2]
        cols.line[(i+2):(i+3), 1] <- colors[2]
      }
    for (i in seq(3, length(args$samples.no.u)*2, 4)){
      cols.line[1, (i+2):(i+3)] <- colors[1]
      cols.line[(i+2):(i+3), 1] <- colors[1]
    }
    cols.line[1:2,1:2] <- 'white'
      cols.line[,ncol(cols.line)] <- 'white'
        
      fig <- plot_ly(
        type = 'table',
        header = list(
          line = list(color = 'white'),
          fill = list(color = 'white'),
          font = list(color = 'white', size = 1)),
        cells = list(values = t(table),
                     line = list(color = t(cols.line), width = t(fill.matrix(table, 1))), fill = list(color = t(cols.fill)),
                     font = list(color = rgb(.2,.2,.2), size = 9)), hoverinfo = 'none')
      fig <- fig %>% layout(autosize = T)
      return(fig)
}

# -----
# Tables
# -----

get.plotly.table <- function(vcf.list){
  states <- c('0/0', '0/1', '1/1')
  rows <- list()
  for (i in 1:length(args$samples.no.u)){
    for (k in 1:3){
      row <- c()
      for (j in 1:length(args$samples.no.u)){
        x <- vcf.list[[args$samples.no.u[i]]]
        x <- x[which(x$GT %in% states),]
        y <- vcf.list[[args$samples.no.u[j]]]
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
  
  table <- rbind(rep(c('0/0', '0/1', '1/1'), length(args$samples.no.u)), sapply(rows, cbind))
  table <- cbind(c('', rep(c('0/0', '0/1', '1/1'), length(args$samples.no.u))), table)
  table <- cbind(c('', unlist(lapply(args$samples.no.u, function(x) c(paste0('(', which(args$samples.no.u == x), ')'),
                                                                      x, trim(gsub(x, '', args$samples.out[args$sample.ids == x])))))), table)
  table <- rbind(c('', '', unlist(lapply(args$samples.no.u, function(x) c('',paste0('(', which(args$samples.no.u == x), ')'),'')))), table)
  table <- cbind(table, rep('', nrow(table)))
  
  cols.fill <- fill.matrix(table, 'white')
  cols.fill[1:2,] <- colors[1] ; cols.fill[,1:2] <- colors[1]
  cols.fill[1:2,1:2] <- 'white'
    for (i in seq(1, length(args$samples.no.u)*3, 6)){
      cols.fill[1:2, (i+2):(i+4)] <- colors[2]
      cols.fill[(i+2):(i+4), 1:2] <- colors[2]
    }
  cols.fill[,ncol(cols.fill)] <- 'white'
    cols.line <- fill.matrix(table, 'grey')
    cols.line[2,] <- 'white' ; cols.line[,2] <- 'white'
      for (i in seq(1, length(args$samples.no.u)*3, 6)){
        cols.line[1, (i+2):(i+4)] <- colors[2]
        cols.line[(i+2):(i+4), 1] <- colors[2]
      }
    if (length(args$samples.no.u) > 1){
      for (i in seq(4, length(args$samples.no.u)*3, 6)){
        cols.line[1, (i+2):(i+4)] <- colors[1]
        cols.line[(i+2):(i+4), 1] <- colors[1]
      }
    }
    cols.line[1:2,1:2] <- 'white'
      cols.line[,ncol(cols.line)] <- 'white'
        
      fig <- plot_ly(
        type = 'table',
        header = list(
          line = list(color = 'white'),
          fill = list(color = 'white'),
          font = list(color = 'white', size = 1)),
        cells = list(values = t(table),
                     line = list(color = t(cols.line), width = t(fill.matrix(table, 1))), fill = list(color = t(cols.fill)),
                     font = list(color = rgb(.2,.2,.2), size = 9), height = 30), hoverinfo = 'none')
      fig <- fig %>% layout(autosize = T)
      
      return(fig)
}

# -----
# Pedigree
# -----

write.pedigree <- function(file){
  status <- matrix(ncol = 2, nrow = length(args$sample.ids))
  if (length(args$nonaffected)) status[which(args$sample.ids %in% args$nonaffected),] <- 0
  if (length(args$carrier)){
    status[which(args$sample.ids %in% args$carrier),1] <- 0
    status[which(args$sample.ids %in% args$carrier),2] <- 1
  }
  if (length(args$affected)) status[which(args$sample.ids %in% args$affected),] <- 1
  
  pedi <- suppressWarnings(pedigree(args$samples.out,
                                    args$samples.out[match(args$father.ids, args$sample.ids)], 
                                    args$samples.out[match(args$mother.ids, args$sample.ids)],
                                    args$genders, status))
  png(file, width=log(length(args$sample.ids)) * 4, height=5, units='in', res=512)
  suppressWarnings(plot(pedi, mar = c(4,4,4,4), density = c(-1, -1)))
  invisible(dev.off())
}

# -----
# Variant distribution
# -----

get.var.dis.fig <- function(vcf.list){
  chr.lengths <- sapply(chrs, function(x) max(vcf.list[[1]]$POS[vcf.list[[1]]$CHROM == x]))
  chr.cs <- c(1, cumsum(chr.lengths)) ; names(chr.cs) <- c(chrs, 'end')
  
  annot <- c()
  counts <- c()
  poss <- c()
  for (chr in chrs){
    breaks <- seq(1, chr.lengths[chr] + args$window.size, args$window.size)
    poss <- c(poss, breaks[-length(breaks)] + chr.cs[chr])
    h <- hist(vcf.list[[1]]$POS[vcf.list[[1]]$CHROM == chr], breaks, plot = F)
    counts <- c(counts, h$counts)
    annot <- c(annot, paste0(chr, ':', scales::comma(breaks[-length(breaks)], accuracy = 1), '-',
                             scales::comma(breaks[-length(breaks)] + args$window.size - 1,
                                           accuracy = 1)))
  }
  
  dat <- data.frame(annot, poss, counts)
  
  colnames(dat) <- c('range', 'index', 'count')
  var.dis <- plot_ly(dat, x =~index, y =~count, text=~range, height = 240,
                     marker = list(color = colors[1], alpha = .5, size = 2 * args$dot.factor,
                                   line = list(color = colors[1], alpha = .5)),
                     type = 'scatter', mode = 'markers', hoverinfo = 'y+text')
  
  var.dis <- var.dis %>% layout(xaxis = list(title = list(text='', standoff = 1), showticklabels = F,
                                             zeroline = F, showgrid = F),
                                showlegend = F, yaxis = list(title = 'variant count', zeroline = F),
                                hovermode = 'x unified')
  
  var.dis <- add.chr.lines(var.dis, chr.cs, c(-max(dat$count)*.1, max(dat$count)*1.1))
  
  if (length(args$regions)){
    for (region in args$regions){
      var.dis <- mark.region(var.dis, chr.cs, c(-max(dat$count)*.1, max(dat$count)*1.1), region, chr.lengths)
    }
  }
  return(var.dis)
}

# -----
# Variant depth
# -----

get.var.depth.hist <- function(vcf.list){
  varhists <- list()
  for (s in args$samples.no.u){
    hist <- plot_ly(x = ~vcf.list[[s]]$DP[!is.na(vcf.list[[s]]$DP) & vcf.list[[s]]$DP !=0], type = "histogram", hoverinfo = 'x+y',
                    marker = list(color = colors[1]), height = 200 * ceiling(length(args$samples.no.u) / 4))
    hist <- hist %>% layout(xaxis = list(title = list(text= args$samples.out[args$sample.ids == s] , standoff = 1),
                                         zeroline = F, showgrid = F),
                            yaxis = list(range = 0),
                            showlegend = F, yaxis = list(title = 'density', zeroline = F))
    varhists[[s]] <- hist
  }
  return(varhists)
}

get.cn.fig <- function(){
  
  cluster.max.len.between.CpG = 200
  clusters <- matrix(nrow = 0, ncol = 4)
  
  for (chr in chrs){
    pos <- vcfs[[1]]$POS[vcfs[[1]]$CHROM == chr]
    
    starts <- c(pos[1], pos[which(pos[-1] - pos[-length(pos)] > cluster.max.len.between.CpG) + 1])
    ends <- c(pos[which(pos[-1] - pos[-length(pos)] > cluster.max.len.between.CpG)], pos[length(pos)])
    amount <- diff(c(0, which(pos[-1] - pos[-length(pos)] > cluster.max.len.between.CpG), length(pos)))
    
    chr.cluster <- matrix(nrow = length(ends), ncol = 4)
    chr.cluster[,1] <- rep(chr, length(starts))
    chr.cluster[,2] <- starts
    chr.cluster[,3] <- ends + 1
    chr.cluster[,4] <- amount
    
    clusters <- rbind(clusters, chr.cluster)
  }
  
  clusters <- data.frame(clusters, stringsAsFactors = F)
  colnames(clusters) <- c('seqnames', 'start', 'end', 'amount')
  for (i in 2:4) clusters[,i] <- as.numeric(clusters[,i])
  clusters.gr <- GRanges(clusters)
  
  pos.gr <- GRanges(seqnames = vcfs[[1]]$CHROM, ranges = IRanges(start = vcfs[[1]]$POS, width = 1))
  
  chr.lengths <- sapply(chrs, function(x) max(vcfs[[1]]$POS[vcfs[[1]]$CHROM == x]))
  cn <- GRanges(seqnames = chrs, ranges = IRanges(start = 1, width = chr.lengths))
  cn <- as.data.frame(slidingWindows(cn, width = args$window.size, step = args$window.size))[,3:5]
  cn.gr <- GRanges(cn)
  
  hits <- findOverlaps(clusters.gr, pos.gr, select = 'all')
  hits <- split(hits@to, hits@from)
  
  hits2 <- findOverlaps(cn.gr, clusters.gr, select = 'all')
  hits2 <- split(hits2@to, hits2@from)
  
  copy.number.plots <- list()
  for (s in args$samples.no.u){
    vcf <- vcfs[[s]]
    var.mask <- vcf$GT != './.'
    
    dat.clusters <- clusters
    dat.clusters$mean.depth[as.numeric(names(hits))] <- sapply(hits, function(hit) mean(vcf$AD[hit][var.mask[hit]], na.rm = T))
    
    dat.cn <- cn
    dat.cn$index <- 1:nrow(dat.cn) * args$window.size - args$window.size / 2
    dat.cn$range <- paste0(dat.cn$seqnames, ':', dat.cn$start, '-', dat.cn$end)
    dat.cn$amount[as.numeric(names(hits2))] <- sapply(hits2, function(hit) length(!is.na(dat.clusters$mean.depth[hit])))
    dat.cn$mean.depth[as.numeric(names(hits2))] <- sapply(hits2, function(hit) mean(dat.clusters$mean.depth[hit], na.rm = T))
    dat.cn$sd.depth[as.numeric(names(hits2))] <- sapply(hits2, function(hit) sd(dat.clusters$mean.depth[hit], na.rm = T))
    
    x <- dat.cn$mean.depth ; y <- dat.cn$sd.depth ; m <- !is.na(y) & !is.na(x)
    dat.cn$resi <- NA; dat.cn$resi[m] <- lm(y[m] ~ x[m])$residuals
    
    weights <- dat.cn$amount / mean(dat.cn$amount, na.rm = T)
    dat.cn$weight <- weights * 2 * args$dot.factor
    
    dat.cn$mask <- dat.cn$amount >= as.numeric(quantile(dat.cn$amount[dat.cn$amount != 0], .05, na.rm = T)) &
      dat.cn$resi < as.numeric(quantile(dat.cn$resi, .95, na.rm = T)) &
      dat.cn$resi > as.numeric(quantile(dat.cn$resi, .05, na.rm = T))
    dat.cn$mask[is.na(dat.cn$mask)] <- F
    
    dat.cn$ratio <- log2(dat.cn$mean.depth / median(dat.cn$mean.depth[dat.cn$mask], na.rm = T))
    
    cd.object <- CNA(dat.cn$ratio[dat.cn$mask],
                     dat.cn$seqnames[dat.cn$mask],
                     dat.cn$start[dat.cn$mask], data.type = "logratio", sampleid = "X")
    f = file()
    sink(file=f) ## silence output
    segmented.cd.object <- invisible(segment(cd.object, verbose=1, weights = dat.cn$weight[dat.cn$mask]))
    sink() ## undo silencing
    close(f)
    
    dat.seg <- segmented.cd.object$output
    dat.seg$loc.end <- dat.seg$loc.end + args$window.size - 1
    
    cn.plot <- plot_ly(dat.cn[dat.cn$mask,], x =~index, y =~ratio, text =~range, name = s,
                       height = 210 * length(args$samples.no.u),
                       marker = list(color = colors[1], alpha = .5, size = args$dot.factor * 2,
                                     line = list(color = colors[1], alpha = .5)),
                       type = 'scatter', mode = 'markers', hoverinfo = 'y+text')
    
    chr.lengths <- sapply(chrs, function(chr) length(which(dat.cn$seqnames == chr))) * args$window.size
    chr.cs <- c(0, sapply(chrs, function(chr) last(which(dat.cn$seqnames == chr))) * args$window.size)
    names(chr.cs) <- c(chrs, 'end')
    
    lower <- min(-2.25, quantile(dat.cn$ratio, na.rm = T, .01))
    upper <- max(2.25, quantile(dat.cn$ratio, na.rm = T, .99))
    ylim = c(lower, upper)
    
    for (i in 1:nrow(dat.seg)){
      st <- dat.seg$loc.start[i] + chr.cs[as.character(dat.seg$chrom[i])]
      e <- dat.seg$loc.end[i] + chr.cs[as.character(dat.seg$chrom[i])]
      h <- dat.seg$seg.mean[i]
      text <- paste0(as.character(dat.seg$chrom[i]), ':', dat.seg$loc.start[i], '-', dat.seg$loc.end[i])
      cn.plot <- cn.plot %>%
        add_trace(x = c(st,e), y = c(h, h), name = text,
                  line = list(color = colors[2], width = args$dot.factor),
                  text = paste0('segment: ', text), type='scatter', hoverinfo = 'y+text',
                  marker = list(color = colors[2], size = .1),
                  mode='lines+markers', inherit = T)
    }
    
    cn.plot <- cn.plot %>% layout(xaxis = list(title = list(text=args$samples.out[args$sample.ids == s],
                                                            standoff = 1),
                                               showticklabels = F, zeroline = F, showgrid = F),
                                  showlegend = F, yaxis = list(title = 'log2(ratio)', zeroline = F, range = ylim))
    
    cn.plot <- add.chr.lines(cn.plot, chr.cs, ylim)
    if (length(args$regions)){
      for (region in args$regions){
        cn.plot <- mark.region(cn.plot, chr.cs, ylim, region, chr.lengths)
      }
    }
    
    copy.number.plots[[s]] <- cn.plot
  }
  return(copy.number.plots)
}

# -----
# Man errors
# -----

get.men.err.fig <- function(child, father, mother, n.rel){
  
  get.trio.error <- function(gt.child, gt.parent1, gt.parent2){
    trio.error <- rep(0, length(gt.child))
    
    m <- gt.parent1 == '0/0' & gt.parent2 == '0/0'
    trio.error[m] <- 1
    trio.error[m][gt.child[m] %in% c('0/1', '1/1')] <- 2
    
    m <- (gt.parent1 == '0/1' & gt.parent2 == '0/0') | (gt.parent1 == '0/0' & gt.parent2 == '0/1')
    trio.error[m] <- 1
    trio.error[m][gt.child[m] %in% c('1/1')] <- 2
    
    m <- (gt.parent1 == '1/1' & gt.parent2 == '0/1') | (gt.parent1 == '0/1' & gt.parent2 == '1/1')
    trio.error[m] <- 1
    trio.error[m][gt.child[m] %in% c('0/0')] <- 2
    
    m <- gt.parent1 == '1/1' & gt.parent2 == '1/1'
    trio.error[m] <- 1
    trio.error[m][gt.child[m] %in% c('0/0', '0/1')] <- 2
    
    m <- (gt.parent1 == '0/0' & gt.parent2 == '1/1') | (gt.parent1 == '1/1' & gt.parent2 == '0/0')
    trio.error[m] <- 1
    trio.error[m][gt.child[m] %in% c('0/0', '1/1')] <- 2
    
    return(trio.error)
  }
  
  get.duo.error <- function(gt.child, gt.parent){
    duo.error <- rep(0, length(gt.child))
    
    m <- gt.parent == '0/0'
    duo.error[m] <- 1
    duo.error[m][gt.child[m] %in% c('1/1')] <- 2
    
    m <- gt.parent == '1/1'
    duo.error[m] <- 1
    duo.error[m][gt.child[m] %in% c('0/0')] <- 2
    
    return(duo.error)
  }
  
  man.err.frame <- vcfs.filtered[[child]][,1:2]
  
  if (length(father) & length(mother)) man.err.frame$trio <- get.trio.error(vcfs.filtered[[child]]$GT,
                                                                            vcfs.filtered[[father]]$GT,
                                                                            vcfs.filtered[[mother]]$GT)
  if (length(father)) man.err.frame$fat <- get.duo.error(vcfs.filtered[[child]]$GT,
                                                         vcfs.filtered[[father]]$GT)
  if (length(mother)) man.err.frame$mot <- get.duo.error(vcfs.filtered[[child]]$GT,
                                                         vcfs.filtered[[mother]]$GT)
  
  man.err.frame.gr <- man.err.frame[,1:2] ; colnames(man.err.frame.gr) <- c('seqnames', 'start')
  man.err.frame.gr$end <- man.err.frame.gr$start + 1
  man.err.frame.gr <- GRanges(man.err.frame.gr)
  
  chr.lengths <- sapply(chrs, function(x) max(vcfs.filtered[[1]]$POS[vcfs.filtered[[1]]$CHROM == x]))
  x <- GRanges(seqnames = chrs, ranges = IRanges(start = 1, width = chr.lengths))
  x <- as.data.frame(slidingWindows(x, width = args$window.size, step = args$window.size))[,3:5]
  x.gr <- GRanges(x)
  
  x$index <- 1:nrow(x) * args$window.size - args$window.size / 2
  x$range <- paste0(x$seqnames, ':', x$start, '-', x$end)
  
  hits <- findOverlaps(x.gr, man.err.frame.gr, select = 'all')
  hits <- split(hits@to, hits@from)
  
  if (length(father) & length(mother)){
    x$trio <- 0
    x$trio[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man.err.frame$trio[hit] == 2)))
  }
  if (length(father)){
    x$fat <- 0
    x$fat[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man.err.frame$fat[hit] == 2)))
  }
  if (length(mother)){
    x$mot <- 0
    x$mot[as.numeric(names(hits))] <- sapply(hits, function(hit) length(which(man.err.frame$mot[hit] == 2)))
  }
  
  me.plot <- plot_ly(x, x =~index, y = 0, height = 210 * n.rel,
                     line = list(color = colors[1], width = 0),
                     name = 'trio errors', type = 'scatter', mode = 'lines', hoverinfo = 'none')
  
  if (length(father) & length(mother)){
    me.plot <- me.plot %>% add_trace(x =~index, y =~trio, text =~range,
                                     line = list(color = colors[1], width = args$dot.factor),
                                     name = 'trio errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')
    
    me.plot <- me.plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$trio,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[1], opacity = .2)
  }
  
  if (length(father)){
    me.plot <- me.plot %>% add_trace(x =~index, y =~fat, text =~range,
                                     line = list(color = colors[2], width = args$dot.factor, dash = 'dot'),
                                     name = 'father errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')
    
    me.plot <- me.plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$fat,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[2], opacity = .2)
  }
  
  if (length(mother)){
    me.plot <- me.plot %>% add_trace(x =~index, y =~mot, text =~range,
                                     line = list(color = colors[3], width = args$dot.factor, dash = 'dot'),
                                     name = 'mother errors', type = 'scatter', mode = 'lines', hoverinfo = 'name+y+text')
    
    me.plot <- me.plot %>% add_polygons(x = c(1, x$index, last(x$index)), y = c(0, x$mot,0), inherit = F,
                                        line=list(width=0), fillcolor = colors[3], opacity = .2)
  }
  
  ylim = c(0, max(x$trio, x$fat, x$mot, 50, na.rm = T))
  
  me.plot <- me.plot %>% layout(xaxis = list(title = list(text=args$samples.out[args$sample.ids == child], standoff = 5),
                                             showticklabels = F, zeroline = F, showgrid = F),
                                showlegend = F, yaxis = list(title = 'mendelian error count', zeroline = F, range = ylim))
  
  chr.lengths <- sapply(chrs, function(chr) length(which(x$seqnames == chr))) * args$window.size
  chr.cs <- c(0, sapply(chrs, function(chr) last(which(x$seqnames == chr))) * args$window.size)
  names(chr.cs) <- c(chrs, 'end')
  
  me.plot <- add.chr.lines(me.plot, chr.cs, ylim)
  if (length(args$regions)){
    for (region in args$regions){
      me.plot <- mark.region(me.plot, chr.cs, ylim, region, chr.lengths)
    }
  }
  
  return(me.plot)
}

# -----
# BAF
# -----

get.region.baf <- function(){
  chr.lengths <- sapply(chrs, function(x) max(vcfs.filtered[[1]]$POS[vcfs.filtered[[1]]$CHROM == x]))
  bafs <- list()
  for (region in args$regions){
    c <- strsplit(region, ':')[[1]][1]
    st <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][1]) - args$regions.flanking.size
    st <- max(1, st)
    en <- as.numeric(strsplit(strsplit(region, ':')[[1]][2], '-')[[1]][2]) + args$regions.flanking.size
    en <- min(chr.lengths[c], en)
    
    m <- vcfs.filtered[[1]]$CHROM == c & vcfs.filtered[[1]]$POS > st & vcfs.filtered[[1]]$POS < en
    for (s in args$samples.no.u){
      dat <- data.frame(paste0(vcfs.filtered[[s]]$CHROM[m], ':', vcfs.filtered[[s]]$POS.out[m]),
                        vcfs.filtered[[s]]$POS[m], vcfs.filtered[[s]]$AF[m] * 100)
      colnames(dat) <- c('id', 'index', 'AF')
      dat <- dat[!is.na(dat$AF),]
      
      baf <- plot_ly(dat, x =~index, y =~AF, text =~id, height = 200 * ceiling(length(args$samples.no.u) / 4),
                     marker = list(color = colors[1], alpha = .5,
                                   size = args$dot.factor * 2, line = list(color = colors[1], alpha = .5)),
                     type = 'scatter', mode = 'markers', hoverinfo = 'y+text')
      
      yaxis = list(title = 'BAF (%)', zeroline = F, range = c(-15,115), fixedrange = T)
      if (which(args$samples.no.u == s) %% 4 != 1) {
        yaxis = list(title = '', showticklabels = F, zeroline = F, range = c(-15,115), fixedrange = T)
      }
      baf <- baf %>% layout(xaxis = list(title = list(text=args$samples.out[args$sample.ids == s], standoff = 1),
                                         showticklabels = F, zeroline = F, showgrid = F),
                            showlegend = F, yaxis = yaxis)
      
      tmp <- c(1) ; names(tmp) <- c
      
      baf <- mark.region(baf, tmp, c(-5,105), region, chr.lengths, plot.flanks = F)
      
      region.out <- paste0(c, ':', scales::comma(st, accuracy = 1), ':', scales::comma(en, accuracy = 1))
      
      bafs[[region.out]][[s]] <- baf
    }
  }
  return(bafs)
}

get.genome.baf <- function(s){
  chr.lengths <- sapply(chrs, function(x) max(vcfs.filtered[[1]]$POS[vcfs.filtered[[1]]$CHROM == x]))
  bafs <- list()
  for (chr in chrs){
    chr.m <- vcfs.filtered[[s]]$CHROM == chr
    dat <- data.frame(paste0(vcfs.filtered[[s]]$CHROM[chr.m], ':', vcfs.filtered[[s]]$POS.out[chr.m]),
                      vcfs.filtered[[s]]$POS[chr.m], vcfs.filtered[[s]]$AF[chr.m] * 100)
    colnames(dat) <- c('id', 'index', 'AF')
    dat <- dat[!is.na(dat$AF),]
    
    if(args$limit.baf.to.P) dat <- dat[sort(sample(nrow(dat),round(nrow(dat) * args$value.of.P))),]
    
    ## raw data
    
    baf <- plot_ly(dat, x = ~index, y = ~AF, text =~id,
                   marker = list(color = colors[1], alpha = .5, size = args$dot.factor * 2,
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
          baf <- mark.region(baf, tmp, c(-5, 130), region, chr.lengths)
        }
      }
    }
    
    ## add cytobands
    
    if (length(args$cytoband.file)){
      baf <- add.cytoband(baf, chr, 120)
    } else {
      baf <- add.locus.bar(baf, chr, chr.lengths[[chr]], 120)
    }
    
    bafs[[chr]] <- baf
  }
  return(bafs)
}

# -----
# Parent mapping
# -----

get.pm <- function(child, father, mother){
  vcf.child <- vcfs.filtered[[child]]
  
  annot.list <- c('father 0/1 --- mother 0/0|1/1 --- child 0/1',
                  'father 0/1 --- mother 0/0|1/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/0|1/1')
  
  if (length(father) & length(mother)){
    vcf.fat <- vcfs.filtered[[father]]
    vcf.mot <- vcfs.filtered[[mother]]
    m1 <- vcf.fat$GT == '0/1' & vcf.mot$GT %in% c('0/0', '1/1')
    m2 <- vcf.mot$GT == '0/1' & vcf.fat$GT %in% c('0/0', '1/1')
  }
  if (length(father) & !length(mother)){
    vcf.fat <- vcfs.filtered[[father]]
    m1 <- vcf.fat$GT == '0/1'
    m2 <- vcf.fat$GT %in% c('0/0', '1/1')
    
    annot.list <- c('father 0/1 --- child 0/1',
                    'father 0/1 --- child 0/0|1/1',
                    'father 0/0|1/1 --- child 0/1',
                    'father 0/0|1/1 --- child 0/0|1/1')
  }
  if (!length(father) & length(mother)){
    vcf.mot <- vcfs.filtered[[mother]]
    m1 <- vcf.mot$GT %in% c('0/0', '1/1')
    m2 <- vcf.mot$GT == '0/1'
    
    annot.list <- c('mother 0/0|1/1 --- child 0/1',
                    'mother 0/0|1/1 --- child 0/0|1/1',
                    'mother 0/1 --- child 0/1',
                    'mother 0/1 --- child 0/0|1/1')
  }
  
  vcf.child$tracks[m1][vcf.child$GT[m1] == '0/1'] <- 5
  vcf.child$tracks[m1][vcf.child$GT[m1] %in% c('0/0', '1/1')] <- 4
  
  vcf.child$tracks[m2][vcf.child$GT[m2] == '0/1'] <- 2
  vcf.child$tracks[m2][vcf.child$GT[m2] %in% c('0/0', '1/1')] <- 1
  
  vcf.child$col <- NA
  vcf.child$col[which(vcf.child$tracks %in% 4:5)] <- colors[1]
  vcf.child$col[which(vcf.child$tracks %in% 1:2)] <- colors[2]
  
  chr.lengths <- sapply(chrs, function(x) max(vcfs.filtered[[1]]$POS[vcfs.filtered[[1]]$CHROM == x]))
  upds <- list()
  for (chr in chrs){
    chr.m <- vcfs.filtered[[1]]$CHROM == chr
    dat <- data.frame(paste0(vcf.child$CHROM[chr.m], ':', vcf.child$POS.out[chr.m]),
                      vcf.child$POS[chr.m], vcf.child$tracks[chr.m], vcf.child$col[chr.m])
    colnames(dat) <- c('id', 'index', 'track', 'col')
    dat <- dat[!is.na(dat$track),]
    
    if(args$limit.pm.to.P) dat <- dat[sort(sample(nrow(dat),round(nrow(dat) * args$value.of.P))),]
    
    ## raw data
    
    upd <- plot_ly(dat, x = ~index, y = ~track, text =~id,
                   marker = list(color =~ col, alpha = .5, size = args$dot.factor * 3,
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
          upd <- mark.region(upd, tmp, c(.5,5.5), region, chr.lengths)
        }
      }
    }
    
    ## add cytobands
    
    if (length(args$cytoband.file)){
      upd <- add.cytoband(upd, chr, 3)
    } else {
      upd <- add.locus.bar(upd, chr, chr.lengths[[chr]], 3)
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
                        annotations = list(list(x = chr.lengths[[chr]] / 2, y = 5, font = list(color = colors[1]),
                                                text = annot.list[1], showarrow = F),
                                           list(x = chr.lengths[[chr]] / 2, y = 4, font = list(color = colors[1]),
                                                text = annot.list[2], showarrow = F),
                                           list(x = chr.lengths[[chr]] / 2, y = 2, font = list(color = colors[2]),
                                                text = annot.list[3], showarrow = F),
                                           list(x = chr.lengths[[chr]] / 2, y = 1, font = list(color = colors[2]),
                                                text = annot.list[4], showarrow = F)))
  
  if (length(args$cytoband.file)){
    upd <- add.cytoband(upd, chr, 3)
  } else {
    upd <- add.locus.bar(upd, chr, chr.lengths[[chr]], 3)
  }
  
  upds[[24]] <- upd
  return(upds)
}



# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                       Functions: writing to HTML output
# ---------------------------------------------------------------------------------------------------------------------------------------------------

get.html.list <- function(){
  cat('Generating visualizations, working ...\n')
  
  html.list <- list()
  append.list <- function(list, x){
    l <- list
    l[[length(l) + 1]] <- x
    return(l)
  }
  
  add.main.header <- function(html.list, h){
    html.list <- append.list(html.list, tags$hr())
    html.list <- append.list(html.list, tags$hr())
    html.list <- append.list(html.list, tags$h2(h))
    html.list <- append.list(html.list, tags$hr())
    html.list <- append.list(html.list, tags$hr())
    return(html.list)
  }
  
  get.empty <- function(){
    p <- plot_ly(x = 0, y = 0, name = NULL, type = 'scatter', mode = 'markers',
                 marker = list(color = 'white', size = .01), hoverinfo='skip')
    p <- p %>% layout(xaxis = list(title = '', showticklabels = F, zeroline = F, showgrid = F, fixedrange = T),
                      yaxis = list(title = '', showticklabels = F, zeroline = F, showgrid = F, fixedrange = T),
                      showlegend = F)
    return(p)
  }
  
  do.subplot <- function(plot.list, ncol = 1, panning = .03, margin = .02, overridehovermode = NULL){
    nrow <- ceiling(length(plot.list) / ncol)
    
    plot.list.ap <- lapply(1:(ncol + 2), function(x) get.empty())
    for (i in 1:nrow){
      plot.list.ap <- c(plot.list.ap, lapply(1, function(x) get.empty()))
      s <- (1 + (i - 1) * ncol)
      e <- (ncol + (i - 1) * ncol)
      real.e <- length(plot.list)
      plot.list.ap <- c(plot.list.ap, plot.list[s:min(real.e, e)])
      plot.list.ap <- c(plot.list.ap, lapply(1, function(x) get.empty()))
    }
    plot.list.ap <- c(plot.list.ap, lapply((length(plot.list.ap)+1):((ncol+2)*(nrow+2)), function(x) get.empty()))
    
    heights <- c(panning, rep((1 - 2*panning) / nrow, nrow), panning)
    widths <- c(panning, rep((1 - 2*panning) / ncol, ncol), panning)
    this.subplot <- subplot(plot.list.ap, nrows=nrow+2, margin=margin, titleY=T, titleX=T,
                            heights=heights, widths = widths)
    if (!is.null(overridehovermode)) this.subplot$x$layout$hovermode <- overridehovermode
    return(this.subplot)
  }
  
  get.ado <- function(vcf.list, mother, father, child){
    ado.set <- vcf.list[[1]]$ID[which((vcf.list[[mother]]$GT == '0/0' & vcf.list[[father]]$GT == '1/1') | 
                                        (vcf.list[[father]]$GT == '0/0' & vcf.list[[mother]]$GT == '1/1'))]
    ado.table <- table(vcf.list[[child]]$GT[which(vcf.list[[child]]$ID %in% ado.set)])
    ado = round(sum(ado.table[which(names(ado.table) %in% c('0/0', '1/1'))]) /
                  sum(ado.table[which(names(ado.table) %in% c('0/0', '0/1', '1/1'))]) * 100, 2)
    return(paste0(ado, '%'))
  }
  
  get.adi <- function(vcf.list, mother, father, child){
    adi.set <- vcf.list[[1]]$ID[which((vcf.list[[mother]]$GT == '1/1' & vcf.list[[father]]$GT == '1/1'))]
    adi.table <- table(vcf.list[[child]]$GT[which(vcf.list[[child]]$ID %in% adi.set)])
    adi = round(sum(adi.table[which(names(adi.table) %in% c('0/1'))]) /
                  sum(adi.table[which(names(adi.table) %in% c('0/0', '0/1', '1/1'))]) * 100, 2)
    return(paste0(adi, '%'))
  }
  
  ## info
  
  if (length(args$info)){
    html.list <- add.main.header(html.list, "Family/disease information")
    for (part in args$info){
      html.list <- append.list(html.list, tags$p(part))
    }
  }
  
  ## pedigree
  
  if (length(args$samples.no.u) > 1){
    cat('  ... at pedigree \n')
    
    html.list <- add.main.header(html.list, "Family tree")
    
    write.pedigree(paste0(args$out.bs, 'ped.tree.png'))
    x <- htmltools::img(src = image_uri(paste0(args$out.bs, 'ped.tree.png')),
                        style = paste0('height:',5*100,'px;width:',log(length(args$sample.ids)) * 4 * 100,'px'))
    invisible(file.remove(paste0(args$out.bs, 'ped.tree.png')))
    html.list <- append.list(html.list, x)
  }
  
  # raw
  
  html.list <- add.main.header(html.list, "Filter 0: single nucleotide variants")
  
  ## variant statistics
  
  html.list <- append.list(html.list, tags$h3("Variant statistics"))
  
  add.tot.number.of.variants <- function(html.list, vcf.list){
    nvars <- c()
    for (s in args$samples.no.u){
      nvars <- c(nvars, paste0(s, ': ', scales::comma(nrow(vcf.list[[s]][vcf.list[[s]]$GT %in% c('0/0', '0/1', '1/1'),]), accuracy = 1)))
    }
    html.list <- append.list(html.list, tags$p(paste0('° overall; ', paste0(nvars, collapse = ' | '))))
    
    get.vars.in.region <- function(vcf.list, sample, region){
      r.split <- strsplit(region, ':')[[1]]
      c = r.split[1]
      s <- as.numeric(strsplit(r.split[2],'-')[[1]][1])
      e <- as.numeric(strsplit(r.split[2],'-')[[1]][2])
      x <- vcf.list[[sample]]
      n1 <- length(which(x$CHROM == c & x$POS >= s & x$POS <= e & x$GT %in% c('0/0', '0/1', '1/1')))
      s.flank <- s - args$regions.flanking.size
      e.flank <- e + args$regions.flanking.size
      n2 <- length(which(x$CHROM == c & x$POS >= s.flank & x$POS <= s & x$GT %in% c('0/0', '0/1', '1/1')))
      n3 <- length(which(x$CHROM == c & x$POS >= e & x$POS <= e.flank & x$GT %in% c('0/0', '0/1', '1/1')))
      return(list(n1 = n1, n2 = n2, n3 = n3))
    }
    
    for (region in args$regions){
      nvars <- c()
      for (s in args$samples.no.u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get.vars.in.region(vcf.list, s, region)$n1, accuracy = 1)))
      }
      html.list <- append.list(html.list, tags$p(paste0('° in ', region, '; ', paste0(nvars, collapse = ' | '))))
      
      nvars <- c()
      for (s in args$samples.no.u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get.vars.in.region(vcf.list, s, region)$n2, accuracy = 1)))
      }
      html.list <- append.list(html.list, tags$p(paste0('° in ', region, ' (left flank); ', paste0(nvars, collapse = ' | '))))
      
      nvars <- c()
      for (s in args$samples.no.u){
        nvars <- c(nvars, paste0(s, ': ', scales::comma(get.vars.in.region(vcf.list, s, region)$n3, accuracy = 1)))
      }
      html.list <- append.list(html.list, tags$p(paste0('° in ', region, ' (right flank); ', paste0(nvars, collapse = ' | '))))
    }
    return(html.list)
  }
  
  cat('  ... at total number of variants (raw) \n')
  
  html.list <- append.list(html.list, tags$h4("Total number of variants"))
  html.list <- add.tot.number.of.variants(html.list, vcfs)
  
  cat('  ... at number of variants table (raw) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants table"))
  html.list <- append.list(html.list, get.plotly.table(vcfs))
  
  if (length(args$samples.no.u) > 1){
    html.list <- append.list(html.list, tags$h4("Allelic drop-out (ADO) & allelic drop-in (ADI)"))
    for (child in args$samples.no.u){
      father <- args$father.ids[args$sample.ids == child]
      mother <- args$mother.ids[args$sample.ids == child]
      
      has.father <- !is.na(father) & !(father %in% args$samples.u)
      has.mother <- !is.na(mother) & !(mother %in% args$samples.u)
      
      html.list <- append.list(html.list, tags$h5(child))
      
      if (has.mother & has.father){
        html.list <- append.list(html.list, tags$p(paste0(
          'ADO = ', get.ado(vcfs, mother, father, child))))
        html.list <- append.list(html.list, tags$p(paste0(
          'ADI = ', get.adi(vcfs, mother, father, child))))
      } else {
        html.list <- append.list(html.list, tags$p('no two parents provided'))
      }
    }
  }
  
  ## var depth
  
  cat('  ... at variant depth (raw) \n')
  
  html.list <- append.list(html.list, tags$h4("Variant depth"))
  html.list <- append.list(html.list, do.subplot(get.var.depth.hist(vcfs), ncol = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (raw) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants profile"))
  html.list <- append.list(html.list, do.subplot(list(get.var.dis.fig(vcfs))))
  
  ## copy number
  
  cat('  ... at vcf-based copy number (raw) \n')
  
  html.list <- append.list(html.list, tags$h3("Vcf-based copy number (bam-based verification recommended)"))
  html.list <- append.list(html.list, do.subplot(get.cn.fig()))
  
  # filtered 1
  
  html.list <- add.main.header(html.list, "Filter 1: filter 0, --dp.hard.limit, --af.hard.limit and --dp.soft.limit")
  
  ## variant statistics
  
  html.list <- append.list(html.list, tags$h3("Variant statistics"))
  
  cat('  ... at total number of variants (filter 1) \n')
  
  html.list <- append.list(html.list, tags$h4("Total number of variants"))
  html.list <- add.tot.number.of.variants(html.list, vcfs.filtered)
  
  cat('  ... at number of variants table (filter 1) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants table"))
  html.list <- append.list(html.list, get.plotly.table(vcfs.filtered))
  
  n.rel <- 0
  if (length(args$samples.no.u) > 1){
    html.list <- append.list(html.list, tags$h4("Allelic drop-out (ADO) & allelic drop-in (ADI)"))
    for (child in args$samples.no.u){
      father <- args$father.ids[args$sample.ids == child]
      mother <- args$mother.ids[args$sample.ids == child]
      
      has.father <- !is.na(father) & !(father %in% args$samples.u)
      has.mother <- !is.na(mother) & !(mother %in% args$samples.u)
      
      html.list <- append.list(html.list, tags$h5(child))
      
      if (has.mother | has.father) n.rel <- n.rel + 1
      
      if (has.mother & has.father){
        html.list <- append.list(html.list, tags$p(paste0(
          'ADO = ', get.ado(vcfs.filtered, mother, father, child))))
        html.list <- append.list(html.list, tags$p(paste0(
          'ADI = ', get.adi(vcfs.filtered, mother, father, child))))
      } else {
        html.list <- append.list(html.list, tags$p('no two parents provided'))
      }
    }
  }
  
  ## var depth
  
  cat('  ... at variant depth (filter 1) \n')
  
  html.list <- append.list(html.list, tags$h4("Variant depth"))
  html.list <- append.list(html.list, do.subplot(get.var.depth.hist(vcfs.filtered), ncol = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (filter 1) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants profile"))
  html.list <- append.list(html.list, do.subplot(list(get.var.dis.fig(vcfs.filtered))))
  
  ## BAF
  
  if (length(args$regions)){
    cat('  ... at B-allele frequency (regions; filter 1) \n')
    html.list <- append.list(html.list, tags$h3("B-allele frequency (BAF), region(s) of interest"))
    regions.baf <- get.region.baf()
    for (region in names(regions.baf)){
      html.list <- append.list(html.list, tags$h4(region))
      html.list <- append.list(html.list, do.subplot(regions.baf[[region]], ncol = 4))
    }
  }
  
  ## BAF detail
  
  if (length(args$baf.ids)){
    cat('  ... at B-allele frequency (genome-wide; filter 1) \n')
    if (args$limit.baf.to.P){
      html.list <- append.list(html.list,
                               tags$h3(paste0("B-allele frequency (BAF), genome-wide, only ", args$value.of.P * 100,"% of data")))
    } else {
      html.list <- append.list(html.list, tags$h3("B-allele frequency (BAF), genome-wide"))
    }
    for (s in args$baf.ids){
      html.list <- append.list(html.list, tags$h4(args$samples.out[args$sample.ids == s]))
      html.list <- append.list(html.list, do.subplot(get.genome.baf(s), ncol = 2, panning = .015, margin = .012))
    }
  }
  
  ## Mendelian errors
  
  if (length(args$sample.ids) > 1){
    
    men.err.plots <- list()
    for (s in args$samples.no.u){
      father <- args$father.ids[args$sample.ids == s]
      mother <- args$mother.ids[args$sample.ids == s]
      
      has.father <- !is.na(father) & !(father %in% args$samples.u)
      has.mother <- !is.na(mother) & !(mother %in% args$samples.u)
      
      if (length(father[has.father]) | length(mother[has.mother])){
        men.err.plots[[s]] <- get.men.err.fig(s, father[has.father], mother[has.mother], n.rel)
      }
    }
    if (length(men.err.plots)){
      cat('  ... at mendelian errors (filter 1) \n')
      
      html.list <- append.list(html.list, tags$h3("Mendelian errors"))
      html.list <- append.list(html.list, do.subplot(men.err.plots, ncol = 1))
    }
  }
  
  ## Parent mapping
  
  if (length(args$sample.ids) > 1){
    cat('  ... at parent mapping (filter 1) \n')
    if (args$limit.pm.to.P){
      html.list <- append.list(html.list, tags$h3(paste0("Parent mapping, only", args$value.of.P * 100,"% of data")))
    } else {
      html.list <- append.list(html.list, tags$h3("Parent mapping"))
    }
    for (s in args$samples.no.u){
      father <- args$father.ids[args$sample.ids == s]
      mother <- args$mother.ids[args$sample.ids == s]
      
      has.father <- !is.na(father) & !(father %in% args$samples.u)
      has.mother <- !is.na(mother) & !(mother %in% args$samples.u)
      
      if (length(father[has.father]) | length(mother[has.mother])){
        html.list <- append.list(html.list, tags$h4(args$samples.out[args$sample.ids == s]))
        html.list <- append.list(html.list, do.subplot(get.pm(s, father[has.father], mother[has.mother]), ncol = 4))
      }
    }
  }
  
  # filtered 2
  
  html.list <- add.main.header(html.list, "Filter 2: filter 0, filter 1, --keep.informative.ids and --keep.hetero.ids")
  
  ## variant statistics
  
  html.list <- append.list(html.list, tags$h3("Variant statistics"))
  
  cat('  ... at total number of variants (filter 2) \n')
  
  html.list <- append.list(html.list, tags$h4("Total number of variants"))
  html.list <- add.tot.number.of.variants(html.list, vcfs.filtered2)
  
  cat('  ... at number of variants table (filter 2) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants table"))
  html.list <- append.list(html.list, get.plotly.table(vcfs.filtered2))
  
  ## var depth
  
  cat('  ... at variant depth (filter 2) \n')
  
  html.list <- append.list(html.list, tags$h4("Variant depth"))
  html.list <- append.list(html.list, do.subplot(get.var.depth.hist(vcfs.filtered2), ncol = 4))
  
  ## number of variants
  
  cat('  ... at number of variants profile (filter 2) \n')
  
  html.list <- append.list(html.list, tags$h4("Number of variants profile"))
  
  html.list <- append.list(html.list, do.subplot(list(get.var.dis.fig(vcfs.filtered2))))
  
  ## Merlin
  
  if (args$run.merlin){
    
    cat('  ... at Merlin (filter 2) \n')
    
    html.list <- append.list(html.list, tags$h3("Haplotyping by Merlin"))
    html.list <- append.list(html.list, do.subplot(get.haplo.profiles(), ncol = 2, panning = .015, margin = .007,
                                                   overridehovermode = 'X unified'))
    
    if (args$concordance.table){
      html.list <- append.list(html.list, tags$h3("Haplotyping by Merlin: strand concordance"))
      html.list <- append.list(html.list, get.haplo.tables())
    }
  }
  
  return(html.list)
}

transform.to.selfcontained <- function(){
  cat('Converting to self-contained HTML ...\n')
  if (!htmlwidgets:::pandoc_available()) {
    cat(paste0("WARNING: Saving a widget with --self.contained T requires pandoc. For details see: https://github.com/rstudio/rmarkdown/blob/master/PANDOC.md\n",
               "Self-contained HTML will not be created.\n"))
  }
  else {
    htmlwidgets:::find_pandoc()
    system(paste0('touch ', args$out.bs, 'nocss.css'))
    system(paste0('cd "', normalizePath(args$out.dir),
                  '" && ', htmlwidgets:::pandoc(), 
                  ' ', args$out.bs, 'output.html --output ', args$out.bs, 'output.sc.html --from markdown --self-contained --metadata pagetitle=', args$fam.id,' --css ',
                  args$out.bs, 'nocss.css'), ignore.stderr = T)
    unlink(paste0(args$out.bs, 'nocss.css'), recursive = T)
    if (file.exists(paste0(args$out.bs, 'output.sc.html'))){
      unlink(paste0(args$out.bs, 'output_files'), recursive = T)
      unlink(paste0(args$out.bs, 'output.html'), recursive = T)
      tmp = file.rename(paste0(args$out.bs, 'output.sc.html'), paste0(args$out.bs, 'output.html'))
    } else {
      cat('WARNING: pandoc error encountered, self-contained HTML could not be created.\n')
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------------------------------------
#                                                                    Main
# ---------------------------------------------------------------------------------------------------------------------------------------------------

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
suppressMessages(library('knitr'))


# -----
# Parameters
# -----


args <- list(
  ## mandatory arguments
  vcf.file=c(),
  sample.ids=c(),
  
  ## important optional arguments
  father.ids=c(),
  mother.ids=c(),
  genders=c(),
  run.merlin=T,
  run.visualization = F,
  cytoband.file=c(),
  
  ## variant inclusion arguments: filter 1
  dp.hard.limit.ids=c(),
  dp.hard.limit=10,
  af.hard.limit.ids=c(),
  af.hard.limit=0,
  dp.soft.limit.ids=c(),
  dp.soft.limit=10,
  
  ## variant inclusion arguments: filter 2
  keep.informative.ids=c(),
  keep.hetero.ids=c(),
  
  ## sample/disease annotation
  regions=c(),
  reference.ids=c(),
  carrier.ids=c(),
  affected.ids=c(),
  nonaffected.ids=c(),
  info=c(),
  
  ## BAF profiles
  baf.ids=c(),
  
  ## merlin profiles
  merlin.model='best',
  min.seg.var=5,
  min.seg.var.X=15,
  window.size.voting=10000000,
  window.size.voting.X=c(),
  keep.chromosomes.only=T,
  keep.regions.only=F,
  concordance.table=T,
  
  ## remaining features
  out.dir=c('./'),
  settings.file = '/home/jovyan/work/hopla/data/Proband_16_09932_B.txt',  
  fam.id='hopla',
  X.cutoff=1.5,
  Y.cutoff=.6,
  window.size=1000000,
  regions.flanking.size=2000000,
  limit.baf.to.P=F,
  limit.pm.to.P=F,
  value.of.P=.25,
  color.palette='Paired',
  dot.factor=2,
  self.contained=F,
  cairo=F
)

args <- get.file.args(args$settings.file)
args <- post.process.args(args)

# -----
# Overall options & constants
# -----


options(scipen=999)
if (args$cairo) options(bitmaptype='cairo')

colors = brewer.pal(brewer.pal.info[args$color.palette,]$maxcolors, args$color.palette)
chrs <- paste0('chr', c(1:22, 'X'))

# -----
# Initialize
# -----

dir.create(args$out.dir, showWarnings = F, recursive = T)
args$out.dir <- normalizePath(args$out.dir)

args$fam.id <- gsub("[[:punct:]]", ".", args$fam.id)
args$out.bs <- paste0(args$out.dir, '/', args$fam.id, '-')
args$merlin.dir <- paste0(args$out.bs, 'merlin/')
if (length(args$cytoband.file)) cytobands <- get.cytobands(args$cytoband.file)

return(args)


# -----
# Vcf loading & parsing
# -----

vcfs <- load.samples(args)

if (any(is.na(args$genders))) args$genders <- predict.genders(args$genders)

vcfs <- lapply(vcfs, function(x) x[vcfs[[1]]$CHROM %in% chrs,])
for (s in args$sample.ids[args$genders == 'M']){
  if (s %in% args$samples.u) next
  vcfs[[s]]$GT[which(vcfs[[s]]$CHROM == 'chrX' & vcfs[[s]]$GT == '0/1')] <- './.'
}

args <- add.ghosts(args)

vcfs.filtered <- apply.filter1(vcfs)
vcfs.filtered2 <- apply.filter2(vcfs.filtered)


# -----
# Merlin
# -----

if (args$run.merlin){
  map.list <- run.merlin(args, vcfs.filtered2)
  
  merlin.out <- parse.merlin(args)
  parsed.geno <- merlin.out$parsed.geno
  parsed.flow <- merlin.out$parsed.flow
  map.list <- merlin.out$map.list
  rm(merlin.out)
  
  parsed.geno <- update.geno(parsed.geno)
  
  corrected.data <- correct.profiles(args, parsed.flow)
  parsed.flow = corrected.data$parsed.flow
  is.corrected = corrected.data$is.corrected
  rm(corrected.data)
  
  letters <- unique(unlist(strsplit(unique(unlist(parsed.flow)), '')))
  letters <- letters[!(letters %in% c('|', 'X'))]
  letter.colors <- c(colors[1:length(letters)], 'white')
  names(letter.colors) <- c(letters, 'X')
} else{
  letters <- c('A', 'B', 'C', 'D') # no merlin -> four letters (ie, colors) required
}


# -----
# Write output (html)
# -----

if (args$run.visualization){
  html.list <- get.html.list()
  cat('Saving to HTML ...\n')
  save_html(html.list, file = paste0(args$out.bs, 'output.html'), libdir = paste0(args$out.bs, 'output_files'))
  if (args$self.contained) transform.to.selfcontained()
}


# -----
# Write output (csv)
# -----

# add new columns about filtering and save
for (i in 1:length(vcfs)){
  vcfs[[i]]$On_filter1 <- ifelse(vcfs[[i]][, 'ID'] %in% vcfs.filtered[[i]][, 'ID'], 1, 0)
  vcfs[[i]]$On_filter2 <- ifelse(vcfs[[i]][, 'ID'] %in% vcfs.filtered2[[i]][, 'ID'], 1, 0)
}

write.csv(vcfs, paste0(args$out.dir, '/vcfs.csv'))

# saving parsed.flow into csv

combined_flow <- data.frame(matrix(nrow = 0, ncol = dim(parsed.flow[[1]])[2]+1))
for (i in 1:length(parsed.flow)){
  parsed.flow[[i]] <- cbind(parsed.flow[[i]], paste0("chr", i))
  combined_flow <- rbind(combined_flow, parsed.flow[[i]])
  
}

write.csv(combined_flow, file.path(args$out.dir, 'parsed_flow.csv'), row.names=FALSE)

# saving parsed.geno into csv

combined_geno <- data.frame(matrix(nrow = 0, ncol = dim(parsed.geno[[1]])[2]+1))
for (i in 1:length(parsed.geno)){
  parsed.geno[[i]] <- cbind(parsed.geno[[i]], paste0("chr", i))
  combined_geno <- rbind(combined_geno, parsed.geno[[i]])
  
}

write.csv(combined_geno, file.path(args$out.dir, 'parsed_geno.csv'), row.names=FALSE)




