# ENV["PYTHON"] = "/usr/local/anaconda3/envs/land2graph/bin/python"
# using Pkg; Pkg.build("PyCall")
using PyCall
ccrs = pyimport("cartopy.crs")
cf = pyimport("cartopy.feature")
rasterio = pyimport("rasterio")
using PyPlot
include("../misc/pnas.jl")
geometry = pyimport("shapely.geometry")
cd(@__DIR__)
rivers_50m = cf.NaturalEarthFeature("physical", "rivers_lake_centerlines", "50m")

filename_hab = "../data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif"
filename_temp = "../data/chelsa/CHELSA_bio12_reprojected_nearest.tif"
# calculate extent of raster
xmin = 94.132175
xmax = 101.873646
ymin =  22.097833
ymax = 31.7

# adding the window that we like
windowminx = 99.
windowmaxx = 99.15
windowminy = 25
windowmaxy = 25.15

verbose = true
habitat = "forest"

src = rasterio.open(filename_hab, "r")
# try
# longitude / latitudes for top left and bottom right corner of hengduan window
row, col = src.index(xmin, ymin)
row2, col2 = src.index(xmax, ymax)
# read image into ndarray
global myim = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))

# longitude / latitudes for top left and bottom right corner of hengduan window
global row, col = src.index(windowminx, windowminy)
global windowminx, windowminy = src.xy(row, col)
global row2, col2 = src.index(windowmaxx, windowmaxy)
global windowmaxx, windowmaxy = src.xy(row2, col2)
global myim2 = src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
# finally 
#     src.close()
# end


# define cartopy crs for the raster
crs = ccrs.PlateCarree()


# create figure
fig = plt.figure()
gs = fig.add_gridspec(2, 2)
ax1 = fig.add_subplot(py"$gs[0, 0]", projection=crs)
ax2 = fig.add_subplot(py"$gs[1, 0]", projection=crs)
ax3 = fig.add_subplot(py"$gs[0, 1]", projection=crs)
ax4 = fig.add_subplot(py"$gs[1, 1]", projection=crs)


################
#### ax1 #######
################
# ax1.set_title("Hengduan region")
ax1.set_xmargin(0.05)
ax1.set_ymargin(0.10)

# plot raster
ax1.imshow(myim, extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation="nearest")
gl = ax1.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false

# plot features
ax1.coastlines(resolution="auto", color="red")
ax1.add_feature(cf.BORDERS)
ax1.add_feature(rivers_50m, facecolor="None", edgecolor="b")

# adding small shaded area to ax1
geom = geometry.box(minx=windowminx, maxx=windowmaxx, miny=windowminy, maxy=windowmaxy);
ax1.add_geometries([geom], alpha=1, crs = crs, edgecolor = "r", linewidth = 3)

############################
############ ax2 ###########
############################
# ax2.set_title("zoomed window")
ax2.set_xmargin(0.05)
ax2.set_ymargin(0.10)
[i.set_linewidth(3) for i in ax2.spines.values()]
[i.set_color("r") for i in ax2.spines.values()]

# plot raster
ax2.imshow(myim2, origin="upper", extent=[windowminx - src.transform[1]/2, windowmaxx - src.transform[1]/2, windowminy - src.transform[5]/2, windowmaxy - src.transform[5]/2], transform=crs)

# plot features
ax2.coastlines(resolution="auto", color="red")
ax2.add_feature(cf.BORDERS)
ax2.add_feature(rivers_50m, facecolor="None", edgecolor="b")

fig.tight_layout()
gcf()

#############################################
############ graph transformation ###########
#############################################
include("../src/extract_graph_from_raster.jl")
include("../src/graph_metrics.jl")
include("../../graphs_utils/src/graphs_utils.jl")
area_threshold = 900

g, B = extract_graph_1km(myim2, area_threshold)
coord_graph = CartesianIndices(myim2)[B]
gx = to_nx(g)

pos = Dict{Int,Array}()
for i in 1:length(coord_graph)
    xs, ys = src.xy(row2 + coord_graph[i][1] - 1, col + coord_graph[i][2] - 1, offset="center")
    pos[i-1] = [xs[], ys[]]
end
nx.draw_networkx_nodes(gx,
                pos,
                edgecolors="tab:blue",
                node_size = 1e0,
                node_color = "tab:blue",
                # horizontalalignment = "right",
                # verticalalignment = "baseline",
                # alpha = 0.
                # options,
                # with_labels = false,
                ax = ax2,
                )
nx.draw_networkx_edges(gx, pos, alpha=0.5, width=1,ax=ax2)

# ax2.axis("off")
gl = ax2.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false

ax2.margins(0.10)
################################
######### ax 3##################
################################
include("extract_metrics.jl")

ax3.imshow(raster["sqrtk"], extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation="nearest")
gcf()

# rasterio.transform.xy