using Plots
using Distributions
using Random
using Statistics

include("utils.jl")


T = 40

nCenarios = 10000;                  # Number of Scenarios
Ω = 1:nCenarios;                    # Set of Scenarios
pr = ones(nCenarios)*(1/nCenarios); # Equal Probability

# Random.seed!(1);
D = rand(Random.seed!(1), Uniform(20,100), nCenarios);

function calcPrejuizo(T, d)
    return d < T ? d : T
end

# ============================     Item (a)     ============================== #

VME_prej = sum(calcPrejuizo(T, D[i]) * pr[i] for i in Ω)

println("O Valor Esperado do Prejuízo financeiro para a empresa é: \$$(round(VME_prej, digits=2))")

# ============================     Item (b)     ============================== #
tCenarios = collect(1:10:nCenarios)
rep = 100
means = []
for n in tCenarios
    prej = []
    for i in 1:rep
        Db = rand(Uniform(20,100), n);
        p = ones(n)*(1/n);
        loss = sum(calcPrejuizo(T, Db[i]) * p[i] for i in 1:n)
        append!(prej, loss)
    end
    append!(means, mean(prej))
end

pb = plot(tCenarios, means, xlabel="Número de Cenários", ylabel="Prejuízo Médio", label="", title="Gráfico de Prejuízo Médio X Nº de Cenários", legend=false)
display(pb)
savefig(pb, "lista2/images/q19b_prejCenarios.png")
# ============================     Item (c)     ============================== #
pr_Ac = 0.7
VME_prej_incerteza =  sum(calcPrejuizo(T, D[i]) * pr[i] for i in 1:nCenarios) * pr_Ac + 0 * (1 - pr_Ac)

println("O Valor Esperado do Prejuízo financeiro para a empresa considerando incerteza na ocorrência de aciedente é: \$$(round(VME_prej_incerteza, digits=2))")

# ============================     Item (d)     ============================== #

means_inc = []
for n in tCenarios
    prej = []
    for i in 1:rep
        Db = rand(Uniform(20,100), n);
        p = ones(n)*(1/n);
        loss = sum(calcPrejuizo(T, Db[i]) * p[i] for i in 1:n) * pr_Ac + 0 * (1 - pr_Ac)
        append!(prej, loss)
    end
    append!(means_inc, mean(prej))
end

pb = plot(tCenarios, means_inc, xlabel="Número de Cenários", ylabel="Prejuízo Médio", label="", title="Gráfico de Prejuízo Médio X Nº de Cenários", legend=false)
display(pb)
savefig(pb, "lista2/images/q19d_prejCenarios.png") 

# ============================     Item (e)     ============================== #
VME_prej_sseguro = sum(D[i] * pr[i] for i in 1:nCenarios) * pr_Ac + 0 * (1 - pr_Ac)
β = - (VME_prej_incerteza - VME_prej_sseguro)
println("O ser o maior valor de prêmio (β) cobrado pela seguradora para que a empresa prefira ter o seguro à não tê-lo é de : \$$(round(β, digits=2))")

# ============================     Item (f)     ============================== #

# calcular utilidade
θ = 0.1

function calc_UtilidadeSeguro(θ,x)
    return 1 - exp(-θ * x)
end

u_seg = sum(calc_UtilidadeSeguro(θ, - calcPrejuizo(T, D[i])) * pr[i] for i in Ω) * pr_Ac + calc_UtilidadeSeguro(θ,0) * (1-pr_Ac)
u_sseg = sum(calc_UtilidadeSeguro(θ,-D[i]) * pr[i] for i in Ω) * pr_Ac + calc_UtilidadeSeguro(θ,0) * (1-pr_Ac)

# calcular equivalente certo (-1 * eq_certo, pois calculei a utilidade de -x e não de x)
eq_certo_seg = log(1-u_seg)/θ
eq_certo_sseg = log(1-u_sseg)/θ

# EQ certo Seguro - EQ Certo S/ seguro
β = - (eq_certo_seg - eq_certo_sseg)
println("O ser o maior valor de prêmio (β) considerando a função utilidade é de : \$$(round(β, digits=2))")

# ============================     Item (g)     ============================== #
u_segP = sum(calc_UtilidadeSeguro(θ, - (β + calcPrejuizo(T, D[i]))) * pr[i] for i in Ω) * pr_Ac + calc_UtilidadeSeguro(θ,- (β + 0)) * (1-pr_Ac)

eq_certo_segP = log(1-u_segP)/θ

println("O equivalente certo do fluxo financeiro incerto da empresa sob a decisão de adquirir o seguro, com o prêmio β é de: \$$(round(eq_certo_segP, digits=2))")
# O meu entendimento é que a empresa troca todo o fluxo incerto de prejuízos por um montante de 75. Esse valor é menor que Franquia+Premio, ou seja, 
# ele trocaria o fluxo incerto de prejuizos, por um prejuizo de 75 que é inferior ao maior valor de prejuizo possivel no fluxo incerto (Franquia+Premio)
# O que faz sentido, visto que não valeria a pena trocar um prejuizo incerto, porém limitado à no maximo 80 (Franquia+premio), por um prejuizo certo superior a 80

# ============================     Item (h)     ============================== #
α = 0.95
# Necessário multiplica por -1 pois a função de calculo do CVaR que estou utilizando está definida em termos de ganhos financeiros (similar a utilidade)
Rev_seguro = [-calcPrejuizo(T, D[i]) for i in 1:nCenarios]
Rev_sseguro = [-D[i] for i in 1:nCenarios]

CVaR_seguro = calc_CVaR(Rev_seguro,repeat([pr_Ac], nCenarios), α)
CVaR_sseguro = calc_CVaR(Rev_sseguro,repeat([pr_Ac], nCenarios), α)
β_CVaR = - (CVaR_seguro - CVaR_sseguro)

println("O ser o maior valor de prêmio (β) considerando o CVaR_95% é de : \$$(round(β_CVaR, digits=2))")

# O premio β está aumentando ao longo da questão, isso significa que a distancia entre o prejuizo financeiro com seguro e sem seguro também esta aumentando
# ou seja, a empresa esta adotando medidas de risco mais rigidas, ou mais avessas ao risco, fazendo com que o prejuizo extra, em comparação com o prejuizo obtido quando o seguro é contratado,
# é mais penalizado, fazendo assim com que mesmo pagando um premio mais alto (β_item(h) > β_item(f) > b_item(e)) seja preferível contratar o seguro.
