using MAT

data = matread("src/Stacker/modelResults/FaciesMosaic.mat")
variables = keys(data)
stratadata = data["strata"]

#extract data
facies = stratadata["facies"]
layers = stratadata["layers"]

# faciesMosaicElementTrajectoryY is 25*10000: rows are each patch, columns are time steps
# faciesMosaicElementYInc is 25*1: rows are each patch, columns are y increment per time step
