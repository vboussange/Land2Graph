using LightGraphs

"""
    function extract_adjacency(N::BitMatrix)
Given `N` a matrix of suitable habitat (`true` if suitable habitat at index `i,j`), returns a graph.
Habitats are potentially connected to eight neighbours (left, diagonal left top, top, diagonal right top, etc...).
"""
function extract_adjacency(N)
    s1 = size(N,1)
    s2 = size(N,2)
    _li = LinearIndices(N)
    A = zeros(Bool,length(N), length(N))
    for i in 1:s1, j in 1:s2
        if N[i,j] # cell is not empty
            if i == s1 && j == s2
                break
            elseif i == s1
                padding = [(0, 1)]
            elseif j == 1
                padding = [(1, 0), (0, 1), (1,1)]
            elseif j == s2
                padding = [(1, -1), (1, 0)]
            else
                padding = [(0,1), (1, -1), (1, 0), (1,1)]
            end
            for _o in padding
                # @show _o
                if N[i + _o[1], j + _o[2]] # neighbour not empty?
                    A[ _li[i, j], _li[ i + _o[1], j + _o[2] ] ] = A[_li[ i + _o[1], j + _o[2] ],  _li[i, j],] = true 
                end
            end
        end
    end
    return A
end

"""
    function extract_graph(N, habitat = 1)
Extract graph from raster `N`, with habitat defined by value `habitat`
"""
function extract_graph(N, habitat = 1)
    B = N .== habitat
    A = extract_adjacency(B)
    g = SimpleGraph{Int16}(A)
    return g[LinearIndices(B)[B]]
end

"""
    function extract_graph_1km(N, area = 0)
Extract graph from fractional raster `N`, given threshold `area`
return graph and coordinate BitMatrix for habitats
"""
function extract_graph_1km(N, area = 0)
    B = N .> area
    A = extract_adjacency(B)
    g = SimpleGraph{Int16}(A)
    return g[LinearIndices(B)[B]], B
end
