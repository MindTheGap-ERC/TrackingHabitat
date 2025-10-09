# Create inventory for Joulters data
quadInv_DF <- data.frame(
    "vintage" = c(1949),
    "modern" = c(2019)
)

# Convert to list format
quadInv_list <- as.list(quadInv_DF)

# Remove any NA values (though there shouldn't be any in this case)
quadInv_list <- lapply(X = quadInv_list, FUN = function(x) x[is.na(x) == FALSE])