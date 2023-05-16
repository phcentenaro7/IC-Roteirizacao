using JuMP
using GLPK
using BenchmarkTools
using Graphs
using GraphPlot
using Colors
using Combinatorics

C = [0 2 5 9 6; 1 0 2 3 4 ; 3 3 0 3 7; 6 5 6 0 5; 9 4 3 2 0]
n = size(C, 1)
program = Model(GLPK.Optimizer)
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