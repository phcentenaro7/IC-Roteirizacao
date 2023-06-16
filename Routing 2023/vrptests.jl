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
createTSPModel!(model, C)
set_optimizer(model, Gurobi.Optimizer)
set_attribute(model, MOI.TimeLimitSec(), 600)
optimize!(model)
graphTSP(model, colorant"red", P[:, 1], P[:, 2], linetype = "straight")

##CVRP
n = 15
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = Model(Gurobi.Optimizer)
createCVRPModel!(model, C, 3, ceil(n/3), vcat(0, ones(n - 1)))
set_optimizer(model, Gurobi.Optimizer)
set_attribute(model, MOI.TimeLimitSec(), 500)
set_attribute(model, "LazyConstraints", 1)
set_attribute(model, "Threads", 1)
optimize!(model)
graphVRP(model, [colorant"red", colorant"blue", colorant"green", colorant"pink", colorant"brown"], P[:, 1], P[:, 2], linetype = "straight")