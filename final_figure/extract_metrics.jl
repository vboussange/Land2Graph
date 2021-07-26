window_size = 50#cells
raster_i = 1:window_size:size(myim,1)
raster_j = 1:window_size:size(myim,2)

raster = Dict(
    "sqrtk" => fill(NaN,length(raster_i), length(raster_j)),
    "assortativity" => fill(NaN,length(raster_i), length(raster_j)),
    )

for ii in 1:length(raster_i)-1
    i = raster_i[ii]
    for (jj,j) in enumerate(raster_j[1:end-1])
        datahab_ij = view(myim, i:i+window_size,j:j+window_size)
        ncells = count(datahab_ij .> 0)
        if ncells > 0
            datatemp_ij = view(mytemp, i:i+window_size,j:j+window_size)
            verbose && println(ncells, " cells of habitats ", habitat, " were found")
            g, B = extract_graph_1km(datahab_ij, area_threshold)
            # calculating metrics
            raster["sqrtk"][ii,jj] = sqrtk(g)
            raster["assortativity"][ii,jj] = assortativity(g, datatemp_ij[B])
            # storing graph
            # raster_g[ii,jj] = g

            if verbose
                println("sqrtk = ", raster["sqrtk"][ii,jj])
                println("assortativity = ", raster["assortativity"][ii,jj])
            end
        end
    end
end