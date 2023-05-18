using JLD2
using GLPK
using CPLEX
using Gurobi
using BenchmarkTools
using Plots
include("vrp.jl")

function solveSampleProblem(model, optstr, iter)
    println("$optstr solving $iter")
    tps = @belapsed optimize!($model) samples = 1
    push!(ts[optstr], tps)
end

function graphProfiles(r, ntests, maxtau)
    R = 1/ntests
    percents = repeat(collect(0:R:1), inner=2)
    p = plot()
    for (name, vector) in r
        if vector == []
            continue
        end
        plotvector = vcat([1], repeat(vector, inner=2), maxtau)
        plot!(p, plotvector, percents, label=name, linestyle=:dash)
    end
    return p
end

@load "performancesets100points.jld2" ntests npoints P
optimizers = Dict([#=("GLPK", GLPK.Optimizer),=# ("CPLEX", CPLEX.Optimizer), ("Gurobi", Gurobi.Optimizer)])
ts = Dict([("GLPK", []), ("CPLEX", []), ("Gurobi", [])])
costs = []

for i in 1:ntests
    C = createSymmetricalCostMatrix(P[i][: , 1], P[i][:, 2])
    push!(costs, C)
end

model = Model()

for i in optimizers
    set_optimizer(model, i[2])
    for j in 1:ntests
        empty!(model)
        createTSPModel!(model, costs[j])
        MOI.set(model, MOI.Silent(), true)
        solveSampleProblem(model, i[1], j)
    end
end

best = minimum(vcat(ts["GLPK"], ts["CPLEX"], ts["Gurobi"]))
r = Dict([("GLPK", ts["GLPK"] ./ best), ("CPLEX", ts["CPLEX"] ./ best), ("Gurobi", ts["Gurobi"] ./ best)])
worstr = maximum(vcat(r["GLPK"], r["CPLEX"], r["Gurobi"]))
sort!(r["GLPK"])
sort!(r["CPLEX"])
sort!(r["Gurobi"])

@save "performancetest.jld2" ts r best

p = graphProfiles(r, ntests, worstr + 1)