function findSubcycles(X::Matrix{Float64})
    n = size(X, 1)
    unchecked = collect(2:n)
    path = [1]
    now = 1
    subcycles = []
    while true
        next = findfirst(x -> x > 0.5, X[now, :])
        if next == path[1]
            push!(subcycles, path)
            if length(unchecked) == 0
                return subcycles
            end
            now = unchecked[1]
            unchecked = unchecked[2:end]
            path = [now]
            continue
        end
        setdiff!(unchecked, [next])
        push!(path, next)
        now = next
    end
end