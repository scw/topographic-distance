#!/usr/bin/env Rscript

require('raster')
require('rgdal')
# the original data they sent on is all in NAD27, may want to check if they're
# measuring things in a different datum for consistency

setwd("~/d/education/frog-pathogen")

r <- raster("data/seki/dem/elev_met/hdr.adf")
#r <- raster("data/seki/dem/elev_met.asc")

# Read in the polygon shapefile, reshape the centroid coordinates into coordinate pairs, to 
# be fed into a SpatialLines object -- this can be saved as a shapefile with sp, as an intermediate product.

lakes <- readOGR(dsn="data/seki/lakes/SEKI_lakes.shp", layer="SEKI_lakes")

lines <- list()
d <- data.frame(ID=character(0), from_id=numeric(0), to_id=numeric(0))

# compute the full line matrix
for (i in c(1:10)) {
  # get two consecutive points for calculating the line. To do the distance matrix, you'd need
  # to compute the full m*n == (m*m-1)/2 set of lines.
  lines[[i]] <- Lines(Line(rbind(c(lakes$X_CENTER[i], lakes$Y_CENTER[i]), c(lakes$X_CENTER[i+1], lakes$Y_CENTER[i+1]))), ID = as.character(i))
  #attr <- rbind(attr, c(ID=as.character(i), from_id=lakes$LAKEID[i], to_id=lakes$LAKEID[i+1]))
  d <- rbind(d, data.frame(as.character(i), lakes$LAKEID[i], lakes$LAKEID[i+1]))
}

sldf <- SpatialLinesDataFrame(SpatialLines(lines), d, match.ID = FALSE)

for (i in c(1:10)) {
  # get two consecutive points for calculating the line. To do the distance matrix, you'd need
  # to compute the full m*n == (m*m-1)/2 set of lines.
  lines[[i]] <- Lines(Line(rbind(c(lakes$X_CENTER[i], lakes$Y_CENTER[i]), c(lakes$X_CENTER[i+1], lakes$Y_CENTER[i+1]))), ID = as.character(i))
  #attr <- rbind(attr, c(ID=as.character(i), from_id=lakes$LAKEID[i], to_id=lakes$LAKEID[i+1]))
  d <- rbind(d, data.frame(as.character(i), lakes$LAKEID[i], lakes$LAKEID[i+1]))
  #tmp <- SpatialLines(list(Lines(list(Line(centroids.line)), x)))

# running this for 18 distances takes ~5minutes! That's ~17s per distance, 
# with a full matrix we'd have 125000 calculations, or 590hr to run the whole set, which is 24 days...
# actually, its worse than this: we'd have 7.1M calculations across the full set of lakes, though perhaps filteirng would reduce this to a more reasonable quantity...

  system.time(elevations <- extract(r, tmp))
}

#    392.63    0.45  396.41 
# my guess is this is probably an order of magnitude faster in GRASS...

# our 'z' values
#elevations <- extract(r, lines)

# x and y can be pulled from the sp object containing the shapefile itself
# TODO actually, this only pulls the coordinates for the _points_ need the coordinates from the extract locations...

# actually smackually, we don't even need this -- the sampling grid is COMPLETELY REGULAR so the x and y components are always the same... only Z is varying. So we just need to do the maths for the paths, and we're g2g.

#srqt(9.3333 * 9.3333) + ... + 
if (FALSE) {
s.elev <- length(elevations[[1]] - 1)
dz.elev <- elevations[[1]][2:(s.elev+1)] - elevations[[1]][1:s.elev]
c.elev <- sqrt(9.336^2 + 9.336^2 + dz.elev^2)
c.e2d <- sqrt(9.336^2 + 9.336^2)
dist.e2d <- c.e2d * s.elev
dist.elev <- cumsum(c.elev[1:s.elev])

# for the first feature: 10509.34 vs. 10034...
pct.diff <- (dist.elev[s.elev - 1] - dist.e2d) / dist.e2d * 100
# here, 4.734% greater via 3d routine
}
