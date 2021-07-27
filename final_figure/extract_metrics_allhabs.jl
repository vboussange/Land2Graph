using Glob
# directory where all habitat raster are listed
dir_files = "/Users/victorboussange/ETHZ/projects/neutralmarker/Land2Graph/data/lvl2_dataofinterest/"

# arrays of metrics for different habitats
rasters_sqrtk = []
rasters_cl = []
rasters_assortativity = []

for filename_hab in glob("iucn*", dir_files)
    println("Computing for", filename_hab)
    raster_sqrtk = fill(NaN, length(raster_i), length(raster_j))
    raster_cl = fill(NaN, length(raster_i), length(raster_j))
    raster_assortativity = fill(NaN, length(raster_i), length(raster_j))
    data_src = rasterio.open(filename_hab, "r")

    # opening the region of interest
    row, col = data_src.index(xmin, ymax)
    myim = data_src.read(1, window = rasterio.windows.Window( col, row, sizex, sizey))

    # dividing the raster in coarser raster
    window_size = 25#cells
    raster_i = 1:window_size:size(myim,1)
    raster_j = 1:window_size:size(myim,2)

    # looping over the windows of the coarser raster
    for ii in 1:length(raster_i)
        i = raster_i[ii] #index coarser raster
        for (jj,j) in enumerate(raster_j[1:end])
            datahab_ij = view(myim, i:i+window_size - 1, j:j+window_size - 1)
            ncells = count(datahab_ij .> 0) # is there the considered habitat in the window?
            if ncells > 0
                datatemp_ij = view(mytemp, i:i+window_size - 1,j:j+window_size -1 ) # needed for assortativity
                verbose && println(ncells, " cells of habitats ", habitat, " were found")
                g, B = extract_graph_1km(datahab_ij, area_threshold)
                # calculating metrics
                raster_sqrtk[ii,jj] = sqrtk(g)
                raster_cl[ii,jj] = (mean∘betweenness_centrality)(g)
                raster_assortativity[ii,jj] = assortativity(g, datatemp_ij[B])

                if verbose
                    println("sqrtk = ", raster_sqrtk[ii,jj])
                    println("cl = ", raster_cl[ii,jj])
                    println("assortativity = ", raster_assortativity[ii,jj])
                end
            end
        end
    end
    push!(rasters_sqrtk, raster_sqrtk)
    push!(rasters_cl, raster_cl)
    push!(rasters_assortativity, raster_assortativity)
    data_src.close()
end
