# ============================================================================ #
# ======================       Dominance Analysis       ====================== #
# ============================================================================ #

using Distributions, Random
using Plots
using RCall

include("utils.jl");

# ======================    Parâmetros do Problema   ========================= #

P = 120;            # Preço Contrato
πV = 12;            # Preço Venda
πC = 600;           # Preço Compra

Q1 = 80;            # Quantidade Contrato 1
Q2 = 115;           # Quantidade Contrato 2

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
println("===================================================")
println("=====>     Iniciando Cálculo Dominâncias     <=====")
println("===================================================")
println("\n")

# ============================================================================ #

# ====================     Dominância Determinística     ===================== #

println("  1) Dominância Determinística\n")

#### -> Q1 Dominate Q2 <- ####

DD_Q1 = minimum(Rev1);
DD_Q2 = maximum(Rev2);

if (DD_Q1 >= DD_Q2)
    println("     Q1 possui dominância determinística sobre Q2\n");
else
    println("     Q1 NÃO possui dominância determinística sobre Q2\n");
end


#### -> Q2 Dominate Q1 <- ####

DD_Q1 = maximum(Rev1);
DD_Q2 = minimum(Rev2);

if (DD_Q2 >= DD_Q1)
    println("     Q2 possui dominância determinística sobre Q1\n");
else
    println("     Q2 NÃO possui dominância determinística sobre Q1\n");
end

println("\n")

# ============================================================================ #

# ===============     Dominância Estocástica Ponto-a-Ponto     =============== #

println("  2) Dominância Estocástica Ponto-a-Ponto\n")

#### -> Q1 Dominate Q2 <- ####

global flagDEPP_Q1 = true;

for ω in Ω
    if (Rev1[ω] <= Rev2[ω])
        global flagDEPP_Q1 = false;
    end
end

if (flagDEPP_Q1)
    println("     Q1 possui dominância estocástica ponto-a-ponto sobre Q2\n");
else
    println("     Q1 NÃO possui dominância estocástica ponto-a-ponto sobre Q2\n");
end

#### -> Q2 Dominate Q1 <- ####

global flagDEPP_Q2 = true;

for ω in Ω
    if (Rev2[ω] <= Rev1[ω])
        global flagDEPP_Q2 = false;
    end
end

if (flagDEPP_Q2)
    println("     Q2 possui dominância estocástica ponto-a-ponto sobre Q1\n");
else
    println("     Q2 NÃO possui dominância estocástica ponto-a-ponto sobre Q1\n");
end

println("\n")

# ============================================================================ #

# ==============     Dominância Estocástica Primeira Ordem     =============== #

println("  3) Dominância Estocástica de Primeira Ordem\n")

#### -> Graphical Analysis <- ####

plot_FstOrder(Rev1, Rev2, pr, Ω);

#### -> Q1 Dominate Q2 <- ####

global flagDEPO_Q1 = true;

for z in Rev1

    F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
    F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
    
    if (F_Q1 > F_Q2)
        global flagDEPO_Q1 = false;
    end
    
end

for z in Rev2

    F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
    F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
    
    if (F_Q1 > F_Q2)
        global flagDEPO_Q1 = false;
    end

end

if (flagDEPO_Q1)
    println("     Q1 possui dominância estocástica de Primeira Ordem sobre Q2\n");
else
    println("     Q1 NÃO possui dominância estocástica de Primeira Ordem sobre Q2\n");
end

#### -> Q2 Dominate Q1 <- ####

global flagDEPO_Q2 = true;

for z in Rev1

    F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
    F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
    
    if (F_Q2 > F_Q1)
        global flagDEPO_Q2 = false;
    end

end

for z in Rev2

    F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
    F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
    
    if (F_Q2 > F_Q1)
        global flagDEPO_Q2 = false;
    end

end

if (flagDEPO_Q2)
    println("     Q2 possui dominância estocástica de Primeira Ordem sobre Q1\n");
else
    println("     Q2 NÃO possui dominância estocástica de Primeira Ordem sobre Q1\n");
end

println("\n")

# ============================================================================ #

# ===============     Dominância Estocástica Segunda Ordem     =============== #

println("  4) Dominância Estocástica de Segunda Ordem\n")

#### -> Graphical Analysis <- ####

plot_ScdOrder(Rev1, Rev2, pr, Ω);

#### -> Q1 Dominate Q2 <- ####

global flagDESO_Q1 = true;

for z in Rev1

    F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
    F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
    
    if (F2_Q1 > F2_Q2)
        global flagDESO_Q1 = false;
    end

end

for z in Rev2

    F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
    F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
    
    if (F2_Q1 > F2_Q2)
        global flagDESO_Q1 = false;
    end

end

if (flagDESO_Q1)
    println("     Q1 possui dominância estocástica de Segunda Ordem sobre Q2\n");
else
    println("     Q1 NÃO possui dominância estocástica de Segunda Ordem sobre Q2\n");
end

#### -> Q2 Dominate Q1 <- ####

global flagDESO_Q2 = true;

for z in Rev1

    F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
    F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
    
    if (F2_Q2 > F2_Q1)
        global flagDESO_Q2 = false;
    end

end

for z in Rev2

    F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
    F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
    
    if (F2_Q2 > F2_Q1)
        global flagDESO_Q2 = false;
    end

end

if (flagDESO_Q2)
    println("     Q2 possui dominância estocástica de Segunda Ordem sobre Q1\n");
else
    println("     Q2 NÃO possui dominância estocástica de Segunda Ordem sobre Q1\n");
end