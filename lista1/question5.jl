# ============================================================================================== #
# ==================       Decision Programming - Firma Cinematográfica       ================== #
# ============================================================================================== #

using Plots

using DecisionProgramming       # Package Url: https://github.com/gamma-opt/DecisionProgramming.jl
                                # Paper (EJOR): https://www.sciencedirect.com/science/article/pii/S0377221721010201
#
using JuMP
using HiGHS             # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/HiGHS.jl | https://highs.dev/

# using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.
#

include("Q5_utils.jl");

# ======================     Parâmetros do Problema -- Firma Cinematográfica     ======================== #

nCenarios_F1 = 3;                  # Filme 1 :: Número de Cenários = {High, Med, Low}
p_High_F1 = 0.20;                  # Filme 1 :: Probabilidade Cenário -> High
p_Med_F1  = 0.40;                  # Filme 1 :: Probabilidade Cenário -> Med
p_Low_F1  = 0.40;                  # Filme 1 :: Probabilidade Cenário -> Low

nCenarios_F2 = 3;                  # Filme 2 :: Número de Cenários = {High, Med, Low}
p_High_F2 = 0.20;                  # Filme 2 :: Probabilidade Cenário -> High
p_Med_F2  = 0.40;                  # Filme 2 :: Probabilidade Cenário -> Med
p_Low_F2  = 0.40;                  # Filme 2 :: Probabilidade Cenário -> Low

# Filme 1 :: Investimento & PayOff por Cenário de Audiência

Inv_F1    = 120;                   # Filme 1 :: Montante Total do Investimento
#             High    Med     Low
PayOff_F1 = [ 200.0   150.0   60.0 ];


# Filme 2 :: Investimento & PayOff por Cenário de Audiência

Inv_F2     = 220;                   # Filme 2 :: Montante Total do Investimento

#             High    Med     Low
PayOff_F2 = [ 370.0   270.0   80.0 ];


# ============================     Item (a)     ============================== #

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ia = InfluenceDiagram();

add_node!(diagram_Ia, DecisionNode("Filme1", [], ["Sim", "Nao"]));
add_node!(diagram_Ia, ChanceNode("Audiencia_F1", [], ["High", "Med", "Low"]));
add_node!(diagram_Ia, ValueNode("PayOff", ["Audiencia_F1", "Filme1"]));

generate_arcs!(diagram_Ia);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_Market_F1 = ProbabilityMatrix(diagram_Ia, "Audiencia_F1");
ProbMatrix_Market_F1["High"] = p_High_F1;
ProbMatrix_Market_F1["Med"]  = p_Med_F1;
ProbMatrix_Market_F1["Low"]  = p_Low_F1;
if (sum(ProbMatrix_Market_F1) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ia, "Audiencia_F1", ProbMatrix_Market_F1);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ia, "PayOff");

Payoff_Invest["High", "Sim"] = PayOff_F1[1] - Inv_F1;   # Realizar o Filme 1 & Cenário High
Payoff_Invest["Med",  "Sim"] = PayOff_F1[2] - Inv_F1;   # Realizar o Filme 1 & Cenário Med
Payoff_Invest["Low",  "Sim"] = PayOff_F1[3] - Inv_F1;   # Realizar o Filme 1 & Cenário Low

Payoff_Invest["High", "Nao"] = 0.0;                     # Não Realizar o Filme 1 & Cenário High
Payoff_Invest["Med",  "Nao"] = 0.0;                     # Não Realizar o Filme 1 & Cenário Med
Payoff_Invest["Low",  "Nao"] = 0.0;                     # Não Realizar o Filme 1 & Cenário Low

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

#print_decision_strategy(diagram_Ia, zOpt_Ia, S_Ia);     # Print da Política Ótima
#print_utility_distribution(U_Ia);                       # Print da Distribuição de PayOff para a Política Ótima
#print_statistics(U_Ia);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima
#


# ============================     Item (b)     ============================== #

pr  = U_Ia.p;
Ω   = 1:1:length(pr);
Rev = U_Ia.u;

# plot_FstOrder(Rev, pr, Ω);

# ============================     Item (c)     ============================== #

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Ic = InfluenceDiagram();

add_node!(diagram_Ic, DecisionNode("Filme1_2", [], ["Sim", "Nao"]));
add_node!(diagram_Ic, ChanceNode("Audiencia_F1", [], ["High_F1", "Med_F1", "Low_F1"]));
add_node!(diagram_Ic, ChanceNode("Audiencia_F2", [], ["High_F2", "Med_F2", "Low_F2"]));
add_node!(diagram_Ic, ValueNode("PayOff", ["Audiencia_F1", "Audiencia_F2", "Filme1_2"]));

