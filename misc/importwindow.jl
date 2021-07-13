cd(@__DIR__)
using PyCall
using Conda
rasterio = pyimport("rasterio")
using PyPlot
dataset = rasterio.open("../data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif")
band1 = dataset.read(1)

# longitude / latitudes for top left and bottom right corner of hengduan window
row, col = dataset.index(94.132175, 31.834458)
row2, col2 = dataset.index(101.873647, 22.097833)
# full region 
plt.imshow(band1[row:row2,col:col2])
# scaled window
plt.imshow(band1[row+50:row+100,col:col+50])
band1[row+50:row+100,col:col+50] .> 500

# try to do the same with temperature to check that what you have as data is good

# it would be nice to be able to plot a shape file within the matplotlib, but this seems more difficult