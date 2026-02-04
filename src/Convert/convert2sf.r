quadNames <- list.files("data", pattern = "\\.shp$")

year_lookup <- data.frame(
  filename = c("vintage", "modern_individual_Project"),
  year = c(1945L, 2019L)  
)
shape_list <- list()
counter <- 1

for (filename in year_lookup$filename) {
  shapeNow <- sf::st_read(dsn = "data", 
                         layer = filename,
                         quiet = TRUE)
  
  cat("\nProcessing file:", filename, "\n")
  cat("Columns:", names(shapeNow), "\n")
  cat("Number of rows:", nrow(shapeNow), "\n")
  shapeNow <- sf::st_sf(
    geometry = sf::st_geometry(shapeNow),
    Site = "Joulters",
    Facies = shapeNow$Class_name, 
    Quad = "Habitat",
    Year = year_lookup$year[match(filename, year_lookup$filename)],
    type = "polygon"
  )
  
  shape_list[[counter]] <- shapeNow
  counter <- counter + 1
}

dat <- do.call(rbind, shape_list)

dir.create("results", showWarnings = FALSE)

sf::st_write(dat, "results/combined_shapes.shp", append=FALSE)

saveRDS(dat, "results/combined_shapes.rds")

write.csv(sf::st_drop_geometry(dat), "results/combined_shapes.csv", row.names = FALSE)