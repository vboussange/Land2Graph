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
filename_hab = "/Users/victorboussange/ETHZ/projects/neutralmarker/Land2Graph/data/lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__104_Forest – Temperate__ver004.tif"
# filename_hab = "/Users/victorboussange/ETHZ/projects/neutralmarker/Land2Graph/data/lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__404_Grassland – Temperate__ver004.tif"
area_threshold = 800

filename_temp = "../data/chelsa/CHELSA_bio1_reprojected_nearest.tif"
# calculate extent of raster
xmin = 94.132175
ymin =  22.097833
ymax = 31.834458
xmax = 101.873646

sizex = 800
sizey = 1250

# adding the window that we like
windowminx = 99.
windowmaxx = 99.15
windowminy = 27.2
windowmaxy = 27.42

habitat = "forest"

data_src = rasterio.open(filename_hab, "r")
data_src_temp = rasterio.open(filename_temp, "r")

# try
# longitude / latitudes for top left corner of hengduan window
row, col = data_src.index(xmin, ymax)
# row2, col2 = data_src.index(xmax, ymax)
# read image into ndarray
myim = data_src.read(1, window = rasterio.windows.Window( col, row, sizex, sizey))
mytemp = data_src_temp.read(1, window = rasterio.windows.Window( col, row, sizex, sizey)) /10. .- 273.15
xmin, ymax = data_src.xy(row, col)
xmax, ymin = data_src.xy(row + sizey, col + sizex )

# longitude / latitudes for top left and bottom right corner of hengduan window
row, col = data_src.index(windowminx, windowminy)
windowminx, windowminy = data_src.xy(row, col)
row2, col2 = data_src.index(windowmaxx, windowmaxy)
windowmaxx, windowmaxy = data_src.xy(row2, col2)
myim2 = data_src.read(1, window = rasterio.windows.Window( col, row2, col2-col, row - row2))
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
pos1 = ax1.imshow(mytemp,
                extent=[xmin, xmax, ymin, ymax],
                transform=crs,
                interpolation="nearest",
                cmap = :cividis
                )

cb = plt.colorbar(pos1, ax=ax1, label = "Temperature", shrink=0.5)
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
ax2.set_xmargin(-0.01)
ax2.set_ymargin(-0.01)
[i.set_linewidth(3) for i in ax2.spines.values()]
[i.set_color("r") for i in ax2.spines.values()]

# plot raster
pos2 = ax2.imshow(myim2/10,
                origin="upper",
                extent=[windowminx - data_src.transform[1]/2, windowmaxx - data_src.transform[1]/2, windowminy - data_src.transform[5]/2, windowmaxy - data_src.transform[5]/2],
                transform=crs,
                cmap = :Greens)
cb = colorbar(pos2, ax=ax2, label = "Prop. habitat (Temperate Forest), %", shrink=0.5)

# plot features
# ax2.coastlines(resolution="auto", color="red")
# ax2.add_feature(cf.BORDERS)
ax2.add_feature(rivers_50m, facecolor="None", edgecolor="b")
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
                edgecolors="cyan",
                node_size = 1e1,
                node_color = "tab:blue",
                # horizontalalignment = "right",
                # verticalalignment = "baseline",
                # alpha = 0.
                # options,
                # with_labels = false,
                ax = ax2,
                )
nx.draw_networkx_edges(gx, pos, alpha=0.9, width=1,ax=ax2)

# ax2.axis("off")
gl = ax2.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false

# ax2.margins(0.10)
################################
######### ax 3 / 4##################
################################
using DelimitedFiles

if true
    verbose = false
    include("extract_metrics_allhabs.jl")

    r_ass_mean = similar(rasters_assortativity[1])
    r_sqrtk_mean = similar(rasters_sqrtk[1])
    for i in CartesianIndices(r_ass_mean)
        r_ass_mean[i] = mean(filter(!isnan,[r[i] for r in rasters_assortativity]))
        r_sqrtk_mean[i] = mean(filter(!isnan,[r[i] for r in rasters_sqrtk]))
    end
    writedlm("r_ass_mean.csv", r_ass_mean)
    writedlm("r_ass_mean.csv", r_ass_mean)
else
    r_ass_mean = readdlm("r_ass_mean.csv")
    r_ass_mean = readdlm("r_ass_mean.csv")
end

pos3 = ax3.imshow(r_sqrtk_mean,
                extent=[xmin, xmax, ymin, ymax],
                transform=crs,
                interpolation="nearest",
                cmap = :viridis)
cb = plt.colorbar(pos3, ax=ax3, label = L"\nicefrac{\left\langle \sqrt{k}\right\rangle^{2}}{<k>}", shrink=0.5)
gl = ax3.gridlines(draw_labels=true)
gl.xlabels_top = false
gl.ylabels_right = false
gl.xlines = false
gl.ylines = false
ax3.coastlines(resolution="auto", color="red")
ax3.add_feature(cf.BORDERS)
ax3.add_feature(rivers_50m, facecolor="None", edgecolor="b")


pos4 = ax4.imshow(r_ass_mean,
                    extent=[xmin, xmax, ymin, ymax],
                    transform=crs,
                    interpolation="nearest",
                    cmap = :magma)
cb = plt.colorbar(pos4, ax=ax4, label = "Assortativity", shrink=0.5)
ax4.set_xticks(range(xmin, xmax,length=5), crs=crs)

ax4.coastlines(resolution="auto", color="red")
ax4.add_feature(cf.BORDERS)
ax4.add_feature(rivers_50m, facecolor="None", edgecolor="b")

_let = ["A","B","C","D"]
for (i,ax) in enumerate([ax1,ax2,ax3,ax4])
    _x = -0.2
    ax.text(_x, 1.05, _let[i],
        fontsize=12,
        fontweight="bold",
        va="bottom",
        ha="left",
        transform=ax.transAxes ,
    )
end
gcf()

ax3.set_facecolor("None")
ax2.set_facecolor("None")
ax1.set_facecolor("None")
ax4.set_facecolor("None")
fig.set_facecolor("None")

fig.tight_layout()
fig.savefig("final_figure_habitatmapping_$habitat.pdf",
            dpi=1200,
            bbox_inches = "tight",
            )

gcf()
