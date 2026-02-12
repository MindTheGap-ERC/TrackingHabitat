library(plantTracker)
library(sf)

dat <- readRDS("results/combined_shapes.rds")
print(sum(!st_is_valid(dat)))
dat <- st_make_valid(dat)
print(sum(!st_is_valid(dat)))
quadInv_list <- readRDS("results/Inv_all.rds")
names(dat)[2] <- "Species"

plantTracker::checkDat(dat = dat, 
                      inv = quadInv_list,
                      species = "Species",
                      site = "Site", 
                      quad = "Quad",
                      year = "Year")


print(unique(dat$Species))

# datTrackSpp <- plantTracker::trackSpp(
#     dat = dat, 
#     inv = quadInv_list,
#     dorm = 80,           
#     buff = 10,      
#     buffGenet = 10,    
#     clonal = data.frame(
#         "Species" = c("Seagrass"),  
#         "clonal" = TRUE
#     ),
#     aggByGenet = TRUE,
#     printMessages = TRUE,
#     flagSuspects = TRUE
# )

datTrackSppsg <- plantTracker::trackSpp(
    dat = dat, 
    inv = quadInv_list,
    dorm = 80,           
    buff = 20,      
    buffGenet = 50,    
    clonal = data.frame(
        "Species" = c( "Hardground","Island","Macroalgae","Microfilm","Reef","Sand","Seagrass","Slope"),  
        "clonal" = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE)
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

st_write(datTrackSppsg, "results/tracked_species.geojson", driver = "GeoJSON", delete_dsn=TRUE)

