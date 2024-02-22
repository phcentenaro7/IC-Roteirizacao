using JLD2
using JuMP
using GLPK
using CPLEX
using Gurobi
using BenchmarkTools
using Plots
using Printf
using LaTeXStrings
include("tsp.jl")

function testProblem(filename, optimizers, formulations, time_limit)
    solve_times = Float64[]
    @load filename points
    C = createSymmetricalCostMatrix(points[:, 1], points[:, 2])
    for optimizer in optimizers
        model = Model(optimizer)
        set_silent(model)
        set_attribute(model, MOI.TimeLimitSec(), time_limit)
        for formulation in formulations
            createTSPModel!(model, formulation, C)
            println("$optimizer solving $filename ($(size(points, 1)) points) using $formulation.")
            optimize!(model)
            push!(solve_times, solve_time(model))
            empty!(model)
        end
    end
    return solve_times
end

function testProblems(ntests::Int, nsets::Int, prefix::String; optimizers=[GLPK.Optimizer, CPLEX.Optimizer, Gurobi.Optimizer], formulations=[:DFJ, :MTZ, :GG], time_limit=60)
    solve_times = Array{Float64}(undef, 0, length(optimizers) * length(formulations))
    for set in 1:nsets
        results = []
        for test in 1:ntests
            filename = "$prefix"*"$('A' + set - 1)"*"$test.jld2"
            @load filename points
            results = testProblem(filename, optimizers, formulations, time_limit)
            solve_times = vcat(solve_times, results')
        end
    end
    return solve_times
end

function solveTimesToTable(ntests::Int, nsets::Int, T::Matrix{Float64}, time_limit::Int, filename::String)
    file = open(filename, "w")
    ncols = size(T, 2)
    i = 1
    for set in 1:nsets
        for test in 1:ntests
            textline = "$('A' + set - 1)$test & "
            for j in 1:ncols
                num = T[i, j] > time_limit ? "--" : "\$"*@sprintf("%.3f", T[i, j])*"\$"
                if j == ncols
                    textline = textline * @sprintf("%s\\\\\n", num)
                else
                    textline = textline * @sprintf("%s & ", num)
                end
            end
            write(file, textline)
            i = i + 1
        end
    end
    close(file)
end

function createRatioMatrix(T::Matrix{Float64})
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

function plotPerformanceProfiles(perf::Vector{Function}, labels::Vector{String}, rM::Real; legend=:bottomright)
    p = plot([], [], label="")
    id = 1
    for rho in perf
        plot!(p, rho, label=labels[id], linestyle=:dash, linewidth=2,
            xlims=[1, rM], ylims=[0, 1.05], xticks = 1:rM, grid=true, gridalpha=0.5,
            xlabel=L"\tau", ylabel=L"\rho", legend=legend)
        id = id + 1
    end
    return p
end



# P = loadSamples("perfsets100.jld2")
# optimizers = [#=GLPK.Optimizer,=# Gurobi.Optimizer, CPLEX.Optimizer]
# solvernames = [#="GLPK",=# "Gurobi", "CPLEX"]
# T, R, perf, p = compareSolvers(P, optimizers, solvernames, 10, verbose=true);
# p