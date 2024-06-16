
# ============================================================================ #
# ========================       Risk Measures       ========================= #
# ============================================================================ #

using Distributions, Random
using JuMP
#using GLPK              # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/GLPK.jl | https://www.gnu.org/software/glpk/

using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.

# ======================     Parâmetros do Problema   ======================== #

q           = 40;                       # Newspaper Selling Price
c           = 25;                       # Newspaper Cost
r           = 15;                       # Newspaper Re-Selling Price
u           = 300;                      # Buying Capacity

Rmin        = -1000;                    # Risk Budget

flagVaR     = 0;                        # Allow VaR Constraints
flagCVaR    = 1;                        # Allow CVaR Constraints

α           = 0.95;                     # Confidence Level
M           = 1e6;                      # Large Number - VaR

# ========================     Sampling Process     ========================== #

nCenarios = 2000;                    # Number of Scenarios
Ω = 1:nCenarios;                    # Set of Scenarios
p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

dmin = 100;
dmax = 300;

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

# ============================================================================ #
# =======================     Problema Amostral     ========================== #
# ============================================================================ #

#m = Model(GLPK.Optimizer);
m = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(m, 0 <= x <= u, Int);
@variable(m, y[Ω] >= 0);
@variable(m, z[Ω] >= 0);
@variable(m, R[Ω]);

# ========== Restrições ========== #

@constraint(m, Rest1[ω in Ω], R[ω] == q*y[ω] + r*z[ω] - c*x);
@constraint(m, Rest2[ω in Ω], y[ω] <= d[ω]);
@constraint(m, Rest3[ω in Ω], y[ω] + z[ω] <= x);

# ========== VaR Constraints ========== #

if (flagVaR == 1)

    @variable(m, η[Ω], Bin)
    @variable(m, z_VaR);

    @constraint(m, Rest4, sum(η[ω]*p[ω] for ω in Ω) >= α);
    @constraint(m, Rest5[ω in Ω], R[ω] >= z_VaR - M*(1 - η[ω]));
    @constraint(m, Rest6, z_VaR >= -Rmin);

end;

# ========== CVaR Constraints ========== #

if (flagCVaR == 1)

    @variable(m, z_CVaR);
    @variable(m, β[Ω] >= 0);
    
    @constraint(m, Rest7, z_CVaR - sum(p[ω]*β[ω] for ω in Ω)/(1-α) >= -Rmin);
    @constraint(m, Rest8[ω in Ω], β[ω] >= z_CVaR - R[ω]);

end;

# ========== Função Objetivo ========== #

@objective(m, Max, sum(R[ω]*p[ω] for ω in Ω));

optimize!(m);

status      = termination_status(m);

ExpRevenue  = JuMP.objective_value(m);

ROpt        = JuMP.value.(R);
xOpt        = JuMP.value.(x);

ROrd        = sort(Array(ROpt[:]));
nStar       = Int(floor((1 - α)*nCenarios));

println(" ===================================== \n")

println(" Newspaper - Buy:           ", xOpt);
println(" Expected Revenue:          ", ExpRevenue, "\n");
println(" Value at Risk:             ", -ROrd[nStar + 1]);
println(" Conditional Value at Risk: ", -mean(ROrd[1:nStar]));

println(" ===================================== \n")