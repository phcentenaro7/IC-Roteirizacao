using JLD2
using GLPK
using CPLEX
using Gurobi
using BenchmarkTools
using Plots
include("tsp.jl")

function loadSamples(filename::String)
    @load filename P
    return P
end

function createCostMatrices(P::Vector{Matrix{Float64}})
    C::Vector{Matrix{Float64}} = []
    for p in P
        push!(C, createSymmetricalCostMatrix(p[:, 1], p[:, 2]))
    end
    return C
end

function calculateSampleOptimizationTimes(optimizer::DataType, C::Vector{Matrix{Float64}}; verbose=false, solvername="")
    t::Vector{Float64} = []
    i = 1
    model = Model(optimizer)
    MOI.set(model, MOI.Silent(), true)
    for c in C
        empty!(model)
        createTSPModel!(model, c)
        if verbose
            println("$solvername solving problem $i/$(length(C))")
        end
        optimize!(model)
        tp = solve_time(model)
        push!(t, tp)
        i += 1
    end
    return t
end

function createSampleRatioMatrix(T::Matrix{Float64})
    rows = size(T, 1)
    cols = size(T, 2)
    R = Array{Float64}(undef, 0, cols)
    for i in 1:rows
        bestrate = minimum(T[i, :])
        newrow = (T[i, :] ./ bestrate)'
        R = vcat(R, newrow)
    end
    sort!(R, dims = 1)
    return R
end

function createPerformanceProfiles(R::Matrix{Float64})
    perf::Vector{Function} = []
    np = size(R, 1)
    ns = size(R, 2)
    for j in 1:ns
        r = R[:, j]
        rho(tau) = count(<=(tau), r) / np
        push!(perf, rho)
    end
    return perf
end

function plotPerformanceProfiles(perf::Vector{Function}, solvernames::Vector{String}, rM::Real; legend=:bottomright)
    p = plot([], [], label="")
    solverid = 1
    for rho in perf
        style = @match isodd(solverid) begin
            true => :dash
            false => :solid
        end
        plot!(p, rho, label=solvernames[solverid], linestyle=style, linewidth=2,
            xlims=[1, rM], ylims=[0, 1.05], xticks = 1:rM, grid=true, gridalpha=0.5,
            xlabel="τ", ylabel="ρ", legend=legend)
        solverid += 1
    end
    return p
end

function compareSolvers(P::Vector{Matrix{Float64}}, optimizers::Vector{DataType}, solvernames::Vector{String}, rM::Real; verbose=false, legend=:bottomright)
    np = length(P)
    C = createCostMatrices(P)
    T = Array{Float64}(undef, np, 0)
    solverid = 1
    for optimizer in optimizers
        t = calculateSampleOptimizationTimes(optimizer, C, verbose=verbose, solvername=solvernames[solverid])
        T = hcat(T, t)
        solverid += 1
    end
    R = createSampleRatioMatrix(T)
    perf = createPerformanceProfiles(R)
    p = plotPerformanceProfiles(perf, solvernames, rM, legend=legend)
    return T, R, perf, p
end

P = loadSamples("perfsets100.jld2")
optimizers = [#=GLPK.Optimizer,=# Gurobi.Optimizer, CPLEX.Optimizer]
solvernames = [#="GLPK",=# "Gurobi", "CPLEX"]
T, R, perf, p = compareSolvers(P, optimizers, solvernames, 10, verbose=true);
p