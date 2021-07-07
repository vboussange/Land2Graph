cd(@__DIR__)
using Pkg; Pkg.activate(".")
using ArchGDAL; const AG = ArchGDAL
using Statistics
using ProgressMeter
include("src/extract_graph_from_raster.jl")
verbose = true
## COMPOSITE ##
# dataset = AG.read("data/iucn_habitatclassification_composite_lvl1_ver004.tif")
dataset = AG.read("data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif")

window_size = 100#km
habitat = UInt16(100) #lvl1 forest
newraster_i = 1:window_size:AG.width(dataset)
newraster_j = 1:window_size:AG.height(dataset)
newraster = zeros(length(newraster_i), length(newraster_j))

# preallocating
data = AG.read(dataset, 1, 1, 1, window_size, window_size) #x, y , window size

# main loop
for (ii,i) in enumerate(newraster_i[1:end-1]), (jj,j) in enumerate(newraster_j[1:end-1])
    data .= AG.read(dataset, 1, i, j, window_size, window_size) #x, y , window size
    ncells = count(data .== habitat)
    if ncells > 0
        verbose && println(ncells, " cells of habitats ", habitat, " were found")
        g = extract_graph(data, habitat)
        metrics = mean(degree(g))
        verbose && println("mean metrics = ", metrics)
        newraster[ii,jj] = metrics
    end
end

using PyPlot
plt.imshow(newraster')
gcf()