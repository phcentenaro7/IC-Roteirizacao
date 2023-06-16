using JLD2

let
    ntests = 30
    npoints = 50
    P::Vector{Matrix{Float64}} = []

    for i in 1:ntests
        newP = rand(-1000:1000, npoints, 2)
        push!(P, newP)
    end

    @save "perfsets50.jld2" P
end