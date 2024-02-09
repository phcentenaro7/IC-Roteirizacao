using Graphs
using GraphPlot
using Compose
using Colors
using Match
using JuMP
using LinearAlgebra
include("costmatrix.jl")
include("tsp.jl")

function createCVRPModel!(model, W, C, Q)
    n = size(C, 1)
    Ps = collect(1:n-1) #Permutable vertices
    @variable(model, 0 <= X[1:n,1:n] <= 1, Int)
    set_upper_bound.(X[n, :], 2)
    @variable(model, V == 2, Int)
    @objective(model, Min, sum(LowerTriangular(C) .* LowerTriangular(X)))
    @constraint(model, sum(X[n,j] for j in Ps) == 2*V)
    @constraint(model, test[k = Ps], sum(X[i,k] for i in collect(k+1:n)) + sum(X[k,i] for i in collect(1:k-1)) == 2)
    function callbackRemoveSubcycles(cbdata)
        status = callback_node_status(cbdata, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return
        end
        l(S) = ceil(1/W * sum(Q[j] for j in S))
        sets = findSubcyclesVRP(callback_value.(cbdata, X))
        Sfail = []
        for S in sets
            if !(3 <= length(S) <= n - 2)
                continue
            end
            Vcb = callback_value(cbdata, V)
            Xcb = callback_value.(cbdata, X)
            success = CVRPsearch(Xcb, S, n, l, Vcb, model, cbdata)
            if !success
                push!(failed_sets, S)
            end
        end
        if (k = length(Sfail)) > 0
            r(R) = sum(X[i,j] for i in R, j in R) + sum(X[n,j] for j in R) - length(R)
            Z(R) = V - r(R) - l(setdiff(Ps, R))
            R = []
            i = 1
            MIN = Inf
            while i < k
                union!(R, Sfail[i])
                if (MIN = Z(R)) < 0
                    Snot = setdiff(Ps, S)
                    constraint = @build_constraint(sum(X[i,j] for i in S, j in Snot) + sum(X[i,j] for i in Snot, j in S) + sum(X[n,i] for i in Snot) >= 2*l(Snot))
                    MOI.submit(model, MOI.LazyConstraint(cbdata), constraint)
                    R = []
                    MIN = Inf
                end
                i = i + 1
            end
        end
    end
    set_attribute(model, MOI.LazyConstraintCallback(), callbackRemoveSubcycles)
end

function findSubcyclesVRP(edges::Vector{Tuple{Int, Int}}, n::Int)
    unvisited = Set(collect(1:n))
    subcycles = []
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

function CVRPsearch0(X, S, n, l, model, cbdata)
    if !(n in S)
        constraint = @build_constraint(sum(model[:X][i,j] for i in S, j in S) <= length(S) - l(S))
        MOI.submit(model, MOI.LazyConstraint(cbdata), constraint)
        return true
    end
    return false
end

function CVRPsearch1(X, S, l, model, cbdata)
    R = []
    function Z(R)
        D = setdiff(S, R) #S\R
        return length(D) - l(D) - sum(X[i,j] for i in D, j in D)
    end
    while length(R) < length(S) - 2
        D = setdiff(S, R) #S\R
        r = argmin(Z, union(R, r) for r in D)
        Rprime = union(R, [r])
        Dprime = setdiff(S, Rprime)
        if Z(Rprime) >= Z(R)
            break
        elseif Z(Rprime) < 0
            constraint = @build_constraint(sum(model[:X][i,j] for i in Dprime, j in Dprime) <= length(Dprime) - l(Dprime))
            MOI.submit(model, MOI.LazyConstraint(cbdata), constraint)
            return true
        else
            R = Rprime
        end
    end
    return false
end

function CVRPsearch2(X, S, n, l, V, model, cbdata)
    Ps = collect(1:n-1)
    function Z(R)
        Rnot = setdiff(Ps, R) #Ps\R
        return length(R) + V - ceil(1/W * sum(Q[j] for j in Rnot)) - sum(X[i,j] for i in R, j in R) - sum(X[n,j] for j in R)
    end
    R = []
    MIN = Inf
    while length(R) != length(S) - 1
        D = setdiff(S, R)
        r = argmin(Z, union(R, r) for r in D)
        Rprime = union(R, r)
        println(Rprime)
        if Z(Rprime) <= MIN
            R = Rprime
            MIN = Z(Rprime)
        end
    end
    if MIN < 0
        Snot = setdiff(Ps, S)
        constraint = @build_constraint(sum(model[:X][i,j] for i in S, j in Snot) + sum(model[:X][i,j] for i in Snot, j in S) + sum(model[:X][n,i] for i in Snot) >= 2*l(Snot))
        MOI.submit(model, MOI.LazyConstraint(cbdata), constraint)
        return true
    end
    return false
end

function CVRPsearch(X, S, n, l, V, model, cbdata)
    return CVRPsearch0(X, S, n, l, model, cbdata) | CVRPsearch1(X, S, l, model, cbdata) | CVRPsearch2(X, S, n, l, V, model, cbdata)
end

findSubcyclesVRP(X::Matrix{Float64}) = findSubcyclesVRP(getEdges(X), size(X, 1))