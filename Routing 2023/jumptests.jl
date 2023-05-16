using JuMP
using GLPK
using BenchmarkTools

program = Model()
set_optimizer(program, GLPK.Optimizer)

@variable(program, x1 >= 0)
@variable(program, x2 >= 0)

@constraint(program, x1 + 2*x2 <= 4)
@constraint(program, x2 <= 1)

@objective(program, Min, x1 + x2)

@btime optimize!(program)