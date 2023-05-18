##

using Graphs
using GraphPlot
using Compose
using Colors
using Match
using JuMP

function createSymmetricalCostMatrix(xcoords::Vector, ycoords::Vector)
    n = length(xcoords)
    C = zeros(n, n)
    for i in 1:n
        for j in (i+1):n
            d = sqrt((xcoords[i] - xcoords[j])^2 + (ycoords[i] - ycoords[j])^2)
            C[i, j] = d
            C[j, i] = d
        end
    end
    return C
end

function createTSPModel!(model, C)
    n = size(C, 1)
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
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycles)
end

function createTSPModel(C; optimizer=GLPK.Optimizer)
    model = Model(optimizer)
    createTSPModel!(model, C)
    return model
end

function findSubcycles(X::Matrix{Float64})
    n = size(X, 1)
    unchecked = collect(2:n)
    path = [1]
    now = 1
    subcycles = []
    while true
        next = findfirst(x -> x > 0.5, X[now, :])
        if next == path[1]
            push!(subcycles, path)
            if length(unchecked) == 0
                return subcycles
            end
            now = unchecked[1]
            unchecked = unchecked[2:end]
            path = [now]
            continue
        end
        setdiff!(unchecked, [next])
        push!(path, next)
        now = next
    end
end

function graphVRP(X::Array; x=[], y=[], linetype="curve", labelnodes=false, saveas="", nodesize=1.0)
    n = size(X, 1)
    K = size(X, 3)
    g = SimpleDiGraph(n)
    nodefills = vcat(2, ones(Int, n - 1))
    nodecolors = [colorant"skyblue", colorant"indigo"]
    nodefillc = nodecolors[nodefills]
    nodelabel = collect(0:nv(g)-1)
    nodesizes = nodesize * ones(n)
    for k in 1:K
        E = findall(x -> x > 0.5, X[:, :, k])
        for e in E
            add_edge!(g, e[1], e[2])
        end
    end
    graph = gplot(g, x, y, edgestrokec=colorant"black", nodesize=nodesizes, nodelabel=nodelabel, NODELABELSIZE=2, nodefillc=nodefillc, arrowlengthfrac = 0.03, linetype=linetype)
    if saveas != ""
        draw(PDF(saveas, 16cm, 16cm), graph)
    end
    graph
end

graphVRP(vrp::Model; x=[], y=[], nodesize=1.0, linetype="curve", labelnodes=false, saveas="") = graphVRP(value.(vrp[:X]), x=x, y=y, nodesize=nodesize, linetype=linetype, labelnodes=labelnodes, saveas=saveas)