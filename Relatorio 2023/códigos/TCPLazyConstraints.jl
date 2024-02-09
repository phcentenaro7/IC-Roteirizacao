function createTSPModel(C ;optimizer=GLPK.Optimizer)
    n = size(C, 1)
    model = Model()
    @variable(model, X[1:n, 1:n], Bin)
    @objective(model, Min, sum(C .* X))
    @constraint(model, [i = 1:n], sum(X[i, 1:n]) == 1)
    @constraint(model, [j = 1:n], sum(X[1:n, j]) == 1)
    @constraint(model, [i in 1:n], X[i, i] == 0)
    function callbackRemoveSubcycles(data)
        status = callback_node_status(data, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return
        end
        S = findSubcycles(callback_value.(data, model[:X]))
        for s in S
            if 1 < length(s) < n
                constraint = @build_constraint(sum(model[:X][i, j] for i in s, j in s) <= length(s) - 1)
                MOI.submit(model, MOI.LazyConstraint(data), constraint)
            end
        end
    end
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycle)
    return model
end