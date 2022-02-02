cmd.args <- commandArgs(trailingOnly=T)

flow1 <- read.csv(cmd.args[1], header = T, stringsAsFactors = F, sep = '\t')
flow1$id <- paste0(flow1$chr, ':', flow1$pos)
flow2 <- read.csv(cmd.args[2], header = T, stringsAsFactors = F, sep = '\t')
flow2$id <- paste0(flow2$chr, ':', flow2$pos)

inter <- intersect(flow1$id, flow2$id)

flow1 <- flow1[flow1$id %in% inter, ]
flow2 <- flow2[flow2$id %in% inter, ]

last <- function(x) x[length(x)]
first <- function(x) x[1]

basenames <- as.character(sapply(cmd.args[1:2], function(x) last(strsplit(x, '/', fixed = T)[[1]])))
basenames <- as.character(sapply(basenames, function(x) first(strsplit(x, '-', fixed = T)[[1]])))

concorde <- function(x, y){
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

cat(paste0(basenames[1], '-1 vs ', basenames[2], '-1: ', concorde(flow1$flowA.hexcol, flow2$flowA.hexcol), '%\n'))
cat(paste0(basenames[1], '-1 vs ', basenames[2], '-2: ', concorde(flow1$flowA.hexcol, flow2$flowB.hexcol), '%\n'))
cat(paste0(basenames[1], '-2 vs ', basenames[2], '-1: ', concorde(flow1$flowB.hexcol, flow2$flowA.hexcol), '%\n'))
cat(paste0(basenames[1], '-2 vs ', basenames[2], '-2: ', concorde(flow1$flowB.hexcol, flow2$flowB.hexcol), '%\n'))
