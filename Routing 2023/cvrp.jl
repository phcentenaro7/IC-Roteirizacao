#= #gplot expects edgestrokec to be ordered like
    #[color(0->1), color(0->2),...,color(0->n),color(1->0),color(1->1),...,color(1->n),...]
    for k in 1:K
        colorsum = colorsum + k*rX
        E = findall(isone, rX)
        for e in E
            add_edge!(g, e[1], e[2])
        end
    end
    for i in 1:n
        for j in 1:n
            id = colorsum[i, j]
            if id != 0
                push!(edgecolors, routecolors[id])
            end
        end
    end =#

using Graphs
using GraphPlot
using Compose
using Colors
using Match
using JuMP
using Combinatorics
include("costmatrix.jl")
include("tsp.jl")

function createCVRPModel!(model, C, K, cap, dem)
    n = size(C, 1)
    P = 1:n
    Ps = 2:n
    V = 1:K
    v(S) = ceil(sum(dem[S]) / cap)
    @variable(model, X[1:n, 1:n, 1:K], Bin)
    @variable(model, u[1:n])
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
            depot_constraint = @build_constraint(sum(model[:X][i, j, k] for i in s, j in s, k in V) <= length(s) - v(s))
            MOI.submit(model, MOI.LazyConstraint(data), depot_constraint)
        end
    end
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycles)
end

function getEdges(X::Array{Float64, 3})
    xij = findall(x -> x > 0.5, X)
    edges::Vector{Tuple{Int, Int, Int}} = []
    for x in xij
        push!(edges, (toInt(x[1]), toInt(x[2]), toInt(x[3])))        
    end
    return edges
end

function findSubcyclesVRP(edges::Vector{Tuple{Int, Int, Int}}, X::Array{Float64, 3}, n, K, cap, dem)
    v(S) = ceil(sum(dem[S]) / cap)
    visited = Set()
    subcycles = []
    for k in 1:K
        setdiff!(visited, 1)
        unvisited = setdiff(Set(collect(1:n)), visited)
        for i in unvisited
            if iszero(X[i, :, k])
                setdiff(unvisited, i)
            end
        end
        while !isempty(unvisited)
            thisCycle, neighbors = Int[], unvisited
            while !isempty(neighbors)
                current = pop!(neighbors)
                push!(thisCycle, current)
                if length(thisCycle) > 1
                    next = pop!(unvisited, current)
                    push!(visited, next)
                end
                neighbors = [j for (i, j, k) in edges if i == current && j in unvisited]
            end
            has_depot = 1 in thisCycle
            if !has_depot
                setdiff!(thisCycle, 1)
                push!(subcycles, thisCycle)
            end
        end
    end
    return subcycles
end

findSubcyclesVRP(X::Array{Float64, 3}, n, K, cap, dem) = findSubcyclesVRP(getEdges(X), X, n, K, cap, dem)

function graphVRP(X::Array, routecolors, x, y; linetype="curve", saveas="")
    n = size(X, 1)
    K = size(X, 3)
    g = SimpleDiGraph(n)
    nodefills = vcat(2, ones(Int, n - 1))
    nodecolors = [colorant"skyblue", colorant"indigo"]
    nodefillc = nodecolors[nodefills]
    nodelabel = collect(0:nv(g)-1)
    rX = Int.(round.(X))
    colorsum = zeros(Int, n, n)
    edgecolors = []
    #gplot expects edgestrokec to be ordered like
    #[color(0->1), color(0->2),...,color(0->n),color(1->0),color(1->1),...,color(1->n),...]
    for k in 1:K
        colorsum = colorsum + k*rX[:, :, k]
        E = findall(isone, rX[:, :, k])
        for e in E
            add_edge!(g, e[1], e[2])
        end
    end
    for i in 1:n
        for j in 1:n
            id = colorsum[i, j]
            if id != 0
                push!(edgecolors, routecolors[id])
            end
        end
    end
    graph = gplot(g, x, y, edgestrokec=edgecolors, nodelabel=nodelabel, NODELABELSIZE=3, nodefillc=nodefillc, arrowlengthfrac = 0.05, linetype=linetype)
    if saveas != ""
        draw(PDF(saveas, 16cm, 16cm), graph)
    end
    graph
end

graphVRP(vrp::Model, routecolors, x, y; linetype="curve", saveas="") = graphVRP(value.(vrp[:X]), routecolors, x, y, linetype=linetype, saveas=saveas)