#!/usr/bin/env Rscript

require('rgdal')
# the original data they sent on is all in NAD27, may want to check if they're
# measuring things in a different datum for consistency

setwd("~/d/education/frog-pathogen")

# Read in the polygon shapefile, reshape the centroid coordinates into coordinate pairs, to 
# be fed into a SpatialLines object -- this can be saved as a shapefile with sp, as an intermediate product.

lakes <- readOGR(dsn="data/seki/lakes/SEKI_lakes.shp", layer="SEKI_lakes")

lines <- list()
d <- data.frame(ID=character(0), from_id=numeric(0), to_id=numeric(0))

# compute the full line matrix
for (i in 1:nrow(lakes)) {
  # get two consecutive points for calculating the line. To do the distance matrix, you'd need
  # to compute the full m*n == (m*m-1)/2 set of lines.
    
  lines[[i]] <- Lines(Line(rbind(c(lakes$X_CENTER[1], lakes$Y_CENTER[1]), c(lakes$X_CENTER[i], lakes$Y_CENTER[i]))), ID = as.character(i))
  d <- rbind(d, data.frame(ID=as.character(i), from_id=lakes$LAKEID[1], to_id=lakes$LAKEID[i+1]))
}

sldf <- SpatialLinesDataFrame(SpatialLines(lines), d, match.ID = FALSE)

# XXX SPECIFY SPATIAL REFERENCE
writeOGR(sldf, "data/generated/single.shp", "single", driver="ESRI Shapefile")
