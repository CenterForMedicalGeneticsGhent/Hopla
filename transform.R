#!/usr/bin/env Rscript

cmd.args <- commandArgs(trailingOnly = T)
if (any(cmd.args %in% c('-h', '--help'))){
  cat('Usage: transform.R FLOW1 FLOW2 MODE\n  MODE: 1 compares matching strands; 2 compares crossed strands.\n')
  quit(status = 0)
}
if (length(cmd.args) != 3 || !(cmd.args[3] %in% c('1', '2'))){
  cat('ERROR: expected two flow tables and MODE 1 or 2.\n', file = stderr())
  quit(status = 1)
}

flow1 <- data.table::fread(cmd.args[1])
flow2 <- data.table::fread(cmd.args[2])
flow2.rows <- flow2[flow1, on = .(chr, pos), which = T]
matched <- !is.na(flow2.rows)
flow1 <- flow1[matched]
flow2 <- flow2[flow2.rows[matched]]

if (cmd.args[3] == '1'){
  x <- flow1$flowA.hexcol == flow2$flowA.hexcol
  y <- flow1$flowB.hexcol == flow2$flowB.hexcol
}

if (cmd.args[3] == '2'){
  x <- flow1$flowA.hexcol == flow2$flowB.hexcol
  y <- flow1$flowB.hexcol == flow2$flowA.hexcol
}

flow1$flowA.hexcol <- x
flow1$flowB.hexcol <- y

data.table::fwrite(flow1, paste0(tools::file_path_sans_ext(cmd.args[1]), '-relative.txt'), quote = F, sep = '\t')
