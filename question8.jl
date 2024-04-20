using Distributions, Random
using Plots

include("utils.jl");

RF = 400
I = 200
nCenarios = 3
Ω = 1:nCenarios
K = [1500, 900, 300]
pr = [0.4, 0.1, 0.5]

Rev1 = zeros(nCenarios);
Rev2 = zeros(nCenarios);

for ω in Ω
    Rev1[ω] = 400
    Rev2[ω] = K[ω] - I;
end

println("Q1 = Renda Fixa")
println("Q2 = Sociedade\n")

# ============================     Item (a)     ============================== #
println("=== Item a ===")


# ====================     Dominância Determinística     ===================== #

println("1) Dominância Determinística")

#### -> Q1 Dominate Q2 <- ####

DD_Q1 = minimum(Rev1);
DD_Q2 = maximum(Rev2);

if (DD_Q1 >= DD_Q2)
    println("Q1 possui dominância determinística sobre Q2");
else
    println("Q1 NÃO possui dominância determinística sobre Q2");
end


#### -> Q2 Dominate Q1 <- ####

DD_Q1 = maximum(Rev1);
DD_Q2 = minimum(Rev2);

if (DD_Q2 >= DD_Q1)
    println("Q2 possui dominância determinística sobre Q1");
else
    println("Q2 NÃO possui dominância determinística sobre Q1");
end
println("")
# ============================================================================ #

# ===============     Dominância Estocástica Ponto-a-Ponto     =============== #

println("2) Dominância Estocástica Ponto-a-Ponto")

#### -> Q1 Dominate Q2 <- ####

global flagDEPP_Q1 = true;

for ω in Ω
    if (Rev1[ω] <= Rev2[ω])
        global flagDEPP_Q1 = false;
    end
end

if (flagDEPP_Q1)
    println("Q1 possui dominância estocástica ponto-a-ponto sobre Q2");
else
    println("Q1 NÃO possui dominância estocástica ponto-a-ponto sobre Q2");
end

#### -> Q2 Dominate Q1 <- ####

global flagDEPP_Q2 = true;

for ω in Ω
    if (Rev2[ω] <= Rev1[ω])
        global flagDEPP_Q2 = false;
    end
end

if (flagDEPP_Q2)
    println("Q2 possui dominância estocástica ponto-a-ponto sobre Q1");
else
    println("Q2 NÃO possui dominância estocástica ponto-a-ponto sobre Q1");
end

println("")
# ============================================================================ #

# ============================     Item (b)     ============================== #

println("=== Item b ===")

for k in collect(0:1000)
    Rev1_b = 400
    Rev2_b = k - I;

    if Rev2_b >= Rev1_b
        println("Q2 possui dominância determinística sobre Q1 quando o seu menor ganho é: ", k);
        break
    end
end

println("SEMPRE QUE HÁ DOMINÂNCIA DETERMINÍSTICA, HÁ DOMINÂNCIA ESTOCÁSTICA PONTO-A-PONTO")

println("")

# ============================     Item (c)     ============================== #
println("=== Item c ===")

# ==============     Dominância Estocástica Primeira Ordem     =============== #

println("3) Dominância Estocástica de Primeira Ordem")

#### -> Graphical Analysis <- ####

plot_FstOrder(Rev1, Rev2, pr, Ω);

flagDEPO_RF = calc_FstOrder(Rev1, Rev2, pr, Ω)

if (flagDEPO_RF)
    println("RF possui dominância estocástica de Primeira Ordem sobre Sociedade");
else
    println("RF NÃO possui dominância estocástica de Primeira Ordem sobre Sociedade");
end

flagDEPO_Soc = calc_FstOrder(Rev2, Rev1, pr, Ω)
if (flagDEPO_Soc)
    println("Sociedade possui dominância estocástica de Primeira Ordem sobre RF");
else
    println("Sociedade NÃO possui dominância estocástica de Primeira Ordem sobre RF");
end

println("\n")

# ============================     Item (d)     ============================== #
println("=== Item d ===")

# Análise do gráfico do item c:
# Para a Sociedade dominar renda fixa, ela deve estar sempre por baixo da renda fixa. Para isso, o Rendimento da renda fixa deve ser no máximo de 100
# Para a Renda fixa dominar a sociedade, ela deve estar sempre por baixo da sociedade. Para isso, o Rendimento da renda fixa deve ser no mínimo de 1300

for k in collect(0:10000)
    Rev1_d = repeat([k], nCenarios)
    flagDEPO_RF_d = calc_FstOrder(Rev1_d, Rev2, pr, Ω)
    if (flagDEPO_RF_d == true)
        println("RF possui dominância estocástica de Primeira Ordem sobre Sociedade, quando o Rendimento é no mínimo: ", k);
        # plot_FstOrder(Rev1_d, Rev2, pr, Ω);
        break
    end
end

for k in collect(10000:-1:0)
    Rev1_d = repeat([k], nCenarios)
    flagDEPO_Soc_d = calc_FstOrder(Rev2, Rev1_d, pr, Ω)
    if (flagDEPO_Soc_d == true)
        println("Sociedade possui dominância estocástica de Primeira Ordem sobre RF, quando o Rendimento é no máximo: ", k);
        plot_FstOrder(Rev1_d, Rev2, pr, Ω);
        break
    end
end

println("\n")

# ============================     Item (e)     ============================== #
println("=== Item e ===")

# ===============     Dominância Estocástica Segunda Ordem     =============== #

println("4) Dominância Estocástica de Segunda Ordem")

#### -> Graphical Analysis <- ####

plot_ScdOrder(Rev1, Rev2, pr, Ω);

flagDESO_RF = calc_ScdOrder(Rev1, Rev2, pr, Ω)

if (flagDESO_RF)
    println("RF possui dominância estocástica de Segunda Ordem sobre Sociedade");
else
    println("RF NÃO possui dominância estocástica de Segunda Ordem sobre Sociedade");
end

flagDESO_Soc = calc_ScdOrder(Rev2, Rev1, pr, Ω)
if (flagDESO_Soc)
    println("Sociedade possui dominância estocástica de Segunda Ordem sobre RF");
else
    println("Sociedade NÃO possui dominância estocástica de Segunda Ordem sobre RF");
end

# ============================     Item (f)     ============================== #
println("=== Item f ===")

# Análise do item e:
# Para a Sociedade dominar renda fixa, ela deve estar sempre por baixo da renda fixa. Para isso, o Rendimento da renda fixa deve ser no máximo de 100
# Para a Renda fixa dominar a sociedade, ela deve estar sempre por baixo da sociedade. Para isso, o Rendimento da renda fixa deve ser no mínimo de 640

for k in collect(0:10000)
    Rev1_f = repeat([k], nCenarios)
    flagDESO_RF_f = calc_ScdOrder(Rev1_f, Rev2, pr, Ω)
    if (flagDESO_RF_f == true)
        println("RF possui dominância estocástica de Segunda Ordem sobre Sociedade, quando o Rendimento é no mínimo: ", k);
        # plot_ScdOrder(Rev1_f, Rev2, pr, Ω);
        break
    end
end

for k in collect(10000:-1:0)
    Rev1_f = repeat([k], nCenarios)
    flagDESO_Soc_f = calc_ScdOrder(Rev2, Rev1_f, pr, Ω)
    if (flagDESO_Soc_f == true)
        println("Sociedade possui dominância estocástica de Segunda Ordem sobre RF, quando o Rendimento é no máximo: ", k);
        # plot_ScdOrder(Rev1_f, Rev2, pr, Ω);
        break
    end
end
