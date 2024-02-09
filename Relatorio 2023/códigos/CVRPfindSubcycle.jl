function findSubcyclesVRP(edges::Vector{Tuple{Int, Int, Int}}, X::Array{Float64, 3}, n, K, cap, dem)
    visited = Set()
    subcycles = []
    for k in 1:K
        setdiff!(visited, 1)
        unvisited = setdiff(Set(collect(1:n)), visited)
        for i in unvisited
            if iszero(X[i, :, k])
                setdiff(unvisited, i)
            end
        end
        while !isempty(unvisited)
            thisCycle, neighbors = Int[], unvisited
            while !isempty(neighbors)
                current = pop!(neighbors)
                push!(thisCycle, current)
                if length(thisCycle) > 1
                    next = pop!(unvisited, current)
                    push!(visited, next)
                end
                neighbors = [j for (i, j, k) in edges if i == current && j in unvisited]
            end
            if !(1 in thisCycle) || (sum(dem[thisCycle]) > cap && length(thisCycle) >= 2)
                setdiff!(thisCycle, 1)
                push!(subcycles, thisCycle)
            end
        end
        if !isempty(subcycles)
            return subcycles
        end
    end
end