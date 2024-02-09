using JuMP
using GLPK
include("vrp.jl")

n = 50
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
model = createTSPModel(C)
set_optimizer(model, GLPK.Optimizer)
set_optimizer_attribute(model, "msg_lev", GLPK.GLP_MSG_ALL)
sol = optimize!(model)
graphVRP(sol, x=P[:, 1], y=P[:, 2], linetype = "straight")