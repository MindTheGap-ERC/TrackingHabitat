dat <- grasslandData[grasslandData$Site == c("AZ") &
 grasslandData$Quad == "SG2" &
 grasslandData$Year %in% c(1922:1925),]
names(dat)[1] <- "speciesName"
inv <- grasslandInventory[unique(dat$Quad)]
outDat <- trackSpp(dat = dat,
 inv = inv,
 dorm = 1,
 buff = .05,
 buffGenet = 0.005,
 clonal = data.frame("Species" = unique(dat$speciesName),
 "clonal" = c(TRUE,FALSE)),
 species = "speciesName",
 aggByGenet = TRUE
 )
drawQuadMap(dat = outDat,
type = "bySpecies",
addBuffer = FALSE,
species = "speciesName"
)
