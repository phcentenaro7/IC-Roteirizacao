function createCVRPModel!(model, C, K, cap, dem)
    n = size(C, 1)
    P = 1:n
    Ps = 2:n
    V = 1:K
    v(S) = ceil(sum(dem[S]) / cap)
    @variable(model, X[1:n, 1:n, 1:K], Bin)
    @objective(model, Min, sum(C .* X) / 2) #2a
    @constraint(model, sum(X[1, j, k] for j in Ps, k in V) == K) #2b
    @constraint(model, [k = V], sum(X[1, j, k] for j in Ps) == sum(X[j, 1, k] for j in Ps)) #2c
    @constraint(model, [k = V], sum(X[1, j, k] for j in Ps) == 1) #2c
    @constraint(model, [i = Ps], sum(X[i, j, k] for j in P, k in V) == 1) #2d
    @constraint(model, [k = V, i = Ps], sum(X[i, j, k] for j in P) - sum(X[j, i, k] for j in P) == 0) #2e
    @constraint(model, [k = V], sum(dem[i]*X[i, j, k] for i in Ps, j in setdiff(P, i)) <= cap)
    @constraint(model, [i = P, k = V], X[i, i, k] == 0)
    function callbackRemoveSubcycles(data)
        status = callback_node_status(data, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return
        end
        S = findSubcyclesVRP(callback_value.(data, model[:X]), n, K, cap, dem)
        for s in S
            constraint = @build_constraint(sum(model[:X][i, j, k] for i in s, j in s, k in V) <= length(s) - v(s))
            MOI.submit(model, MOI.LazyConstraint(data), constraint)
        end
    end
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycles)
end