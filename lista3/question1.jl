# ============================================================================ #
# ======================       Newsvendor Problem       ====================== #
# ============================================================================ #

using Distributions, Random
using Plots
using JuMP
using GLPK              # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/GLPK.jl | https://www.gnu.org/software/glpk/

using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.

include("utils.jl");

# ======================     Parâmetros do Problema   ======================== #

u = 150;
q = 60;
r = 10;
c = 20;
flag_tax = false;

# nLines = 3;
# SetLines = 1:nLines;
# p_break = [0.00 ; 1500 ; 3000];
# β2 = [1.00 ;  0.75 ; 0.50];
# β1 = [0.00 ; (β2[1] - β2[2])*p_break[2] ; ((β2[1] - β2[2])*p_break[2] + p_break[3]*(β2[2] - β2[3]))];

# if (flag_tax) plot_tax(u, q, c, β1, β2); end;

# ============================================================================ #

# ========================     Sampling Process     ========================== #

nCenarios = 50000;                  # Number of Scenarios
Ω = 1:nCenarios;                    # Set of Scenarios
p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

dmin = 50;
dmax = 150;

# ===================================
#      =====> Using Julia <=====     
# ===================================

# -> https://juliastats.org/Distributions.jl/stable/ <- #

Random.seed!(1);
d  = rand(Uniform(dmin, dmax), nCenarios);

# ===================================
#         =====> Using R <=====     
# ===================================

# -> https://juliainterop.github.io/RCall.jl/stable/ <- #

#R"set.seed(1)"
#d  = rcopy(R"runif($nCenarios, min = $dmin, max = $dmax)");

# ============================================================================ #

# ========================     Sample Problem     ============================ #

NewsVendorProb = Model(GLPK.Optimizer);
# NewsVendorProb = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(NewsVendorProb, x >= 0);
@variable(NewsVendorProb, y[Ω] >= 0);
@variable(NewsVendorProb, z[Ω] >= 0);
@variable(NewsVendorProb, R[Ω]);
@variable(NewsVendorProb, R_a[Ω]);

# ========== Restrições ========== #

@constraint(NewsVendorProb, Rest1, x <= u);
@constraint(NewsVendorProb, Rest2[ω in Ω], y[ω] <= d[ω]);
@constraint(NewsVendorProb, Rest3[ω in Ω], y[ω] + z[ω] <= x);
@constraint(NewsVendorProb, Rest4[ω in Ω], R_a[ω] == q*y[ω] + r*z[ω] - c*x);
# @constraint(NewsVendorProb, Rest5[ω in Ω, i in SetLines], R[ω] <= β1[i] + β2[i]*R_a[ω]);
@constraint(NewsVendorProb, Rest6[ω in Ω], z[ω] <= 0.1*x);


# ========== Função Objetivo ========== #

if (flag_tax)
    @objective(NewsVendorProb, Max, sum(R[ω]*p[ω] for ω in Ω));
else
    @objective(NewsVendorProb, Max, sum(R_a[ω]*p[ω] for ω in Ω));
end

optimize!(NewsVendorProb);

status      = termination_status(NewsVendorProb);

Profit      = JuMP.objective_value(NewsVendorProb);
xOpt        = JuMP.value.(x);
yOpt        = JuMP.value.(y);
zOpt        = JuMP.value.(z);

println("==============================\n")
println("Status: ", status);
println("Lucro Jornaleiro: ", Profit);
println("Quant. Jornais: ", xOpt);
println("\n==============================")