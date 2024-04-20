# ============================================================================ #
# ====================       Risk Measure Analysis       ===================== #
# ============================================================================ #

using Distributions, Random
using RCall
using Plots

# ======================    Parâmetros do Problema   ========================= #

P  = 120;            # Preço Contrato
πV = 12;            # Preço Venda
πC = 600;           # Preço Compra

Q1 = 80;            # Quantidade Contrato 1
Q2 = 115;           # Quantidade Contrato 2

α = 0.95;            # alpha

# ============================================================================ #

# ========================     Sampling Process     ========================== #

nCenarios = 1000;                   # Number of Scenarios
Ω = 1:nCenarios;                    # Set of Scenarios
pr = ones(nCenarios)*(1/nCenarios); # Equal Probability

Gmin = 50;          # Minimum Production
Gmax = 150;         # Maximum Production

# ===================================
#      =====> Using Julia <=====     
# ===================================

# -> https://juliastats.org/Distributions.jl/stable/ <- #

Random.seed!(1);
G  = rand(Uniform(Gmin, Gmax), nCenarios);

# ===================================
#         =====> Using R <=====     
# ===================================

# -> https://juliainterop.github.io/RCall.jl/stable/ <- #

#R"set.seed(1)"
#G  = rcopy(R"runif($nCenarios, min = $Gmin, max = $Gmax)");

# ============================================================================ #

# =======================     Revenue Evaluation     ========================= #

Rev1 = zeros(nCenarios);
Rev2 = zeros(nCenarios);

for ω in Ω
    Rev1[ω] = P*Q1 - πC*max(Q1 - G[ω], 0) + πV*max(G[ω] - Q1, 0);
    Rev2[ω] = P*Q2 - πC*max(Q2 - G[ω], 0) + πV*max(G[ω] - Q2, 0);
end

println("\n\n\n\n")
println("============================================================")
println("=====>     Iniciando Cálculo das Medidas de Risco     <=====")
println("============================================================")
println("\n")

# ============================================================================ #

# ====================     Value-at-Risk     ===================== #

println("  1) Value-at-Risk \n")

MatAux = [Rev1 pr];
Rev1_Ord = MatAux[sortperm(MatAux[:,1]),:];
MatAux = [Rev2 pr];
Rev2_Ord = MatAux[sortperm(MatAux[:,1]),:];

# Value-at-Risk -> Q1 #

global flagVaR = true;
global ωOp = 1;
global ProbAc = 0;

while (flagVaR)
    global ProbAc = ProbAc + Rev1_Ord[ωOp,2];
    if (ProbAc > (1 - α))
        global flagVaR = false;
    else
        global ωOp += 1;
    end
end

VaR_Q1 = -Rev1_Ord[ωOp,1];
println("     Value-at-Risk - Q1: ", VaR_Q1);

# Value-at-Risk -> Q2 #

global flagVaR = true;
global ωOp = 1;
global ProbAc = 0;

while (flagVaR)
    global ProbAc = ProbAc + Rev2_Ord[ωOp,2];
    if (ProbAc > (1 - α))
        global flagVaR = false;
    else
        global ωOp += 1;
    end
end

VaR_Q2 = -Rev2_Ord[ωOp,1]
println("     Value-at-Risk - Q2: ", VaR_Q2);

println("\n")

# ============================================================================ #

# ===============     Conditional Value-at-Risk     =============== #

println("  2) Conditional Value-at-Risk \n")

CVaR_Q1 = VaR_Q1 + sum(pr[ω]*max(-VaR_Q1 - Rev1[ω],0) for ω in Ω)/(1 - α);
CVaR_Q2 = VaR_Q2 + sum(pr[ω]*max(-VaR_Q2 - Rev2[ω],0) for ω in Ω)/(1 - α);

println("     Conditional Value-at-Risk - Q1: ", CVaR_Q1);
println("     Conditional Value-at-Risk - Q2: ", CVaR_Q2);