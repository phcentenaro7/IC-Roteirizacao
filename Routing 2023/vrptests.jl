using JuMP
using GLPK
include("vrp.jl")

n = 50
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = createTSPModel(C)
set_optimizer(model, Gurobi.Optimizer)
set_attribute(model, MOI.TimeLimitSec(), 500)
sol = optimize!(model)
graphVRP(sol, x=P[:, 1], y=P[:, 2], linetype = "straight")