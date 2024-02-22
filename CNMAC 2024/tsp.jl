##

using Graphs
using GraphPlot
using Compose
using Colors
using Match
using JuMP
using Cairo
using Fontconfig
include("costmatrix.jl")
include("Modelos/dfj.jl")
include("Modelos/mtz.jl")
include("Modelos/gg.jl")

function createTSPModel!(model, type, C)
    @match type begin
        :DFJ => createDFJTSP(model, C)
        :MTZ => createMTZTSP(model, C)
        :GG => createGGTSP(model, C)
    end
    return model
end

function createTSPModel(type, C; optimizer=GLPK.Optimizer)
    model = Model(optimizer)
    createTSPModel!(model, type, C)
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