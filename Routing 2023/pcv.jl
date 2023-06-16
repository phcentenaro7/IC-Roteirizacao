using JuMP
using GLPK
using Gurobi
using BenchmarkTools
using Graphs
using GraphPlot
using Colors
using Combinatorics
include("costmatrix.jl")

n = 12
P = rand(-1000:1000, n, 2)
C = createSymmetricalCostMatrix(P[:, 1], P[:, 2])
program = Model(Gurobi.Optimizer)
@variable(program, X[1:n, 1:n], Bin)
@objective(program, Min, sum(X .* C))
@constraint(program, [i = 1:n], sum(X[i, j] for j = 1:n) == 1)
@constraint(program, [j = 1:n], sum(X[i, j] for i = 1:n) == 1)
for S ∈ combinations(1:n)
    length_S = length(S)
    if length_S == n
        break
    end
    @constraint(program, sum(X[i, j] for i ∈ S, j ∈ S) <= length_S - 1)
end
optimize!(program)