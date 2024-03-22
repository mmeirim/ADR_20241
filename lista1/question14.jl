using Plots

using DecisionProgramming 
using JuMP
using HiGHS 
using XLSX
using DataFrames
using Distributions

include("Q5_utils.jl");


# ======================     Parâmetros do Problema -- Fabrica de Energia     ======================== #

contratos = [300, 600]  # Contratos disponíveis em MWh
preco_normal = 70  # Preço normal do gás em $/MMBtu
preco_alto = 100  # Preço alto do gás em $/MMBtu

nCenarios_G = 2;                  # Preço do gás para energia :: Número de Cenários = {Alto, Normal}
p_Normal_G = 0.85;                # Preço do gás para energia :: Probabilidade Cenário -> Normal
p_Alto_G = 0.15;                  # Preço do gás para energia :: Probabilidade Cenário -> Alto

nCenarios_E = 2                   # Entrega do gás para energia :: Número de Cenários = {Parcial, Total}
p_Total_E = 0.6;                 # Entrega do gás para energia :: Probabilidade Cenário -> Total
p_Parcial_E = 0.4;                # Entrega do gás para energia :: Probabilidade Cenário -> Parcial


# Fabrica Energia :: PayOff por Cenário de preço

pay_x1_Normal_Total =   45 * contratos[1] - preco_normal * (contratos[1] / 3)
pay_x1_Alto_Total =     45 * contratos[1] - preco_alto   * (contratos[1] / 3)
pay_x1_Normal_Parcial = 45 * contratos[1] - (preco_normal * 1.10) * (contratos[1] / 6) - 100 * (contratos[1] / 2) 
pay_x1_Alto_Parcial =   45 * contratos[1] - (preco_alto   * 1.10) * (contratos[1] / 6) - 100 * (contratos[1] / 2)

pay_x2_Normal_Total =   45 * contratos[2] - preco_normal * (contratos[2] / 3)
pay_x2_Alto_Total =     45 * contratos[2] - preco_alto   * (contratos[2] / 3)
pay_x2_Normal_Parcial = 45 * contratos[2] - (preco_normal * 1.10) * (contratos[2] / 6) - 100 * (contratos[2] / 2)
pay_x2_Alto_Parcial =   45 * contratos[2] - (preco_alto   * 1.10) * (contratos[2] / 6) - 100 * (contratos[2] / 2)

# ============================     Item (a)     ============================== #

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ia = InfluenceDiagram();

add_node!(diagram_Ia, DecisionNode("Contrato", [], ["X1", "X2"]))
add_node!(diagram_Ia, ChanceNode("PrecoGas", [], ["Normal", "Alto"]))
add_node!(diagram_Ia, ChanceNode("EntregaFornecedor", [], ["Total", "Parcial"]))
add_node!(diagram_Ia, ValueNode("PayOff", ["Contrato", "PrecoGas", "EntregaFornecedor"]));

generate_arcs!(diagram_Ia);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_PrecoGas = ProbabilityMatrix(diagram_Ia, "PrecoGas");
ProbMatrix_PrecoGas["Normal"]  = p_Normal_G;
ProbMatrix_PrecoGas["Alto"]  = p_Alto_G;
if (sum(ProbMatrix_PrecoGas) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ia, "PrecoGas", ProbMatrix_PrecoGas);
end;

ProbMatrix_EntregaFornecedor = ProbabilityMatrix(diagram_Ia, "EntregaFornecedor");
ProbMatrix_EntregaFornecedor["Total"]  = p_Total_E;
ProbMatrix_EntregaFornecedor["Parcial"]  = p_Parcial_E;
if (sum(ProbMatrix_EntregaFornecedor) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ia, "EntregaFornecedor", ProbMatrix_EntregaFornecedor);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ia, "PayOff");

Payoff_Invest["X1", "Normal",  "Total"]      = pay_x1_Normal_Total;
Payoff_Invest["X1", "Normal",  "Parcial"]    = pay_x1_Normal_Parcial;
Payoff_Invest["X1", "Alto",  "Total"]        = pay_x1_Alto_Total;
Payoff_Invest["X1", "Alto",  "Parcial"]      = pay_x1_Alto_Parcial;

Payoff_Invest["X2", "Normal",  "Total"]      = pay_x2_Normal_Total;
Payoff_Invest["X2", "Normal",  "Parcial"]    = pay_x2_Normal_Parcial;
Payoff_Invest["X2", "Alto",  "Total"]        = pay_x2_Alto_Total;
Payoff_Invest["X2", "Alto",  "Parcial"]      = pay_x2_Alto_Parcial;

