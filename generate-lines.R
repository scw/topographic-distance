#!/usr/bin/env Rscript

library('rgdal')

# the original data they sent on is all in NAD27, may want to check if they're
# measuring things in a different datum for consistency

setwd("~/d/education/frog-pathogen")

# Read in the polygon shapefile, reshape the centroid coordinates into coordinate pairs, to 
# be fed into a SpatialLines object -- this can be saved as a shapefile with sp, as an intermediate product.

lakes <- readOGR(dsn="data/seki/lakes/SEKI_lakes.shp", layer="SEKI_lakes")

# filter the list out by those which have the 'HasFrogs' attribute
frog.lakes <- lakes$LAKEID[!is.na(lakes$HasFrogs)]

lines <- list()
d <- data.frame(ID=character(0), from_id=numeric(0), to_id=numeric(0))

# compute the full line matrix
computed <- c()
k <- 1 
# there's probably an existing function in R (perhaps using dist()), but this isn't an expensive
# operation to compute manually, so doing it the ol' fashion way here. This generates the full
# m*n matrix, for a total of (m*m-1) / 2 lines; here 195625.
for (i in 1:length(frog.lakes)) {
  source <- frog.lakes[i]
  computed <- append(computed, source)
  for (j in 1:length(frog.lakes)) {
    dest <- frog.lakes[j]

    # this is a candidate lake pairing: we've computed neither it or its inverse
    if (!(dest %in% computed)) {
      lines[[k]] <- Lines(Line(rbind(c(lakes$X_CENTER[i], lakes$Y_CENTER[i]), c(lakes$X_CENTER[j], lakes$Y_CENTER[j]))), ID = as.character(k)) 
      d <- rbind(d, data.frame(ID=as.character(k), from_id=lakes$LAKEID[i], to_id=lakes$LAKEID[j]))
      k <- k + 1
      #cat(k, "\n")
    }
  }
}

# cast our lines into SpatialLines objects, copying in the CRS from the source dataset,
# including our attributes data frame
sldf <- SpatialLinesDataFrame(SpatialLines(lines, proj4string=CRS(proj4string(lakes))), d, match.ID = FALSE)

writeOGR(sldf, "data/generated/full.shp", "full", driver="ESRI Shapefile")
