using Caique

c = [2, 3] #vetor de custos
A = [-4 3; 2 1; 1 1; 5 1] #matriz de restrições
s = [:less, :less, :greater, :greater] #vetor de sinais
b = [12, 6, 3, 4] #vetor de valores do lado direito
lp = LinearProgram(c, A, s, b) #problema linear
solution = solve(lp, type=:max) #solução do problema
println(solution.iB) #índices das variáveis básicas
println(solution.xB) #valores das variáveis básicas
println(solution.z) #valor ótimo da função objetivo