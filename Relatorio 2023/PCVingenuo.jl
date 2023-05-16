function createTSPModel(C)
    n = size(C, 1)
    model = Model()
    @variable(model, X[1:n, 1:n], Bin)
    @objective(model, Min, sum(C .* X))
    @constraint(model, [i = 1:n], sum(X[i, 1:n]) == 1)
    @constraint(model, [j = 1:n], sum(X[1:n, j]) == 1)
    for S in combinations(1:n)
        if length(S) == n
            break
        end
        @constraint(model, sum(X[S, S]) <= length(S) - 1)
    end
    return model
end