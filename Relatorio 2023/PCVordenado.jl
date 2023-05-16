function createTSPModel(C ;optimizer=GLPK.Optimizer)
    n = size(C, 1)
    model = Model()
    @variable(model, X[1:n, 1:n], Bin)
    @variable(model, u[1:n], Int)
    @objective(model, Min, sum(C .* X))
    @constraint(model, [i = 1:n], sum(X[i, 1:n]) == 1)
    @constraint(model, [j = 1:n], sum(X[1:n, j]) == 1)
    @constraint(model, u[1] == 1)
    @constraint(model, [i = 2:n, j = 2:n], u[i] - u[j] + 1 ≤ n*(1 - X[i, j]))
    return model
end