add_utilities!(diagram_Ia, "PayOff", Payoff_Invest);
generate_diagram!(diagram_Ia);

# ----------> 4 :: Instanciar e Resolver o Problema de Otimização

model = Model(HiGHS.Optimizer);
z = DecisionVariables(model, diagram_Ia);
x_s = PathCompatibilityVariables(model, diagram_Ia, z);
EV = expected_value(model, diagram_Ia, x_s);

@objective(model, Max, EV);
optimize!(model);

# ----------> 5 :: Análise dos Resultados do Problema

zOpt_Ia = DecisionStrategy(z);
S_Ia = StateProbabilities(diagram_Ia, zOpt_Ia);
U_Ia = UtilityDistribution(diagram_Ia, zOpt_Ia);

print_decision_strategy(diagram_Ia, zOpt_Ia, S_Ia);     # Print da Política Ótima
print_utility_distribution(U_Ia);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Ia);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima

                                                            
# ============================     Item (b)     ============================== #
                                                            
pr  = U_Ia.p;
Ω   = 1:1:length(pr);
Rev = U_Ia.u;

plot_FstOrder(Rev, pr, Ω, "PerfilRiscoAcum_q14a _X1", "X1");
plot_FstOrder([pay_x2_Alto_Parcial, pay_x2_Alto_Total, pay_x2_Normal_Parcial, pay_x2_Normal_Total],
    [p_Alto_G*p_Parcial_E, p_Alto_G*p_Total_E, p_Normal_G*p_Parcial_E, p_Normal_G*p_Total_E], Ω,
                "PerfilRiscoAcum_q14a _X2t", "X2");
                
plot_FstOrder_PDF(Rev./1000, pr, "PerfilRisco_q14a _X1", "X1 (*10^3)");
plot_FstOrder_PDF([pay_x2_Alto_Parcial, pay_x2_Alto_Total, pay_x2_Normal_Parcial, pay_x2_Normal_Total]./1000,
    [p_Alto_G*p_Parcial_E, p_Alto_G*p_Total_E, p_Normal_G*p_Parcial_E, p_Normal_G*p_Total_E], 
                "PerfilRisco_q14a _X2", "X2 (*10^3)");


# Considerando os retornos calculados para os cenários
# e observando o perfil de risco acumulado é possível ver que há uma probabilidade de
# 40% de a receita líquida ser negativa. O que faz sentido, visto que em 40% dos casos o fornecedor
# irá fornecer apenas metade da demanda e a multa é mais cara do que o ganho que se tem vendendo o que é possível

# ============================     Item (c)     ============================== #


# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ic = InfluenceDiagram();

add_node!(diagram_Ic, DecisionNode("Especialista", [], ["Sim", "Nao"]))
add_node!(diagram_Ic, ChanceNode("PrevisaoPreco", [], ["Normal", "Alto"]))
add_node!(diagram_Ic, DecisionNode("Contrato", ["Especialista", "PrevisaoPreco"], ["X1", "X2"]))
add_node!(diagram_Ic, ChanceNode("PrecoGas", ["Especialista","PrevisaoPreco"], ["Normal", "Alto"]))
add_node!(diagram_Ic, ChanceNode("EntregaFornecedor", [], ["Total", "Parcial"]))
add_node!(diagram_Ic, ValueNode("PayOff", ["Contrato", "PrecoGas", "EntregaFornecedor"]));

generate_arcs!(diagram_Ic);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_PrevisaoPreco = ProbabilityMatrix(diagram_Ic, "PrevisaoPreco");
ProbMatrix_PrevisaoPreco["Normal"]  = p_Normal_G;
ProbMatrix_PrevisaoPreco["Alto"]  = p_Alto_G;
if (sum(ProbMatrix_PrevisaoPreco) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ic, "PrevisaoPreco", ProbMatrix_PrevisaoPreco);
end;


ProbMatrix_PrecoGas = ProbabilityMatrix(diagram_Ic, "PrecoGas");
ProbMatrix_PrecoGas["Sim", "Normal", "Normal"]  = 1.0;
ProbMatrix_PrecoGas["Sim", "Normal", "Alto"]    = 0.0;
ProbMatrix_PrecoGas["Sim", "Alto", "Alto"]      = 1.0;
ProbMatrix_PrecoGas["Sim", "Alto", "Normal"]    = 0.0;

