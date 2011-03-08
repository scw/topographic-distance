#!/usr/bin/env python
# lines.py -- extract raster values along a geometry at regular intervals
# 
try:
    from osgeo import gdal, ogr
except:
    import gdal, ogr

import numpy
import struct
import sys

# returns the cellvalue on the band at (x, y)
def CellValue(band, ndv, geotransform, x, y):
  cols = band.XSize
  rows = band.YSize

  cellSizeX = geotransform[1]
  # Y-cell resolution is reported as negative
  cellSizeY = -1 * geotransform[5]

  minx = geotransform[0]
  maxy = geotransform[3]
  maxx = minx + (cols * cellSizeX)
  miny = maxy - (rows * cellSizeY)

  if ((x < minx) or (x > maxx) or (y < miny) or (y > maxy)):
    #print 'given point does not fall within grid'
    return ndv

  # calc point location in pixels
  xLoc = (x - minx) / cellSizeX
  xLoc = int(xLoc)
  yLoc = (maxy - y) / cellSizeY
  yLoc = int(yLoc)

  if ((xLoc < 0.5) or (xLoc > cols - 0.5)):
    return ndv

  if ((yLoc < 0.5) or (yLoc > rows - 0.5)):
    return ndv

  strRaster = band.ReadRaster(xLoc, yLoc, 1, 1, 1, 1, band.DataType)
  sDT = gdal.GetDataTypeName(band.DataType)
  if (sDT == 'Int16'):
    dblValue = struct.unpack('h', strRaster)
  elif (sDT == 'Float32'):
    dblValue = struct.unpack('f', strRaster)
  elif (sDT == 'Byte'):
    dblValue = struct.unpack('B', strRaster)
  else:
    print 'unrecognized DataType:', gdal.GetDataTypeName(band.DataType)
    return ndv

  return dblValue[0]

# in projected units; here meters
DISTANCE_LIMIT = 30000
# how far apart should the points be between sample locations?
SEGMENT_DISTANCE = 10

# shapefile containing geometries we're interested in
infile = "../data/generated/frog-lake-lines.shp"
# raster DEM of 'z' values
inraster = "../data/seki/dem/elev_met.tif"

ds = ogr.Open(infile)
lyr = ds.GetLayer(0)
total = 0

source_ds = gdal.Open(inraster)
if source_ds is None:
  print 'Could not open image file'
  sys.exit(1)

# read in the DEM data and get info about it
geotransform = source_ds.GetGeoTransform()
band = source_ds.GetRasterBand(1)
rows = source_ds.RasterYSize
cols = source_ds.RasterXSize

# set a default NDV if none specified
if (band.GetNoDataValue() == None):
    band.SetNoDataValue(-9999)
ndv = band.GetNoDataValue()

print "fid,topographic_dist,linear_dist,increase"
for i in range(lyr.GetFeatureCount()):
    feat = lyr.GetFeature(i)

    feat.GetGeometryRef().Segmentize(SEGMENT_DISTANCE)
    
    pt_count = feat.GetGeometryRef().GetPointCount()
  
    (start_x, start_y, start_z) = feat.GetGeometryRef().GetPoint() 
    start_z = CellValue(band, ndv, geotransform, start_x, start_y)
    start = numpy.array((start_x, start_y, start_z))
    (end_x, end_y, end_z) = feat.GetGeometryRef().GetPoint(pt_count - 1)
    end = numpy.array((end_x, end_y, start_z))

    linear_dist = numpy.linalg.norm(start - end)
    # cap the distance calculations; beyond this distance they aren't worth computing the fancy way.
    if linear_dist <= DISTANCE_LIMIT:
        line_dist = 0
        for j in range(0, pt_count):
            (x, y, z) = feat.GetGeometryRef().GetPoint(j)
             
            # What we're really doing here is computing the 'z' value which we can add to a 
            # list of triples, and then compute the distances between each pair of triples -- 
            # summing these 3d distances is what we ultimately want.
            z = CellValue(band, ndv, geotransform, x, y)

            dest = numpy.array((x,y,z))
           
            # http://stackoverflow.com/questions/1401712/calculate-euclidean-distance-with-numpy 
            line_dist += numpy.linalg.norm(start - dest)
            # retain previous coordinate for next calculation
            start = dest
        print "%i,%.2f,%.2f,%.4f" % (i, line_dist, linear_dist, (line_dist / linear_dist) - 1)
        total += pt_count

print "total sample points: %i" % total
