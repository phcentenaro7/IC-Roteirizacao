using Graphs
using GraphPlot
using Colors

g = SimpleDiGraph(4)
add_edge!(g, 1, 3)
add_edge!(g, 3, 2)
add_edge!(g, 2, 4)
add_edge!(g, 4, 1)
nodelabel = 1:nv(g)
nodecolorlist = [1, 2, 2, 2]
nodecolors = [colorant"darkseagreen2", colorant"springgreen"]
nodefillc = nodecolors[nodecolorlist]
edgecolorlist = [1, 1, 2, 2]
edgecolors = [colorant"red", colorant"blue"]
edgestrokec = edgecolors[edgecolorlist]
gplot(g, nodelabel=nodelabel, nodefillc=nodefillc, edgestrokec=edgestrokec, linetype="curve")