ProbMatrix_PrecoGas["Nao", "Normal", "Normal"]  = p_Normal_G;
ProbMatrix_PrecoGas["Nao", "Normal", "Alto"]    = p_Alto_G;
ProbMatrix_PrecoGas["Nao", "Alto", "Alto"]      = p_Alto_G;
ProbMatrix_PrecoGas["Nao", "Alto", "Normal"]    = p_Normal_G;
if (sum(ProbMatrix_PrecoGas) ≠ 4) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ic, "PrecoGas", ProbMatrix_PrecoGas);
end;

ProbMatrix_EntregaFornecedor = ProbabilityMatrix(diagram_Ic, "EntregaFornecedor");
ProbMatrix_EntregaFornecedor["Total"]  = p_Total_E;
ProbMatrix_EntregaFornecedor["Parcial"]  = p_Parcial_E;
if (sum(ProbMatrix_EntregaFornecedor) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ic, "EntregaFornecedor", ProbMatrix_EntregaFornecedor);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ic, "PayOff");

Payoff_Invest["X1", "Normal",  "Total"]      = pay_x1_Normal_Total;
Payoff_Invest["X1", "Normal",  "Parcial"]    = pay_x1_Normal_Parcial;
Payoff_Invest["X1", "Alto",  "Total"]        = pay_x1_Alto_Total;
Payoff_Invest["X1", "Alto",  "Parcial"]      = pay_x1_Alto_Parcial;

Payoff_Invest["X2", "Normal",  "Total"]      = pay_x2_Normal_Total;
Payoff_Invest["X2", "Normal",  "Parcial"]    = pay_x2_Normal_Parcial;
Payoff_Invest["X2", "Alto",  "Total"]        = pay_x2_Alto_Total;
Payoff_Invest["X2", "Alto",  "Parcial"]      = pay_x2_Alto_Parcial;


add_utilities!(diagram_Ic, "PayOff", Payoff_Invest);
generate_diagram!(diagram_Ic);

# ----------> 4 :: Instanciar e Resolver o Problema de Otimização

model = Model(HiGHS.Optimizer);
z = DecisionVariables(model, diagram_Ic);
x_s = PathCompatibilityVariables(model, diagram_Ic, z);
EV = expected_value(model, diagram_Ic, x_s);

@objective(model, Max, EV);
optimize!(model);

# ----------> 5 :: Análise dos Resultados do Problema

zOpt_Ic = DecisionStrategy(z);
S_Ic = StateProbabilities(diagram_Ic, zOpt_Ic);
U_Ic = UtilityDistribution(diagram_Ic, zOpt_Ic);

print_decision_strategy(diagram_Ic, zOpt_Ic, S_Ic);     # Print da Política Ótima
print_utility_distribution(U_Ic);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Ic);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima



# ============================     Item (d)     ============================== #

df = DataFrame(XLSX.readtable("Questao15 - Historico Consultoria.xlsx", "Historico_Consultoria"))

# Contar o número de previsões "Preço Normal"
total_prev_normal = sum(df[:, 1] .== "Preço Normal")
total_prev_alto = sum(df[:, 1] .== "Preço Alto")

# Contar o número de vezes que a previsão "Preço Normal" foi seguida de "Preço Alto"
ocorr_alto_dado_prev_normal = sum((df[:, 1] .== "Preço Normal") .& (df[:, 2] .== "Preço Alto"))
ocorr_alto_dado_prev_alto = sum((df[:, 1] .== "Preço Alto") .& (df[:, 2] .== "Preço Alto"))

ocorr_normal_dado_prev_normal = sum((df[:, 1] .== "Preço Normal") .& (df[:, 2] .== "Preço Normal"))
ocorr_normal_dado_prev_alto = sum((df[:, 1] .== "Preço Alto") .& (df[:, 2] .== "Preço Normal"))

# Calcular as probabilidades
prob_prev_normal = total_prev_normal / nrow(df)

prob_ocorr_alto_dado_prev_normal   = ocorr_alto_dado_prev_normal / total_prev_normal
prob_ocorr_normal_dado_prev_normal = ocorr_normal_dado_prev_normal / total_prev_normal
prob_ocorr_alto_dado_prev_alto     = ocorr_alto_dado_prev_alto / total_prev_alto
prob_ocorr_normal_dado_prev_alto   = ocorr_normal_dado_prev_alto / total_prev_alto


