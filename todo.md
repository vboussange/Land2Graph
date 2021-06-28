# TODO

## Script
- Read the 1km dataset
- slice it in windows of 100x100km
- perform a loop over those windows, from which graphs are extracted
    - let's first consider only one type of habitats (say `lvl2_frac_1km_ver004/iucn_habitatclassification_fraction_lvl2__104_Forest – Temperate__ver004.tif`)
    - extract the graphs in an array, by considering that nodes are connected if neighbours (consider 8 neihbours, i.e. direct neighbours and diagonal)
    > for this, use LightGraphs.jl. See example
```julia
using LightGraphs
A = [0 1; 1 0] # adjacency matrix
g = SimpleGraph(A)
```
    - compute betweenness_centrality for each of the graph, and the average for the window
```julia
using Statistics
mean(betweenness_centrality(g))
```
- recreate a raster with average of betweenness_centrality for each 100x100km window



## questions
- What is the difference between `iucn_habitatclassification_composite_lvl1_ver004` and `lvl1_frac_1km_ver004`?
> For me, composite shows all data and frac_1km shows data for each habitat aggregated at 1 km

- Whate is `lvl2_changemasks_ver004.zip` and `lvl2_frac_change_1km_ver004.zip`?


- what are the values inside the rasters? I do not understand

