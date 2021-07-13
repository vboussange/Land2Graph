import numpy as np
import cartopy.crs as ccrs
import cartopy.feature as cf
import rasterio
import matplotlib.pyplot as plt
from shapely import geometry

rivers_50m = cf.NaturalEarthFeature('physical', 'rivers_lake_centerlines', '50m')

# plotting whole file
filename = './data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif'
with rasterio.open(filename, 'r') as src:

    # read image into ndarray
    im = src.read(1)

    # calculate extent of raster
    xmin = -180.
    xmax = 180
    ymin = -90.
    ymax = 90

    # define cartopy crs for the raster
    crs = ccrs.PlateCarree()

    # create figure
    ax = plt.axes(projection=crs)
    plt.title('RGB.byte.tif')
    ax.set_xmargin(0.05)
    ax.set_ymargin(0.10)

    # plot raster
    plt.imshow(im, extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation='nearest')

    # plot coastlines
    ax.coastlines(resolution='110m', color='red', linewidth=1)

    plt.show()

# plotting window
with rasterio.open(filename, 'r') as src:

    # calculate extent of raster
    xmin = 94.132175
    xmax = 101.873647
    ymin =  22.097833
    ymax = 31.834458

    # longitude / latitudes for top left and bottom right corner of hengduan window
    row, col = src.index(xmin, ymin)
    row2, col2 = src.index(xmax, ymax)

    # read image into ndarray
    im = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
    # define cartopy crs for the raster
    crs = ccrs.PlateCarree()


    # create figure
    fig = plt.figure()
    gs = fig.add_gridspec(3, 1)

    ax1 = fig.add_subplot(gs[0:2, :], projection=crs)
    ax1.set_title('Hengduan region')
    ax1.set_xmargin(0.05)
    ax1.set_ymargin(0.10)

    # plot raster
    ax1.imshow(im, extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation='nearest')

    # plot features
    ax1.coastlines(resolution='auto', color='red')
    ax1.add_feature(cf.BORDERS)
    ax1.add_feature(rivers_50m, facecolor='None', edgecolor='b')

    # adding the window that we like
    windowminx = 95.
    windowmaxx = 96.
    windowminy = 25
    windowmaxy = 26
    geom = geometry.box(minx=windowminx,maxx=windowmaxx,miny=windowminy,maxy=windowmaxy)
    ax1.add_geometries([geom], alpha=0.5, crs = crs)

    ##### adding an other plot
    # longitude / latitudes for top left and bottom right corner of hengduan window
    row, col = src.index(windowminx, windowminy)
    row2, col2 = src.index(windowmaxx, windowmaxy)

    # read image into ndarray
    im2 = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
    # define cartopy crs for the raster
    crs = ccrs.PlateCarree()

    ax2 = fig.add_subplot(gs[2, :], projection=crs)
    ax2.set_title('zoomed window')
    ax2.set_xmargin(0.05)
    ax2.set_ymargin(0.10)

    # plot raster
    ax2.imshow(im2, extent=[windowminx, windowmaxx, windowminy, windowmaxy], transform=crs, interpolation='nearest')

    # plot features
    ax2.coastlines(resolution='auto', color='red')
    ax2.add_feature(cf.BORDERS)
    ax2.add_feature(rivers_50m, facecolor='None', edgecolor='b')

    fig.tight_layout()
    plt.show()


