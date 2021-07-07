cd(@__DIR__)
using Pkg; Pkg.activate(".")
using ArchGDAL; const AG = ArchGDAL
using Statistics
using ProgressMeter
using Glob, JLD2
using Dates
verbose = true
test = false
plotting = false

include("src/extract_graph_from_raster.jl")
savedir = "results/lvl2_frac_1km_ver004"
isdir(savedir) ? nothing : mkpath(savedir)
## COMPOSITE ##

datalist = glob("./data/lvl2_frac_1km_ver004/*.tif")

println("Starting computation")
println(now())
Threads.@sync Threads.@threads for f in datalist
    dataset = AG.read(f)
    fsplit = split(f,"_")
    window_size = 100#km
    habitat = parse(UInt16,fsplit[9]) #lvl1 forest
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
        if test
            if i > 1
                break
            end
        end
    end
    savename = split(f,"/")[end]
    savename = string(split(savename,".")[1],".jld2")
    @save joinpath(savedir,savename) newraster
end

# plotting
if plotting
    datalist = glob(savedir*"/*.jld2")
    for _dat in datalist
        @load _dat newraster
        savename = split(_dat,"/")[end]
        savenamfig = string(split(savename,".")[1],".pdf")
        fig, ax = plt.subplots();
        ax.imshow(newraster')
        fig.savefig(joinpath(savedir,savenamfig))
        plt.close(fig)
    end
end
println(now())
println("Computation over")