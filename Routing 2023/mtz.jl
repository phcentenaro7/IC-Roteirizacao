function createMTZTSP(model, C)
    n = size(C, 1)
    @variable(model, X[1:n, 1:n], Bin)
    @variable(model, u[2:n], Int)
    @objective(model, Min, sum(C .* X) / 2)
    @constraint(model, [i in 1:n], sum(X[i, 1:n]) == 1)
    @constraint(model, [j in 1:n], sum(X[1:n, j]) == 1)
    @constraint(model, [j in 2:n, i in 2:n, i != j], u[i] - u[j] + n*X[i, j] <= n - 1)
end