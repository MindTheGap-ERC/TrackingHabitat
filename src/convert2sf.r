# List only .shp files
quadNames <- list.files("data", pattern = "\\.shp$")

year_lookup <- data.frame(
  filename = c("export_shape_vintage_out_joulters", "export_shape_modern_out_joulters"),
  year = c(1949, 2019)  # Replace these years with your actual years
)
# Initialize an empty list to store the processed shapefiles
shape_list <- list()
counter <- 1

# now we'll loop through the quadrat folders to download the data
for (filename in year_lookup$filename) {
  # Read shapefile
  shapeNow <- sf::st_read(dsn = "data", 
                         layer = filename,
                         quiet = TRUE)
  
  cat("\nProcessing file:", filename, "\n")
  cat("Columns:", names(shapeNow), "\n")
  cat("Number of rows:", nrow(shapeNow), "\n")
  # Standardize columns
  shapeNow <- sf::st_sf(
    geometry = sf::st_geometry(shapeNow),
    Site = "Joulters",
    Facies = shapeNow$Class_name, 
    Quad = ifelse(grepl("vintage", filename), "vintage", "modern"),
    Year = year_lookup$year[match(filename, year_lookup$filename)],
    type = "polygon"
  )
  
  # Store in list
  shape_list[[counter]] <- shapeNow
  counter <- counter + 1
}

# Combine all shapefiles
dat <- do.call(rbind, shape_list)

# Create results directory if it doesn't exist
dir.create("results", showWarnings = FALSE)

# Save results in multiple formats
# As shapefile
sf::st_write(dat, "results/combined_shapes.shp", append=FALSE)

# As R data file (preserves all data types)
saveRDS(dat, "results/combined_shapes.rds")

# As CSV (without spatial information)
write.csv(sf::st_drop_geometry(dat), "results/combined_shapes.csv", row.names = FALSE)
# Now, all of the spatial data are in one sf data frame with consistent columns!