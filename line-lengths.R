#!/usr/bin/env Rscript

require('rgdal')
# the original data they sent on is all in NAD27, may want to check if they're
# measuring things in a different datum for consistency

setwd("~/d/education/frog-pathogen")

lines <- readOGR(dsn="data/generated/single.shp", layer="single")

lengths <- SpatialLinesLengths(lines)

sum <- cumsum(lengths)

avg.length <- tail(sum, 1) / nrow(lines)

print("Average line length:")
print(avg.length)

print("Needed raster values (estimate):")
print(tail(sum, 1) / 8)
#for (i in 1:nrow(lines)) {
    
#  lines[[i]] <- Lines(Line(rbind(c(lakes$X_CENTER[1], lakes$Y_CENTER[1]), c(lakes$X_CENTER[i], lakes$Y_CENTER[i]))), ID = as.character(i))
#  d <- rbind(d, data.frame(ID=as.character(i), from_id=lakes$LAKEID[1], to_id=lakes$LAKEID[i+1]))
#}

#sldf <- SpatialLinesDataFrame(SpatialLines(lines), d, match.ID = FALSE)
