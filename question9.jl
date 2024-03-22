using Plots

using DecisionProgramming 
using JuMP
using HiGHS 
using Distributions

include("Q5_utils.jl");


# ======================     Parâmetros do Problema -- Análise de Investimento     ======================== #


nCenarios_Inv = 5;                   # Investimento 2 :: Número de Cenários = {w1, w2, w3, w4, w5}
p_w1_Inv2 = 0.20;                    # Investimento 2 :: Probabilidade Cenário -> w1
p_w2_Inv2 = 0.25;                    # Investimento 2 :: Probabilidade Cenário -> w2
p_w3_Inv2 = 0.10;                    # Investimento 2 :: Probabilidade Cenário -> w3
p_w4_Inv2 = 0.30;                    # Investimento 2 :: Probabilidade Cenário -> w4
p_w5_Inv2 = 0.15;                    # Investimento 2 :: Probabilidade Cenário -> w5

# Investimento 2 :: Investimento & PayOff por Cenário de Audiência

Inv_Inv2     = 0;                   # Investimento 2 :: Montante Total do Investimento

pay_w1 = 10 * 1 + 50 * exp(-0.5 * -2) + ( 5 * -2 * 1)
pay_w2 = 10 * 9 + 50 * exp(-0.5 *  1) + ( 5 * 1 * 9)
pay_w3 = 10 * 6 + 50 * exp(-0.5 *  3) + (5 * 3 * 6)
pay_w4 = 10 * 4 + 50 * exp(-0.5 * -1) + (5 * -1 * 4)
pay_w5 = 10 * 7 + 50 * exp(-0.5 *  0) + (5 * 0 * 7)

#               w1       w2       w3       w4       w5
PayOff_Inv2 = [ pay_w1   pay_w2   pay_w3   pay_w4   pay_w5];


# ============================     Item (a)     ============================== #

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ia = InfluenceDiagram();

add_node!(diagram_Ia, DecisionNode("MudarInv2", [], ["Sim", "Nao"]));
add_node!(diagram_Ia, ChanceNode("Cenario_Macro", [], ["w1", "w2", "w3", "w4", "w5"]));
add_node!(diagram_Ia, ValueNode("PayOff", ["Cenario_Macro", "MudarInv2"]));

generate_arcs!(diagram_Ia);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_Market_Inv2 = ProbabilityMatrix(diagram_Ia, "Cenario_Macro");
ProbMatrix_Market_Inv2["w1"]  = p_w1_Inv2;
ProbMatrix_Market_Inv2["w2"]  = p_w2_Inv2;
ProbMatrix_Market_Inv2["w3"]  = p_w3_Inv2;
ProbMatrix_Market_Inv2["w4"]  = p_w4_Inv2;
ProbMatrix_Market_Inv2["w5"]  = p_w5_Inv2;
if (sum(ProbMatrix_Market_Inv2) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ia, "Cenario_Macro", ProbMatrix_Market_Inv2);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ia, "PayOff");

Payoff_Invest["w1",  "Sim"] = PayOff_Inv2[1] - Inv_Inv2;   # Mudar para o Investimento 2 & Cenário w1
Payoff_Invest["w2",  "Sim"] = PayOff_Inv2[2] - Inv_Inv2;   # Mudar para o Investimento 2 & Cenário w2
Payoff_Invest["w3",  "Sim"] = PayOff_Inv2[3] - Inv_Inv2;   # Mudar para o Investimento 2 & Cenário w3
Payoff_Invest["w4",  "Sim"] = PayOff_Inv2[4] - Inv_Inv2;   # Mudar para o Investimento 2 & Cenário w4
Payoff_Invest["w5",  "Sim"] = PayOff_Inv2[5] - Inv_Inv2;   # Mudar para o Investimento 2 & Cenário w5

Payoff_Invest["w1",  "Nao"] = 150.0;                     # Não Mudar para o Investimento 2 & Cenário w1
Payoff_Invest["w2",  "Nao"] = 150.0;                     # Não Mudar para o Investimento 2 & Cenário w2
Payoff_Invest["w3",  "Nao"] = 150.0;                     # Não Mudar para o Investimento 2 & Cenário w3
Payoff_Invest["w4",  "Nao"] = 150.0;                     # Não Mudar para o Investimento 2 & Cenário w4
Payoff_Invest["w5",  "Nao"] = 150.0;                     # Não Mudar para o Investimento 2 & Cenário w5

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


pr  = U_Ia.p;
Ω   = 1:1:length(pr);
Rev = U_Ia.u;

plot_FstOrder(Rev, pr, Ω, "PerfilRisco_q9a", "Renda Fixa");


# ============================     Item (b)     ============================== #

# Considerando os retornos calculados para os cenários
# w1 à w5 do Investimento 2 (135.914  165.327  161.157  102.436  120.0)
# para se obter um retorno maior ao da RF apenas se ocorrerem os cenários w2 e w3.
# Esses cenários juntos podem ocorrer com Probabilidade de 35%


# ============================     Item (c)     ============================== #


