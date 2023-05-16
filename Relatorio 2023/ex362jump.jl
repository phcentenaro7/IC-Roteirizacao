using JuMP
using GLPK

lp = Model(GLPK.Optimizer)
@variable(lp, x[1:2] ≥ 0)
@objective(lp, Max, 2x[1] + 3x[2])
@constraint(lp, -4x[1] + 3x[2] ≤ 12)
@constraint(lp, 2x[1] + x[2] ≤ 6)
@constraint(lp, x[1] + x[2] ≥ 3)
@constraint(lp, 5x[1] + x[2] ≥ 4)
optimize!(lp)
println(value.(lp[:x]))
print(objective_value(lp))