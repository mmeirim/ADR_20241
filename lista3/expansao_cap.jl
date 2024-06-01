# ============================================================================ #
# ==================       Capacity Expansion Problem       ================== #
# ============================================================================ #

using CSV
using Distributions
using DataFrames
using JuMP
using GLPK              # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/GLPK.jl | https://www.gnu.org/software/glpk/

using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.

filePath = @__DIR__;

# ======================     Parâmetros do Problema   ======================== #

nCenarios   = 1000;
Ω           = 1:nCenarios;

nUnits      = 10;
I           = 1:nUnits;

# ============================     Data Read    ============================== #

Pathread    = string(filePath, "\\IN_c.csv");
df          = DataFrame(CSV.File(Pathread));
c           = df.c[:];

Pathread    = string(filePath, "\\IN_p.csv");
df          = DataFrame(CSV.File(Pathread));
p           = df.p[:];

Pathread    = string(filePath, "\\IN_u.csv");
df          = DataFrame(CSV.File(Pathread));
u           = df.u[:];

Pathread    = string(filePath, "\\IN_x0.csv");
df          = DataFrame(CSV.File(Pathread));
x0          = df.x0[:];

Pathread    = string(filePath, "\\IN_d.csv");
df          = DataFrame(CSV.File(Pathread));
d           = df.d[:];

Pathread    = string(filePath, "\\IN_q.csv");
df          = DataFrame(CSV.File(Pathread));
q           = df.q[:];

# ============================================================================ #

# =================     Problema Amostral    ===================== #

#CapExpModel = Model(GLPK.Optimizer);
CapExpModel = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(CapExpModel, x[I] >= 0);
@variable(CapExpModel, y[I,Ω] >= 0);
@variable(CapExpModel, z[Ω] >= 0);

# ========== Restrições ========== #

@constraint(CapExpModel, Rest1[i in I], x[i] + x0[i] <= u[i]);
@constraint(CapExpModel, Rest2[i in I, ω in Ω], y[i,ω] <= x[i] + x0[i]);
@constraint(CapExpModel, Rest3[ω in Ω], sum(y[i,ω] for i in I) + z[ω] >= d[ω]);

# ========== Função Objetivo ========== #

@objective(CapExpModel, Min, sum(c[i]*x[i] for i in I) + (1/nCenarios)*sum(q[ω]*z[ω] + sum(p[i]*y[i,ω] for i in I) for ω in Ω));

optimize!(CapExpModel);

status      = termination_status(CapExpModel);

TotalCost   = JuMP.objective_value(CapExpModel);
xOpt        = JuMP.value.(x);
yOpt        = JuMP.value.(y);
zOpt        = JuMP.value.(z);

println("\n=================================")

println("\nStatus: ", status, "\n");

for i in I
    println("   x[", i, "] = ", xOpt[i])
end

println("\nExpansion Cost:  ", sum(c[i]*xOpt[i] for i in I));
println("Operations Cost: ", (1/nCenarios)*sum(q[ω]*zOpt[ω] + sum(p[i]*yOpt[i,ω] for i in I) for ω in Ω));
println("\nTotal Cost:      ", TotalCost);

println("\n=================================")

# ============================================================================ #

# =================     Informação Perfeita     ===================== #

global CostEVPI    = zeros(nCenarios);

for ω in Ω

    #CapExpModel = Model(GLPK.Optimizer);
    CapExpModel = Model(Gurobi.Optimizer);
    
    # ========== Variáveis de Decisão ========== #

    @variable(CapExpModel, x[I] >= 0);
    @variable(CapExpModel, y[I] >= 0);
    @variable(CapExpModel, z >= 0);

    # ========== Restrições ========== #

    @constraint(CapExpModel, Rest1[i in I], x[i] + x0[i] <= u[i]);
    @constraint(CapExpModel, Rest2[i in I], y[i] <= x[i] + x0[i]);
    @constraint(CapExpModel, Rest3, sum(y[i] for i in I) + z >= d[ω]);

    # ========== Função Objetivo ========== #

    @objective(CapExpModel, Min, sum(c[i]*x[i] for i in I) + q[ω]*z + sum(p[i]*y[i] for i in I) );

    optimize!(CapExpModel);

    status      = termination_status(CapExpModel);
    CostEVPI[ω]    = JuMP.objective_value(CapExpModel);

end;

TotalCostEVPI   = (1/nCenarios)*sum(CostEVPI[ω] for ω in Ω);
EVPI            = TotalCost - TotalCostEVPI;

println("\n=================================");
println("EVPI:      ", EVPI);
println("\n=================================");

# ============================================================================ #

# =================     Valor da Solução Estocástica     ===================== #

avg_q       = mean(q);
avg_d       = mean(d);

#CapExpModel = Model(GLPK.Optimizer);
CapExpModel = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(CapExpModel, x[I] >= 0);
@variable(CapExpModel, y[I] >= 0);
@variable(CapExpModel, z >= 0);

# ========== Restrições ========== #

@constraint(CapExpModel, Rest1[i in I], x[i] + x0[i] <= u[i]);
@constraint(CapExpModel, Rest2[i in I], y[i] <= x[i] + x0[i]);
@constraint(CapExpModel, Rest3, sum(y[i] for i in I) + z >= avg_d);

# ========== Função Objetivo ========== #

@objective(CapExpModel, Min, sum(c[i]*x[i] for i in I) + avg_q*z + sum(p[i]*y[i] for i in I) );

optimize!(CapExpModel);

status      = termination_status(CapExpModel);
xVSS        = JuMP.value.(x);

global CostVSS    = zeros(nCenarios);

for ω in Ω

    #CapExpModel = Model(GLPK.Optimizer);
    CapExpModel = Model(Gurobi.Optimizer);

    # ========== Variáveis de Decisão ========== #

    @variable(CapExpModel, x[I] >= 0);
    @variable(CapExpModel, y[I] >= 0);
    @variable(CapExpModel, z >= 0);

    # ========== Restrições ========== #

    @constraint(CapExpModel, Rest1[i in I], x[i] + x0[i] <= u[i]);
    @constraint(CapExpModel, Rest2[i in I], y[i] <= x[i] + x0[i]);
    @constraint(CapExpModel, Rest3, sum(y[i] for i in I) + z >= d[ω]);

    @constraint(CapExpModel, RestVSS[i in I], x[i] == xVSS[i])

    # ========== Função Objetivo ========== #

    @objective(CapExpModel, Min, sum(c[i]*x[i] for i in I) + q[ω]*z + sum(p[i]*y[i] for i in I) );

    optimize!(CapExpModel);

    status      = termination_status(CapExpModel);
    CostVSS[ω]  = JuMP.objective_value(CapExpModel);

end;

TotalCostVSS   = (1/nCenarios)*sum(CostVSS[ω] for ω in Ω);
VSS            = TotalCostVSS - TotalCost;

println("\n=================================");
println("VSS:      ", VSS);
println("\n=================================");

# ============================================================================ #

# =================     Print - Resultados Finais     ===================== #

println("\n=================================")

println("\nStatus: ", status, "\n");

for i in I
    println("   x[", i, "] = ", xOpt[i])
end

println("\nExpansion Cost:  ", sum(c[i]*xOpt[i] for i in I));
println("Operations Cost: ", (1/nCenarios)*sum(q[ω]*zOpt[ω] + sum(p[i]*yOpt[i,ω] for i in I) for ω in Ω));
println("\nTotal Cost:      ", TotalCost);

println("\n\nEVPI:      ", EVPI);
println("\n\nVSS:      ", VSS);

println("\n=================================")