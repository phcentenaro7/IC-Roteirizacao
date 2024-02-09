function findSubcyclesTSP(edges::Vector{Tuple{Int, Int}}, n::Int)
    subcycles, unvisited = [], Set(collect(1:n))
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
        push!(subcycles, thisCycle)
    end
    return subcycles
end