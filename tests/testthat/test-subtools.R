flow_fixture <- function(path, reverse = FALSE) {
  value <- data.frame(
    chr = c("chr1", "chr2"),
    pos = 1:2,
    flowA.hexcol = c("red", "blue"),
    flowB.hexcol = c("green", "yellow")
  )
  if (reverse) value <- value[2:1, ]
  data.table::fwrite(value, path, sep = "\t")
}

test_that("concordance aligns shared markers", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second, reverse = TRUE)

  expect_equal(unname(hopla_concordance(first, second)), c(100, 0, 0, 100))
})

test_that("transform writes matching strand comparisons", {
  first <- tempfile(fileext = ".txt")
  second <- tempfile(fileext = ".txt")
  output <- tempfile(fileext = ".txt")
  flow_fixture(first)
  flow_fixture(second, reverse = TRUE)

  expect_identical(hopla_transform(first, second, 1, output), output)
  transformed <- data.table::fread(output)
  expect_true(all(transformed$flowA.hexcol))
  expect_true(all(transformed$flowB.hexcol))
})
