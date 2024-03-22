using Plots

# Parâmetros
Q = 130  # Quantidade vendida em contrato (kg)
g_ω1 = 115  # Quantidade de ouro produzido no cenário ω1 (kg)
g_ω2 = 80  # Quantidade de ouro produzido no cenário ω2 (kg)
P = 120  # Preço fixo pago pela China por kg de ouro ($/kg)
π_C = 600  # Preço de compra no mercado internacional em caso de déficit ($/kg)
π_V = 12  # Preço de venda no mercado internacional em caso de excesso ($/kg)

# ============================     Item (a)     ============================== #

function calcular_receita(Q, g, P, π_C, π_V)
    return P * Q - π_C * max(0, Q - g) + π_V * max(0, g - Q)
end

# Calculando a receita para cada cenário
receita_ω1 = calcular_receita(Q, g_ω1, P, π_C, π_V)
receita_ω2 = calcular_receita(Q, g_ω2, P, π_C, π_V)

println("Receita no cenário ω1: \$", receita_ω1)
println("Receita no cenário ω2: \$", receita_ω2)

# ============================     Item (b)     ============================== #

Q_list = collect(0:Q);
receita_ω1_list = []
receita_ω2_list = []

for q in Q_list
    append!(receita_ω1_list, calcular_receita(q, g_ω1, P, π_C, π_V))
    append!(receita_ω2_list, calcular_receita(q, g_ω2, P, π_C, π_V))
end

R1max, Q1max = findmax(receita_ω1_list)
R2max, Q2max = findmax(receita_ω2_list)

println("Receita máxima no cenário ω1 (Q = ", Q1max-1, "): \$", R1max)
println("Receita máxima no cenário ω2 (Q = ",  Q2max-1, "): \$", R2max)

p1 = plot(Q_list, receita_ω1_list, 
         label = "Receita ω1", title = "Receita ω1 :: Q",
         ylabel = "Receita ω1", xlabel = "Q")

p2 = plot(Q_list, receita_ω2_list, 
          label = "Receita ω2", title = "Receita ω2 :: Q",
          ylabel = "Receita ω2", xlabel = "Q")

display(p1); savefig(p1, "q15b_w1.png")
display(p2); savefig(p2, "q15b_w2.png")

# ============================     Item (c)     ============================== #

println("Receita máxima utilizando Qmax_ω1 a no cenário ω2 (Q = ",  Q1max-1, "): \$", calcular_receita(Q1max-1, g_ω2, P, π_C, π_V))

# ============================     Item (d)     ============================== #

# Q = argmax(E[R(Q, g)])

prob_ω1 = 0.81
prob_ω2 = 0.19

EV_list = []
for q in Q_list
    append!(EV_list, prob_ω1 * calcular_receita(q, g_ω1, P, π_C, π_V) + prob_ω2 * calcular_receita(q, g_ω2, P, π_C, π_V))
end

EV_optimo, Q_optimo = findmax(EV_list)

r_opt_ω1 = calcular_receita(Q_optimo-1, g_ω1, P, π_C, π_V)
r_opt_ω2 = calcular_receita(Q_optimo-1, g_ω2, P, π_C, π_V)

println("Quantidade ótima vendida em contrato: ", Q_optimo-1)
println("Receita no cenário 1: ", r_opt_ω1)
println("Receita no cenário 2: ", r_opt_ω2)

# ============================     Item (e)     ============================== #

# Q = argmax(E[R(Q, g)])

prob_ω1 = 0.82
prob_ω2 = 0.18

EV_list = []
for q in Q_list
    append!(EV_list, prob_ω1 * calcular_receita(q, g_ω1, P, π_C, π_V) + prob_ω2 * calcular_receita(q, g_ω2, P, π_C, π_V))
end

EV_optimo, Q_optimo = findmax(EV_list)

r_opt_ω1 = calcular_receita(Q_optimo-1, g_ω1, P, π_C, π_V)
r_opt_ω2 = calcular_receita(Q_optimo-1, g_ω2, P, π_C, π_V)

println("Quantidade ótima vendida em contrato: ", Q_optimo-1)
println("Receita no cenário 1: ", r_opt_ω1)
println("Receita no cenário 2: ", r_opt_ω2)