. -> Contém o gerador de pontos, um programa para gerar performance profiles e algumas ferramentas de PCV.

Modelos -> Contém os três modelos de PCV implementados em JuMP.

Problemas -> Contém 40 problemas aleatoriamente gerados, sendo 10 de 10 pontos (conjunto A), 10 de 15 pontos (conjunto B), 10 de 20 pontos (conjunto C) e 10 de 50 pontos (conjunto D). Os problemas podem ser obtidos em formato CSV ou em JLD2 (para serem carregados diretamente em linguagem Julia).

Resultados -> Contém os resultados dos 40 problemas para cada um dos solvers. O arquivo solve_times contém os resultados dos problemas A, B e C em sequência. Também é possível acessá-los tanto em CSV quanto em JLD2.