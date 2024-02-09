using JuMP
using Gurobi
using CPLEX
using GLPK
using Fontconfig
using Cairo
include("cvrp.jl")

##TSP
n = 50
P = rand(-1000:10:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = Model(Gurobi.Optimizer)
createTSPModel!(model, :DFJ, C)
set_attribute(model, MOI.TimeLimitSec(), 600)
optimize!(model)
graphTSP(model, colorant"green", P[:, 1], P[:, 2], linetype = "straight")

#=##CVRP
n = 15
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = Model(Gurobi.Optimizer)
W = 10
Q = vcat([0], ones(14))
createCVRPModel!(model, W, C, Q)
set_attribute(model, MOI.TimeLimitSec(), 500)
optimize!(model)
#graphVRP(model, [colorant"red", colorant"blue", colorant"green", colorant"pink", colorant"brown"], P[:, 1], P[:, 2], linetype = "straight")=#