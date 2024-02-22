function createDFJTSP(model, C)
    n = size(C, 1)
    @variable(model, X[1:n, 1:n], Bin)
    @objective(model, Min, sum(C .* X) / 2)
    @constraint(model, [i in 1:n], sum(X[i, 1:n]) == 1)
    @constraint(model, [j in 1:n], sum(X[1:n, j]) == 1)
    @constraint(model, [i in 1:n], X[i, i] == 0)
    function callbackRemoveSubcycles(data)
        status = callback_node_status(data, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return
        end
        S = findSubcyclesTSP(callback_value.(data, model[:X]))
        if 1 < length(S) < n
            constraint = @build_constraint(sum(model[:X][i, j] for i in S, j in S) <= length(S) - 1)
            MOI.submit(model, MOI.LazyConstraint(data), constraint)
        end
    end
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycles)
end