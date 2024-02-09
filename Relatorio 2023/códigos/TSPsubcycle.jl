function getEdges(X::Matrix{Float64})
    xij = findall(x -> x > 0.5, X)
    edges::Vector{Tuple{Int, Int}} = []
    for x in xij
        push!(edges, (toInt(x[1]), toInt(x[2])))        
    end
    return edges
end

function findSubcyclesTSP(edges::Vector{Tuple{Int, Int}}, n::Int)
    unvisited = Set(collect(1:n))
    shortest = collect(1:n)
    while !isempty(unvisited)
        thisCycle, neighbors = Int[], unvisited
        while !isempty(neighbors)
            current = pop!(neighbors)
            push!(thisCycle, current)
            if length(thisCycle) > 1
                pop!(unvisited, current)
            end
            neighbors =
                [j for (i, j) in edges if i == current && j in unvisited]
        end
        if 1 < length(thisCycle) < length(shortest)
            shortest = thisCycle
        end
    end
    return shortest
end