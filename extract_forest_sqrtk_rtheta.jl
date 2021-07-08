cd(@__DIR__)
using Pkg; Pkg.activate(".")
# using PyPlot
using ArchGDAL; const AG = ArchGDAL
using Statistics
using ProgressMeter
using Glob, JLD2
using Dates
verbose = true
test = true
plotting = false
simulation = true

include("src/extract_graph_from_raster.jl")
include("src/graph_metrics.jl")

savedir = "results/forests"
isdir(savedir) ? nothing : mkpath(savedir)


if simulation
    dataset_hab = AG.read("./data/lvl1_frac_1km_ver004/iucn_habitatclassification_fraction_lvl1__100_Forest__ver004.tif")
    dataset_temp = AG.read("./data/chelsa/CHELSA_bio1_reprojected.tif")

    window_size = 100#km
    habitat = "forest"
    raster_i = 1:window_size:AG.width(dataset_hab)
    raster_j = 1:window_size:AG.height(dataset_hab)

    raster = Dict(
                    "sqrtk" => zeros(length(raster_i), length(raster_j)),
                    "assortativity" => zeros(length(raster_i), length(raster_j)),
                    )
    raster_g = Array{SimpleGraph{Int16}}(undef,length(raster_i), length(raster_j))

    # preallocating
    band_hab = AG.getband(dataset_hab, 1) #x, y , window size
    band_temp = AG.getband(dataset_temp, 1) #x, y , window size

    # main loop
    for ii in 1:length(raster_i)-1
        for (jj,j) in enumerate(raster_j[1:end-1])
            i = raster_i[ii]
            data = view(band_hab, i:i+window_size,j:j+window_size)
            data_temp = view(band_temp, i:i+window_size,j:j+window_size)
           
            ncells = count(data .> 0)
            if ncells > 0
                verbose && println(ncells, " cells of habitats ", habitat, " were found")
                g, B = extract_graph_1km(data)
                # calculating metrics
                raster["sqrtk"][ii,jj] = sqrtk(g)
                raster["assortativity"][ii,jj] = assortativity(g, data_temp[B])
                # storing graph
                raster_g[ii,jj] = g

                if verbose
                    println("sqrtk = ", raster["sqrtk"][ii,jj])
                    println("assortativity = ", raster["assortativity"][ii,jj])
                end
            end
        end

        if test
            if i > 1
                break
            end
        end
    end
    savename = "forest_lvl1_sqrtk_rtheta"
    savename = string(split(savename,".")[1],".jld2")
    @save joinpath(savedir,savename) raster raster_g
end
println(now())
println("Computation over")

# plotting
if plotting
    datalist = glob(savedir*"/*.jld2")
    for _dat in datalist
        @load _dat raster
        savename = split(_dat,"/")[end]
        savenamfig = string(split(savename,".")[1],".pdf")
        fig, ax = plt.subplots();
        ax.imshow(raster')
        fig.savefig(joinpath(savedir,savenamfig))
        plt.close(fig)
    end
end
