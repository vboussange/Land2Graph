# ENV["PYTHON"] = "/usr/local/anaconda3/envs/land2graph/bin/python"
# using Pkg; Pkg.build("PyCall")
import EvoId.eth_grad_std
using PyCall
ccrs = pyimport("cartopy.crs")
cf = pyimport("cartopy.feature")
rasterio = pyimport("rasterio")
using PyPlot
include("../misc/pnas.jl")
geometry = pyimport("shapely.geometry")
cd(@__DIR__)
rivers_50m = cf.NaturalEarthFeature("physical", "rivers_lake_centerlines", "50m")

# filename_hab = "../data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif"
# filename_hab = "/Users/victorboussange/ETHZ/projects/neutralmarker/Land2Graph/data/lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__104_Forest – Temperate__ver004.tif"
filename_hab = "/Users/victorboussange/ETHZ/projects/neutralmarker/Land2Graph/data/lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__404_Grassland – Temperate__ver004.tif"
area_threshold = 800

filename_temp = "../data/chelsa/CHELSA_bio12_reprojected_nearest.tif"
# calculate extent of raster
xmin = 94.132175
xmax = 101.873646
ymin =  22.097833
ymax = 31.834458

# adding the window that we like
windowminx = 99.
windowmaxx = 99.15
windowminy = 27.2
windowmaxy = 27.35

verbose = true
habitat = "grassland"

data_src = rasterio.open(filename_hab, "r")
data_src_temp = rasterio.open(filename_temp, "r")

# try
# longitude / latitudes for top left and bottom right corner of hengduan window
row, col = data_src.index(xmin, ymin)
row2, col2 = data_src.index(xmax, ymax)
# read image into ndarray
global myim = data_src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
global mytemp = data_src_temp.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))/10. .- 273.15

# longitude / latitudes for top left and bottom right corner of hengduan window
global row, col = data_src.index(windowminx, windowminy)
global windowminx, windowminy = data_src.xy(row, col)
global row2, col2 = data_src.index(windowmaxx, windowmaxy)
global windowmaxx, windowmaxy = data_src.xy(row2, col2)
global myim2 = data_src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
# finally 
#     data_src.close()
# end


# define cartopy crs for the raster
crs = ccrs.PlateCarree()


# create figure
fig = plt.figure(
            # constrained_layout=true,
            figsize = FIGSIZE_L
            )
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
pos1 = ax1.imshow(myim, 
                extent=[xmin, xmax, ymin, ymax], 
                transform=crs, 
                interpolation="nearest", 
                cmap = :RdBu)

cb = plt.colorbar(pos1, ax=ax1, label = "Habitat prop", shrink=0.5)
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
pos2 = ax2.imshow(myim2, origin="upper", extent=[windowminx - data_src.transform[1]/2, windowmaxx - data_src.transform[1]/2, windowminy - data_src.transform[5]/2, windowmaxy - data_src.transform[5]/2], transform=crs)
# cb = colorbar(pos2, ax=ax2, label = "habitat")

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

g, B = extract_graph_1km(myim2, area_threshold)
coord_graph = CartesianIndices(myim2)[B]
gx = to_nx(g)

pos = Dict{Int,Array}()
for i in 1:length(coord_graph)
    xs, ys = data_src.xy(row2 + coord_graph[i][1] - 1, col + coord_graph[i][2] - 1, offset="center")
    pos[i-1] = [xs[], ys[]]
end
nx.draw_networkx_nodes(gx,
                pos,
                edgecolors="tab:blue",
                node_size = 1e1,
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
######### ax 3 / 4##################
################################
include("extract_metrics.jl")

pos3 = ax3.imshow(raster["sqrtk"], extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation="nearest")
cb = plt.colorbar(pos3, ax=ax3, label = "Sqrtk", shrink=0.5)
gl = ax3.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false

pos4 = ax4.imshow(raster["assortativity"], extent=[xmin, xmax, ymin, ymax], transform=crs, interpolation="nearest")
cb = plt.colorbar(pos4, ax=ax4, label = "Assortativity", shrink=0.5)
gl = ax4.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false

fig.tight_layout()
fig.savefig("final_figure_habitatmapping_$habitat.pdf",
            dpi=1200,
            bbox_inches = "tight",
            )

gcf()