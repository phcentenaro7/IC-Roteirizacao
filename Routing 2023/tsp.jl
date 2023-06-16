##

using Graphs
using GraphPlot
using Compose
using Colors
using Match
using JuMP
include("costmatrix.jl")

function createTSPModel!(model, C)
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

function toInt(a::Real)
    return Int(round(a))
end

function getEdges(X::Matrix{Float64})
    xij = findall(x -> x > 0.5, X)
    edges::Vector{Tuple{Int, Int}} = []
    for x in xij
        push!(edges, (toInt(x[1]), toInt(x[2])))        
    end
    return edges
end

function findSubcyclesTSP(edges::Vector{Tuple{Int, Int}}, n::Int)
    subcycles, unvisited = [], Set(collect(1:n))
    while !isempty(unvisited)
        thisCycle, neighbors = Int[], unvisited
        while !isempty(neighbors)
            current = pop!(neighbors)
            push!(thisCycle, current)
            if length(thisCycle) > 1
                pop!(unvisited, current)
            end
            neighbors =
                [j for (i, j) in edges if i == current && j in unvisited]
        end
        push!(subcycles, thisCycle)
    end
    return subcycles
end

findSubcyclesTSP(X::Matrix{Float64}) = findSubcyclesTSP(getEdges(X), size(X, 1))

function graphTSP(X::Array, routecolor, x, y; linetype="curve", saveas="", nodesize=1.0)
    n = size(X, 1)
    g = SimpleDiGraph(n)
    nodefills = vcat(2, ones(Int, n - 1))
    nodecolors = [colorant"skyblue", colorant"indigo"]
    nodefillc = nodecolors[nodefills]
    nodelabel = collect(0:nv(g)-1)
    nodesizes = nodesize * ones(n)
    rX = Int.(round.(X))
    E = findall(isone, rX)
    for e in E
        add_edge!(g, e[1], e[2])
    end
    graph = gplot(g, x, y, edgestrokec=routecolor, nodesize=nodesizes, nodelabel=nodelabel, NODELABELSIZE=3, nodefillc=nodefillc, arrowlengthfrac = 0.03, linetype=linetype)
    if saveas != ""
        draw(PDF(saveas, 16cm, 16cm), graph)
    end
    graph
end

graphTSP(tsp::Model, routecolors, x, y; nodesize=1.0, linetype="curve", saveas="") = graphTSP(value.(tsp[:X]), routecolors, x, y, nodesize=nodesize, linetype=linetype, saveas=saveas)