generate_arcs!(diagram_Ic);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_Market_F1 = ProbabilityMatrix(diagram_Ic, "Audiencia_F1");
ProbMatrix_Market_F1["High_F1"] = p_High_F1;
ProbMatrix_Market_F1["Med_F1"]  = p_Med_F1;
ProbMatrix_Market_F1["Low_F1"]  = p_Low_F1;
if (sum(ProbMatrix_Market_F1) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ic, "Audiencia_F1", ProbMatrix_Market_F1);
end;

ProbMatrix_Market_F2 = ProbabilityMatrix(diagram_Ic, "Audiencia_F2");
ProbMatrix_Market_F2["High_F2"] = p_High_F2;
ProbMatrix_Market_F2["Med_F2"]  = p_Med_F2;
ProbMatrix_Market_F2["Low_F2"]  = p_Low_F2;
if (sum(ProbMatrix_Market_F1) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Ic, "Audiencia_F2", ProbMatrix_Market_F2);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Ic, "PayOff");

Payoff_Invest["High_F1", "High_F2", "Sim"] = PayOff_F1[1] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário High
Payoff_Invest["High_F1", "Med_F2",  "Sim"] = PayOff_F1[1] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário Med
Payoff_Invest["High_F1", "Low_F2",  "Sim"] = PayOff_F1[1] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário Low

Payoff_Invest["Med_F1",  "High_F2", "Sim"] = PayOff_F1[2] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário High
Payoff_Invest["Med_F1",  "Med_F2",  "Sim"] = PayOff_F1[2] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Med
Payoff_Invest["Med_F1",  "Low_F2",  "Sim"] = PayOff_F1[2] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Low

Payoff_Invest["Low_F1",  "High_F2", "Sim"] = PayOff_F1[3] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário High
Payoff_Invest["Low_F1",  "Med_F2",  "Sim"] = PayOff_F1[3] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Med
Payoff_Invest["Low_F1",  "Low_F2",  "Sim"] = PayOff_F1[3] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filme 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Low

Payoff_Invest[:, :, "Nao"] = zeros(nCenarios_F1, nCenarios_F2);                                  # Não Realizar o Filme 1 & 2

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

#print_decision_strategy(diagram_Ic, zOpt_Ic, S_Ic);         # Print da Política Ótima
#print_utility_distribution(U_Ic);                           # Print da Distribuição de PayOff para a Política Ótima
#print_statistics(U_Ic);                                     # Print de Estatíticas Descritivas 
                                                                #   da Distribuição de PayOff para a Política Ótima
#



# ============================     Item (d)     ============================== #

# ----------> 1 :: Criação do Diagrama de Influência do Problema

diagram_Id = InfluenceDiagram();

add_node!(diagram_Id, DecisionNode("Filme1", [], ["Sim", "Nao"]));
add_node!(diagram_Id, ChanceNode("Audiencia_F1", [], ["High_F1", "Med_F1", "Low_F1"]));

add_node!(diagram_Id, DecisionNode("Filme2", ["Audiencia_F1", "Filme1"], ["Sim", "Nao"]));
add_node!(diagram_Id, ChanceNode("Audiencia_F2", [], ["High_F2", "Med_F2", "Low_F2"]));

add_node!(diagram_Id, ValueNode("PayOff", ["Audiencia_F1", "Audiencia_F2", "Filme1", "Filme2"]));

generate_arcs!(diagram_Id);

# ----------> 2 :: Alocação da Distribuição de Probabilidade dos Cenários de Mercado

ProbMatrix_Market_F1 = ProbabilityMatrix(diagram_Id, "Audiencia_F1");
ProbMatrix_Market_F1["High_F1"] = p_High_F1;
ProbMatrix_Market_F1["Med_F1"]  = p_Med_F1;
ProbMatrix_Market_F1["Low_F1"]  = p_Low_F1;
if (sum(ProbMatrix_Market_F1) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Id, "Audiencia_F1", ProbMatrix_Market_F1);
end;

ProbMatrix_Market_F2 = ProbabilityMatrix(diagram_Id, "Audiencia_F2");
ProbMatrix_Market_F2["High_F2"] = p_High_F2;
ProbMatrix_Market_F2["Med_F2"]  = p_Med_F2;
ProbMatrix_Market_F2["Low_F2"]  = p_Low_F2;
if (sum(ProbMatrix_Market_F1) ≠ 1) 
    println("Erro :: Probabilidade não soma 1") 
else 
    add_probabilities!(diagram_Id, "Audiencia_F2", ProbMatrix_Market_F2);
end;

# ----------> 3 :: Especificação da Distribuição dos PayOffs para Cada Investimento

Payoff_Invest = UtilityMatrix(diagram_Id, "PayOff");

Payoff_Invest["High_F1", "High_F2", "Sim", "Sim"] = PayOff_F1[1] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário High
Payoff_Invest["High_F1", "Med_F2",  "Sim", "Sim"] = PayOff_F1[1] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário Med
Payoff_Invest["High_F1", "Low_F2",  "Sim", "Sim"] = PayOff_F1[1] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário High & Filme 2 = Cenário Low