println("Probabilidade da consultoria prever 'Preço Normal' na próxima hora: ", round(prob_prev_normal*100, digits=2), "%")
println("Probabilidade do preço do gás natural na próxima hora ser 'Preço Alto' dado que a consultoria previu 'Preço Normal': ", round(prob_ocorr_alto_dado_prev_normal*100, digits=2), "%")

# ============================     Item (e)     ============================== #

# Considerando as possibilidades observadas no item (d)

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ie = InfluenceDiagram();

add_node!(diagram_Ie, DecisionNode("Especialista", [], ["Sim", "Nao"]))
add_node!(diagram_Ie, ChanceNode("PrevisaoPreco", [], ["Normal", "Alto"]))
add_node!(diagram_Ie, DecisionNode("Contrato", ["Especialista", "PrevisaoPreco"], ["X1", "X2"]))
add_node!(diagram_Ie, ChanceNode("PrecoGas", ["Especialista","PrevisaoPreco"], ["Normal", "Alto"]))
add_node!(diagram_Ie, ChanceNode("EntregaFornecedor", [], ["Total", "Parcial"]))
add_node!(diagram_Ie, ValueNode("PayOff", ["Especialista", "PrevisaoPreco", "Contrato", "PrecoGas", "EntregaFornecedor"]));

generate_arcs!(diagram_Ie);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_PrevisaoPreco = ProbabilityMatrix(diagram_Ie, "PrevisaoPreco");
ProbMatrix_PrevisaoPreco["Normal"]  = prob_prev_normal;
ProbMatrix_PrevisaoPreco["Alto"]  = (1 - prob_prev_normal);
if (sum(ProbMatrix_PrevisaoPreco) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ie, "PrevisaoPreco", ProbMatrix_PrevisaoPreco);
end;


ProbMatrix_PrecoGas = ProbabilityMatrix(diagram_Ie, "PrecoGas");
ProbMatrix_PrecoGas["Sim", "Normal", "Normal"]  = prob_ocorr_normal_dado_prev_normal;
ProbMatrix_PrecoGas["Sim", "Normal", "Alto"]    = prob_ocorr_alto_dado_prev_normal;
ProbMatrix_PrecoGas["Sim", "Alto", "Alto"]      = prob_ocorr_alto_dado_prev_alto;
ProbMatrix_PrecoGas["Sim", "Alto", "Normal"]    = prob_ocorr_normal_dado_prev_alto;

# ProbMatrix_PrecoGas["Sim", "Normal", "Normal"]  = 1.0;
# ProbMatrix_PrecoGas["Sim", "Normal", "Alto"]    = 0.0;
# ProbMatrix_PrecoGas["Sim", "Alto", "Alto"]      = 1.0;
# ProbMatrix_PrecoGas["Sim", "Alto", "Normal"]    = 0.0;

ProbMatrix_PrecoGas["Nao", "Normal", "Normal"]  = p_Normal_G;
ProbMatrix_PrecoGas["Nao", "Normal", "Alto"]    = p_Alto_G;
ProbMatrix_PrecoGas["Nao", "Alto", "Alto"]      = p_Alto_G;
ProbMatrix_PrecoGas["Nao", "Alto", "Normal"]    = p_Normal_G;
if (sum(ProbMatrix_PrecoGas) ≠ 4) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ie, "PrecoGas", ProbMatrix_PrecoGas);
end;

ProbMatrix_EntregaFornecedor = ProbabilityMatrix(diagram_Ie, "EntregaFornecedor");
ProbMatrix_EntregaFornecedor["Total"]  = p_Total_E;
ProbMatrix_EntregaFornecedor["Parcial"]  = p_Parcial_E;
if (sum(ProbMatrix_EntregaFornecedor) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ie, "EntregaFornecedor", ProbMatrix_EntregaFornecedor);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ie, "PayOff");

Payoff_Invest["Nao", "Normal", "X1", "Normal",  "Total"]      = pay_x1_Normal_Total;
Payoff_Invest["Nao", "Normal", "X1", "Normal",  "Parcial"]    = pay_x1_Normal_Parcial;
Payoff_Invest["Nao", "Normal", "X1", "Alto",  "Total"]        = pay_x1_Alto_Total;
Payoff_Invest["Nao", "Normal", "X1", "Alto",  "Parcial"]      = pay_x1_Alto_Parcial;

