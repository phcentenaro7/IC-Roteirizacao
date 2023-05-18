using JLD2

let
    ntests = 5
    npoints = 100
    P::Vector{Matrix{Float64}} = []

    for i in 1:ntests
        newP = rand(-1000:1000, npoints, 2)
        push!(P, newP)
    end

    @save "performancesets100points.jld2" ntests npoints P
end