library(plantTracker)
library(sf)

dat <- readRDS("results/combined_seagrass_shapes.rds")
print(sum(!st_is_valid(dat)))
dat <- st_make_valid(dat)
print(sum(!st_is_valid(dat)))
quadInv_list <- readRDS("results/Inv_seagrass.rds")
names(dat)[2] <- "Species"

plantTracker::checkDat(dat = dat, 
                      inv = quadInv_list,
                      species = "Species",
                      site = "Site", 
                      quad = "Quad",
                      year = "Year")




datTrackSpp <- plantTracker::trackSpp(
    dat = dat, 
    inv = quadInv_list,
    dorm = 80,           
    buff = 10,      
    buffGenet = 10,    
    clonal = data.frame(
        "Species" = c("Seagrass"),  
        "clonal" = TRUE
    ),
    aggByGenet = TRUE,
    printMessages = TRUE,
    flagSuspects = TRUE
)

datTrackSppsg <- plantTracker::trackSpp(
    dat = dat, 
    inv = quadInv_list,
    dorm = 80,           
    buff = 10,      
    buffGenet = 10,    
    clonal = data.frame(
        "Species" = c("Seagrass"),  
        "clonal" = TRUE
    ),
    aggByGenet = TRUE,
    printMessages = TRUE,
    flagSuspects = TRUE
)

drawQuadMap(
    dat = datTrackSppsg,
    type = "bytrackID",
    addBuffer = FALSE,
    site = "Site",
    quad = "Quad",
    trackedID = "trackID",
    plotTitle = "Tracked Species Map - Joulters",
    savePlot = TRUE,
    fileName = "results/tracked_species_map_Joulters.png"
)

st_write(datTrackSpp, "results/tracked_species.geojson", driver = "GeoJSON", delete_dsn=TRUE)
