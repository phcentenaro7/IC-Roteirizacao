function callbackRemoveSubcycle(data, model)
    X = value.(model[:X])
    n = size(X, 1)
    status = callback_node_status(data, model)
    if status != MOI.CALLBACK_NODE_STATUS_INTEGER
        return
    end
    S = findShortestSubcycle(X)
    if !(1 < length(S) < n)
        return
    end
    constraint = @build_constraint(sum(model[:X][S, S]) < length(S))
    MOI.submit(model, MOI.LazyConstraint(data), constraint)
end