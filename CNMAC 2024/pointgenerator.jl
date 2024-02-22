using JLD2

function generateTSPProblems(ntests::Int, npoints::Vector{Int}, path::String)
    for set in 1:length(npoints)
        for test in 1:ntests
            points = rand(-1000:1000, npoints[set], 2)
            filename = "$path/problemset"*"$('A' + set - 1)"*"$test.jld2"
            file = open(filename, "w")
            close(file)
            @save filename points
        end
    end
end