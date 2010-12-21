#!/usr/bin/env Rscript

require('raster')
require('rgdal')
# the original data they sent on is all in NAD27, may want to check if they're
# measuring things in a different datum for consistency

setwd("~/d/education/frog-pathogen")

r <- raster("data/seki/dem/elev_met/hdr.adf")

# Read in the polygon shapefile, reshape the centroid coordinates into coordinate pairs, to 
# be fed into a SpatialLines object -- this can be saved as a shapefile with sp, as an intermediate product.

lines <- readOGR(dsn="data/generated/single.shp", layer="single")

# compute the full line matrix
#for (i in 1:nrow(lines)) {
for (i in 1:2) {
  # get two consecutive points for calculating the line. To do the distance matrix, you'd need
  # to compute the full m*n == (m*m-1)/2 set of lines.
  #lines[[i]] <- Lines(Line(rbind(c(lakes$X_CENTER[i], lakes$Y_CENTER[i]), c(lakes$X_CENTER[i+1], lakes$Y_CENTER[i+1]))), ID = as.character(i))
  #attr <- rbind(attr, c(ID=as.character(i), from_id=lakes$LAKEID[i], to_id=lakes$LAKEID[i+1]))
  
  #tmp <- SpatialLines(lines[[i]]) #SpatialLines(list(), i)))
# running this for 18 distances takes ~5minutes! That's ~17s per distance, 
# with a full matrix we'd have 125000 calculations, or 590hr to run the whole set, which is 24 days...
# actually, its worse than this: we'd have 7.1M calculations across the full set of lakes, though perhaps filteirng would reduce this to a more reasonable quantity...

  #system.time(elevations <- extract(r, tmp))
}

system.time(elevations <- extract(r, lines))

#    392.63    0.45  396.41 
# my guess is this is probably an order of magnitude faster in GRASS...

# our 'z' values
#elevations <- extract(r, lines)

# x and y can be pulled from the sp object containing the shapefile itself
# TODO actually, this only pulls the coordinates for the _points_ need the coordinates from the extract locations...

# actually smackually, we don't even need this -- the sampling grid is COMPLETELY REGULAR so the x and y components are always the same... only Z is varying. So we just need to do the maths for the paths, and we're g2g.
