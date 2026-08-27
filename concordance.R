#!/usr/bin/env Rscript

cmd.args <- commandArgs(trailingOnly = T)
if (any(cmd.args %in% c('-h', '--help'))){
  cat('Usage: concordance.R FLOW1 FLOW2 [RELATIVE]\n')
  quit(status = 0)
}
if (length(cmd.args) < 2 || length(cmd.args) > 3){
  cat('ERROR: expected two flow tables and optional T/TRUE relative comparison flag.\n', file = stderr())
  quit(status = 1)
}

flow1 <- data.table::fread(cmd.args[1])
flow2 <- data.table::fread(cmd.args[2])
flow1[, input.order := .I]
flows <- merge(
  flow1[, .(chr, pos, input.order, flowA.1 = flowA.hexcol, flowB.1 = flowB.hexcol)],
  flow2[, .(chr, pos, flowA.2 = flowA.hexcol, flowB.2 = flowB.hexcol)],
  by = c('chr', 'pos'),
  sort = F
)
data.table::setorder(flows, input.order)

basenames <- sub('-.*$', '', basename(cmd.args[1:2]))

#' Calculate concordance between two haplotype-colour vectors.
#' @param x,y Character vectors of equal length.
#' @return A numeric percentage.
concorde <- function(x, y){
  stopifnot(is.character(x), is.character(y), length(x) == length(y))
  negmask <- x == 'X' | y == 'X'
  x = x[!negmask]
  y = y[!negmask]
  
  if (length(cmd.args) > 2){
    if (cmd.args[3] == 'T' | cmd.args[3] == 'TRUE'){
      x = x == x[1]
      y = y == y[1]
    }
  }
  
  return(round(length(which(x == y)) / length(x) * 100, 2))
}

cat(paste0(basenames[1], '-1 vs ', basenames[2], '-1: ', concorde(flows$flowA.1, flows$flowA.2), '%\n'))
cat(paste0(basenames[1], '-1 vs ', basenames[2], '-2: ', concorde(flows$flowA.1, flows$flowB.2), '%\n'))
cat(paste0(basenames[1], '-2 vs ', basenames[2], '-1: ', concorde(flows$flowB.1, flows$flowA.2), '%\n'))
cat(paste0(basenames[1], '-2 vs ', basenames[2], '-2: ', concorde(flows$flowB.1, flows$flowB.2), '%\n'))
