using JuMP
using Gurobi
using CPLEX
using GLPK
include("vrp.jl")

n = 300
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = createTSPModel(C)
set_optimizer(model, CPLEX.Optimizer)
set_attribute(model, MOI.TimeLimitSec(), 600)
optimize!(model)
graphVRP(model, x=P[:, 1], y=P[:, 2], linetype = "straight")