library(plantTracker)
library(sf)

dat <- readRDS("results/combined_shapes.rds")
print(sum(!st_is_valid(dat)))
dat <- st_make_valid(dat)
print(sum(!st_is_valid(dat)))
quadInv_list <- readRDS("results/quadInv_list.rds")
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
    dorm = 1,           
    buff = .05,          
    buffGenet = .005,    
    clonal = data.frame(
        "Species" = c("Hardground","Island","Macroalgae","Microfilm","Reef","Sand","Seagrass","Slope"),  # Replace with your species
        "clonal" = c(FALSE)                
    ),
    aggByGenet = TRUE,   
    printMessages = TRUE 
)


saveRDS(datTrackSpp, "results/tracked_species.rds")