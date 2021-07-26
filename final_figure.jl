ENV["PYTHON"] = "/usr/local/anaconda3/envs/land2graph/bin/python"
using Pkg; Pkg.build("PyCall")
using PyCall
ccrs = pyimport("cartopy.crs")
cf = pyimport("cartopy.feature")
rasterio = pyimport("rasterio")
using PyPlot
geometry = pyimport("shapely.geometry")
cd(@__DIR__)
rivers_50m = cf.NaturalEarthFeature("physical", "rivers_lake_centerlines", "50m")

filename = "./data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif"

# calculate extent of raster
xmin = 94.132175
xmax = 101.873647
ymin =  22.097833
ymax = 31.834458


# adding the window that we like
windowminx = 95.
windowmaxx = 96.
windowminy = 25
windowmaxy = 26

src = rasterio.open(filename, "r")
try
    # longitude / latitudes for top left and bottom right corner of hengduan window
    row, col = src.index(xmin, ymin)
    row2, col2 = src.index(xmax, ymax)
    # read image into ndarray
    global myim = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))

    # longitude / latitudes for top left and bottom right corner of hengduan window
    row, col = src.index(windowminx, windowminy)
    row2, col2 = src.index(windowmaxx, windowmaxy)
    global myim2 = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
finally 
    src.close()
end


# define cartopy crs for the raster
crs = ccrs.PlateCarree()


# create figure
fig = plt.figure()
gs = fig.add_gridspec(3, 1)

ax1 = fig.add_subplot(py"$gs[0:2, :]", projection=crs)
ax1.set_title("Hengduan region")
ax1.set_xmargin(0.05)
ax1.set_ymargin(0.10)

# plot raster
ax1.imshow(myim, extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation="nearest")

# plot features
ax1.coastlines(resolution="auto", color="red")
ax1.add_feature(cf.BORDERS)
ax1.add_feature(rivers_50m, facecolor="None", edgecolor="b")

# adding small shaded area to ax1
geom = geometry.box(minx=windowminx, maxx=windowmaxx, miny=windowminy, maxy=windowmaxy);
ax1.add_geometries([geom], alpha=0.5, crs = crs)

############################
############ ax2 ###########
############################
ax2 = fig.add_subplot(py"$gs[2, :]", projection=crs)
ax2.set_title("zoomed window")
ax2.set_xmargin(0.05)
ax2.set_ymargin(0.10)

# plot raster
ax2.imshow(myim2, extent=[windowminx, windowmaxx, windowminy, windowmaxy], transform=crs, interpolation="nearest")

# plot features
ax2.coastlines(resolution="auto", color="red")
ax2.add_feature(cf.BORDERS)
ax2.add_feature(rivers_50m, facecolor="None", edgecolor="b")

fig.tight_layout()
gcf()