Payoff_Invest["Nao", "Alto", "X1", "Normal",  "Total"]        = pay_x1_Normal_Total;
Payoff_Invest["Nao", "Alto", "X1", "Normal",  "Parcial"]      = pay_x1_Normal_Parcial;
Payoff_Invest["Nao", "Alto", "X1", "Alto",  "Total"]          = pay_x1_Alto_Total;
Payoff_Invest["Nao", "Alto", "X1", "Alto",  "Parcial"]        = pay_x1_Alto_Parcial;

Payoff_Invest["Nao", "Normal", "X2", "Normal",  "Total"]      = pay_x2_Normal_Total;
Payoff_Invest["Nao", "Normal", "X2", "Normal",  "Parcial"]    = pay_x2_Normal_Parcial;
Payoff_Invest["Nao", "Normal", "X2", "Alto",  "Total"]        = pay_x2_Alto_Total;
Payoff_Invest["Nao", "Normal", "X2", "Alto",  "Parcial"]      = pay_x2_Alto_Parcial;

Payoff_Invest["Nao", "Alto", "X2", "Normal",  "Total"]        = pay_x2_Normal_Total;
Payoff_Invest["Nao", "Alto", "X2", "Normal",  "Parcial"]      = pay_x2_Normal_Parcial;
Payoff_Invest["Nao", "Alto", "X2", "Alto",  "Total"]          = pay_x2_Alto_Total;
Payoff_Invest["Nao", "Alto", "X2", "Alto",  "Parcial"]        = pay_x2_Alto_Parcial;

Payoff_Invest["Sim", "Normal", "X1", "Normal",  "Total"]      = pay_x1_Normal_Total - 50;
Payoff_Invest["Sim", "Normal", "X1", "Normal",  "Parcial"]    = pay_x1_Normal_Parcial - 50;
Payoff_Invest["Sim", "Normal", "X1", "Alto",  "Total"]        = pay_x1_Alto_Total - 50;
Payoff_Invest["Sim", "Normal", "X1", "Alto",  "Parcial"]      = pay_x1_Alto_Parcial - 50;

Payoff_Invest["Sim", "Alto", "X1", "Normal",  "Total"]        = pay_x1_Normal_Total - 50;
Payoff_Invest["Sim", "Alto", "X1", "Normal",  "Parcial"]      = pay_x1_Normal_Parcial - 50;
Payoff_Invest["Sim", "Alto", "X1", "Alto",  "Total"]          = pay_x1_Alto_Total - 50;
Payoff_Invest["Sim", "Alto", "X1", "Alto",  "Parcial"]        = pay_x1_Alto_Parcial - 50;

Payoff_Invest["Sim", "Normal", "X2", "Normal",  "Total"]      = pay_x2_Normal_Total - 50;
Payoff_Invest["Sim", "Normal", "X2", "Normal",  "Parcial"]    = pay_x2_Normal_Parcial - 50;
Payoff_Invest["Sim", "Normal", "X2", "Alto",  "Total"]        = pay_x2_Alto_Total - 50;
Payoff_Invest["Sim", "Normal", "X2", "Alto",  "Parcial"]      = pay_x2_Alto_Parcial - 50;

Payoff_Invest["Sim", "Alto", "X2", "Normal",  "Total"]        = pay_x2_Normal_Total - 50;
Payoff_Invest["Sim", "Alto", "X2", "Normal",  "Parcial"]      = pay_x2_Normal_Parcial - 50;
Payoff_Invest["Sim", "Alto", "X2", "Alto",  "Total"]          = pay_x2_Alto_Total - 50;
Payoff_Invest["Sim", "Alto", "X2", "Alto",  "Parcial"]        = pay_x2_Alto_Parcial - 50;


add_utilities!(diagram_Ie, "PayOff", Payoff_Invest);
generate_diagram!(diagram_Ie);

# ----------> 4 :: Instanciar e Resolver o Problema de Otimização

model = Model(HiGHS.Optimizer);
z = DecisionVariables(model, diagram_Ie);
x_s = PathCompatibilityVariables(model, diagram_Ie, z);
EV = expected_value(model, diagram_Ie, x_s);

@objective(model, Max, EV);
optimize!(model);

# ----------> 5 :: Análise dos Resultados do Problema

zOpt_Ic = DecisionStrategy(z);
S_Ic = StateProbabilities(diagram_Ie, zOpt_Ic);
U_Ic = UtilityDistribution(diagram_Ie, zOpt_Ic);

print_decision_strategy(diagram_Ie, zOpt_Ic, S_Ic);     # Print da Política Ótima
print_utility_distribution(U_Ic);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Ic);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima