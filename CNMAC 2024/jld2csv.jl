using JLD2

for alpha in 'A':'D'
    for num in 1:10
        load("Problemas/Julia/problemset$(alpha)$(num).jld2")
        open("Problemas/CSV/problemset$alpha$num.csv", "w") do out
            println(out, "X,Y")
            for i in 1:size(points)[1]
                println(out, "$(points[i,1]),$(points[i,2])")
            end
        end
    end
end

open("Resultados/solve_times.csv", "w") do out
    @load "Resultados/solve_times.jld2"
    println(out, "GLPK-DFJ,GLPK-MTZ,GLPK-GG,CPLEX-DFJ,CPLEX-MTZ,CPLEX-GG,Gurobi-DFJ,Gurobi-MTZ,Gurobi-GG")
    for i in 1:size(solve_times)[1]
        for j in 1:size(solve_times)[2]
            print(out, solve_times[i,j])
            print(out, j != size(solve_times)[2] ? "," : "\n")
        end
    end
end

open("Resultados/solve_times50.csv", "w") do out
    @load "Resultados/solve_times50.jld2"
    println(out, "GLPK-DFJ,CPLEX-DFJ,Gurobi-DFJ")
    for i in 1:size(solve_times50)[1]
        for j in 1:size(solve_times50)[2]
            print(out, solve_times50[i,j])
            print(out, j != size(solve_times50)[2] ? "," : "\n")
        end
    end
end