N = [0 1 0; 1 0 1;0 1 0] #raster matrix
A = similar(N) # adjacency matrix

function extract_adjacency_from_raster(N)
    s1 = size(N,1)
    s2 = size(N,2)
    _li = LinearIndices(N)
    A = zeros(Bool,length(N), length(N))
    for i in 1:s1-1, j in 1:s2-1
        @show i, j
        if N[i,j] !== 0 # cell is not empty
            if i == 1
                offset = [(1,0), (0, 1), (1,1)]
            else
                offset = [(1,0), (-1, 1), (0, 1), (1,1)]
            end
            for _o in offset
                if N[i + _o[1], j + _o[2]] !== 0 # neighbour not empty?
                    A[ _li[i, j], _li[ i + _o[1], j + _o[2] ] ] = A[_li[ i + _o[1], j + _o[2] ],  _li[i, j],] = true 
                end
            end
        end
    end
    return A
end

A = extract_adjacency_from_raster(N)
using LightGraphs, GraphPlot
g = SimpleGraph(A)
gplot(g)
# need to reduce the graph to only those points of interest
gplot(g[LinearIndices(N)[N .== 1]])