Payoff_Invest["High_F1", "High_F2", "Sim", "Nao"] = PayOff_F1[1] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário High & Filme 2 = Cenário High
Payoff_Invest["High_F1", "Med_F2",  "Sim", "Nao"] = PayOff_F1[1] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário High & Filme 2 = Cenário Med
Payoff_Invest["High_F1", "Low_F2",  "Sim", "Nao"] = PayOff_F1[1] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário High & Filme 2 = Cenário Low

Payoff_Invest["Med_F1",  "High_F2", "Sim", "Sim"] = PayOff_F1[2] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário High
Payoff_Invest["Med_F1",  "Med_F2",  "Sim", "Sim"] = PayOff_F1[2] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Med
Payoff_Invest["Med_F1",  "Low_F2",  "Sim", "Sim"] = PayOff_F1[2] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Low

Payoff_Invest["Med_F1",  "High_F2", "Sim", "Nao"] = PayOff_F1[2] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Med & Filme 2 = Cenário High
Payoff_Invest["Med_F1",  "Med_F2",  "Sim", "Nao"] = PayOff_F1[2] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Med
Payoff_Invest["Med_F1",  "Low_F2",  "Sim", "Nao"] = PayOff_F1[2] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Med & Filme 2 = Cenário Low

Payoff_Invest["Low_F1",  "High_F2", "Sim", "Sim"] = PayOff_F1[3] + PayOff_F2[1] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário High
Payoff_Invest["Low_F1",  "Med_F2",  "Sim", "Sim"] = PayOff_F1[3] + PayOff_F2[2] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Med
Payoff_Invest["Low_F1",  "Low_F2",  "Sim", "Sim"] = PayOff_F1[3] + PayOff_F2[3] - Inv_F1 - Inv_F2;      # Realizar os Filmes 1 & 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Low

Payoff_Invest["Low_F1",  "High_F2", "Sim", "Nao"] = PayOff_F1[3] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Low & Filme 2 = Cenário High
Payoff_Invest["Low_F1",  "Med_F2",  "Sim", "Nao"] = PayOff_F1[3] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Med
Payoff_Invest["Low_F1",  "Low_F2",  "Sim", "Nao"] = PayOff_F1[3] - Inv_F1;      # Realizar o Filme 1 & Não Realizar o Filme 2 || Filme 1 = Cenário Low & Filme 2 = Cenário Low

Payoff_Invest[:, :, "Nao", "Sim"] = zeros(nCenarios_F1, nCenarios_F2);                                  # Não Realizar o Filme 1
Payoff_Invest[:, :, "Nao", "Nao"] = zeros(nCenarios_F1, nCenarios_F2);                                  # Não Realizar o Filme 1

add_utilities!(diagram_Id, "PayOff", Payoff_Invest);
generate_diagram!(diagram_Id);

# ----------> 4 :: Instanciar e Resolver o Problema de Otimização

model = Model(HiGHS.Optimizer);
z = DecisionVariables(model, diagram_Id);
x_s = PathCompatibilityVariables(model, diagram_Id, z);
EV = expected_value(model, diagram_Id, x_s);

@objective(model, Max, EV);
optimize!(model);

# ----------> 5 :: Análise dos Resultados do Problema

zOpt_Id = DecisionStrategy(z);
S_Id = StateProbabilities(diagram_Id, zOpt_Id);
U_Id = UtilityDistribution(diagram_Id, zOpt_Id);

#print_decision_strategy(diagram_Id, zOpt_Id, S_Id);         # Print da Política Ótima
#print_utility_distribution(U_Id);                           # Print da Distribuição de PayOff para a Política Ótima
#print_statistics(U_Id);                                     # Print de Estatíticas Descritivas 
                                                                #   da Distribuição de PayOff para a Política Ótima
#




# ======================================================================================== #
# ============================     Print dos Resultados     ============================== #
# ======================================================================================== #

println("\n\n\n\n\n\n\n")

println("\n")
println(" -----> Item (a)")
println("\n")
print_decision_strategy(diagram_Ia, zOpt_Ia, S_Ia);     # Print da Política Ótima
print_utility_distribution(U_Ia);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Ia);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima
#

println("\n")
println(" -----> Item (c)")
println("\n")
print_decision_strategy(diagram_Ic, zOpt_Ic, S_Ic);     # Print da Política Ótima
print_utility_distribution(U_Ic);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Ic);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima
#

println("\n")
println(" -----> Item (d)")
println("\n")
print_decision_strategy(diagram_Id, zOpt_Id, S_Id);     # Print da Política Ótima
print_utility_distribution(U_Id);                       # Print da Distribuição de PayOff para a Política Ótima
print_statistics(U_Id);                                 # Print de Estatíticas Descritivas 
                                                            #   da Distribuição de PayOff para a Política Ótima
#

println("\n")