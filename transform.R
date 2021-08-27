cmd.args <- commandArgs(trailingOnly=T)
#cmd.args <- c('/Users/leraman/phd/lisa/publication/ASPA_09-2020-01096/SingleParent/hopla-merlin/DNA052977-flow.txt',
#              '/Users/leraman/phd/lisa/publication/ASPA_09-2020-01096/SingleParent/hopla-merlin/DNA052979-flow.txt')

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

write.table(flow1, paste0(gsub('.txt', '', cmd.args[1]), '-relative.txt'), quote = F, sep = '\t', row.names = F)
