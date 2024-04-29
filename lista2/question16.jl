using Plots
using Distributions
using Random

include("utils.jl")

q = 40
r = 15
c = 25
d0 = 100
d1 = 300

# ============================     Item (a)     ============================== #
# ex: comprou 10 e vendeu 5 -> preco_venda * min(demanda, qtd_comprada) + preco_residual * max(qtd_comprada - demanda; 0) - preco_compra * qtd_comprada
# ex: comprou 10 e vendeu 5 ->  40 * 5 + 15 * max(10 - 5; 0) - 25 * 10 = 

function calc_ReceitaJornaleiro(x, d)
    return q * min(x, d) + r * max(x - d, 0) - (c * x)
end

# println(calc_ReceitaJornaleiro(100,100))

# ============================     Item (b)     ============================== #

nCenarios = 10000;                   # Number of Scenarios
Ω = 1:nCenarios;                    # Set of Scenarios
pr = ones(nCenarios)*(1/nCenarios); # Equal Probability

Random.seed!(1);
D = rand(d0 + (d1-d0) * Beta(2,2), nCenarios);

x1 = 220
x2= 280
limit = 1500

prob_inf = sum(calc_ReceitaJornaleiro(x1, d) <= limit ? 1 : 0 for d in D) / nCenarios

println("A probabilidadade de a receita ser inferior à \$1500 é: $(prob_inf*100) %")

# ============================     Item (c)     ============================== #
# Como é neutro a risco, vamos utilizar o valor esperado pra calcular

VME_x1 = round(sum(calc_ReceitaJornaleiro(x1, D[i]) * pr[i] for i in 1:nCenarios), digits=2)
VME_x2 = round(sum(calc_ReceitaJornaleiro(x2, D[i]) * pr[i] for i in 1:nCenarios), digits=2)

if VME_x1 >= VME_x2
    println("A opção x1($VME_x1) preferida à opção x2($VME_x2)")
else
    println("A opção x2($VME_x2) preferida à opção x1($VME_x1)")
end

# ============================     Item (d)     ============================== #

Rev1 = [calc_ReceitaJornaleiro(x1, d) for d in D]
Rev2 = [calc_ReceitaJornaleiro(x2, d) for d in D]

plot_FstOrder(Rev1, Rev2, pr, Ω);

fstOrderDominance_x1 = calc_FstOrder(Rev1, Rev2, pr, Ω)

if (fstOrderDominance_x1)
    println("x1 possui dominância estocástica de Primeira Ordem sobre x2");
else
    println("x1 NÃO possui dominância estocástica de Primeira Ordem sobre x2");
end

fstOrderDominance_x2 = calc_FstOrder(Rev2, Rev1, pr, Ω)

if (fstOrderDominance_x2)
    println("x2 possui dominância estocástica de Primeira Ordem sobre x1");
else
    println("x2 NÃO possui dominância estocástica de Primeira Ordem sobre x1");
end

# ============================     Item (e)     ============================== #
Rev1 = [calc_ReceitaJornaleiro(x1, d) for d in D]
Rev2 = [calc_ReceitaJornaleiro(x2, d) for d in D]

plot_ScdOrder(Rev1, Rev2, pr, Ω);

scdOrderDominance_x1 = calc_ScdOrder(Rev1, Rev2, pr, Ω)

if (scdOrderDominance_x1)
    println("x1 possui dominância estocástica de Segunda Ordem sobre x2");
else
    println("x1 NÃO possui dominância estocástica de Segunda Ordem sobre x2");
end

scdOrderDominance_x2 = calc_FstOrder(Rev2, Rev1, pr, Ω)

if (scdOrderDominance_x2)
    println("x2 possui dominância estocástica de Segunda Ordem sobre x1");
else
    println("x2 NÃO possui dominância estocástica de Segunda Ordem sobre x1");
end

# ============================     Item (f)     ============================== #
α = 0.99;     

VaR_x1 = calc_VaR(Rev1, pr, α)
VaR_x2 = calc_VaR(Rev2, pr, α)
if VaR_x1 <= VaR_x2
    println("VaR($α) - A opção x1($VaR_x1) preferida à opção x2($VaR_x2),")
else
    println("VaR($α) - A opção x2($VaR_x2) preferida à opção x1($VaR_x1)")
end

CVaR_x1 = calc_CVaR(Rev1, pr, α);
CVaR_x2 = calc_CVaR(Rev2, pr, α);
if CVaR_x1 <= CVaR_x2
    println("CVaR($α) - A opção x1($CVaR_x1) preferida à opção x2($CVaR_x2),")
else
    println("CVaR($α) - A opção x2($CVaR_x2) preferida à opção x1($CVaR_x1)")
end

# ============================     Item (g)     ============================== #
u_bar = 300
function calc_UtilidadeJornaleiro(x, θ)
    return (1000 + x)^θ
end

teta_list = []
teta_list_util = []
for θ in 0.1:0.05:1.5
    util_list = []
    for x in 1:u_bar
        util = sum(calc_UtilidadeJornaleiro(calc_ReceitaJornaleiro(x, D[i]), θ)* pr[i] for i in 1:nCenarios)
        append!(util_list, util)
    end
    max_util, max_index = findmax(util_list)
    println("θ($θ):", max_index, " - ", max_util)
    append!(teta_list, max_index)
    append!(teta_list_util, max_util)
end 
# println(teta_list)

p = plot(collect(0.1:0.05:1.5), teta_list, xlabel="θ", ylabel="x*(θ)", label="", title="Gráfico de θ versus x*(θ)", legend=false)
display(p)
# savefig(p, "lista2/images/q11g_bestX_theta")

pu = plot(collect(0.1:0.05:1.5), teta_list_util, xlabel="θ", ylabel="u(R(x*(θ),d)", label="", title="Gráfico de θ versus u(R(x*(θ),d)", legend=false)
display(pu)
# savefig(pu, "lista2/images/q16g_util_theta")

α = 0.99
x01 = teta_list[1]
x10 = teta_list[19]
x15 = teta_list[29]
Rev01 = [calc_ReceitaJornaleiro(x01, d) for d in D]
Rev10 = [calc_ReceitaJornaleiro(x10, d) for d in D]
Rev15 = [calc_ReceitaJornaleiro(x15, d) for d in D]

println("Conditional Value-at-Risk - (θ=0.1): ", calc_CVaR(Rev01, pr, α));
println("Conditional Value-at-Risk - (θ=1.0): ", calc_CVaR(Rev10, pr, α));
println("Conditional Value-at-Risk - (θ=1.5): ", calc_CVaR(Rev15, pr, α));
# Quanto maior o θ mais arriscado (maior o CVaR). O que faz sentido, visto que quanto maior o valor de θ, maior foi o x*(θ) encontrado e com isso maior
# o risco de assumido pelo jornaleiro ao comprar um número mais elevado de jornais dado uma demanda incerta. Além disso, podemos entender que quanto maior
# o valor de θ, maior a utilidade esperada e a receita, e sendo o CVaR uma medida coerente de risco se X > Y, CVaR(X) > CVaR(Y) (monotonicidade)