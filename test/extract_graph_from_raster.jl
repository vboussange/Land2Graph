using Test
cd(@__DIR__)
include("../src/extract_graph_from_raster.jl")

N = [0 1 0; 1 0 1;0 1 0] #raster matrix
g = extract_graph(N)
@test nv(g) == 4
@test ne(g) == 4

# gplot(g, nodelabel = 1:nv(g))

N = [1 1 1; 1 0 1;1 1 1] #raster matrix
g = extract_graph(N)
@test nv(g) == 8
@test ne(g) == 12

# gplot(g, nodelabel = 1:nv(g))
for _ in 1:10
    N = rand([0,1],10,10)
    g = extract_graph(N)
    @test typeof(g) <: SimpleGraph
end
# gplot(g)