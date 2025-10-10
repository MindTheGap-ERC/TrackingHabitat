library(plantTracker)
library(sf)

dat <- readRDS("results/combined_shapes.rds")
print(sum(!st_is_valid(dat)))
dat <- st_make_valid(dat)
print(sum(!st_is_valid(dat)))
quadInv_list <- readRDS("results/quadInv_list.rds")

# First check the data format
plantTracker::checkDat(dat = dat, 
                      inv = quadInv_list,
                      species = "Facies",  # Add this column if not present
                      site = "Site", 
                      quad = "Quad",
                      year = "Year")


# Track changes between vintage and modern data
datTrackSpp <- plantTracker::trackSpp(
    dat = dat, 
    inv = quadInv_list,
    dorm = 1,            # Number of census intervals an individual can be dormant
    buff = .05,          # Buffer distance for matching locations
    buffGenet = .005,    # Buffer for determining genets
    clonal = data.frame(
        "Species" = c("Hardground","Island","Macroalgae","Microfilm","Reef","Sand","Seagrass","Slope"),  # Replace with your species
        "clonal" = c(FALSE)                  # TRUE if species is clonal
    ),
    aggByGenet = TRUE,   # Aggregate by genetic individual
    printMessages = TRUE # Set to TRUE for debugging
)

# Save tracking results
saveRDS(datTrackSpp, "results/tracked_species.rds")