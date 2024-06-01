using CSV
using Distributions
using DataFrames
using JuMP
using GLPK 

filePath = @__DIR__;

# ======================     Parâmetros do Problema   ======================== #

c_v = [100.0, 150.0, floatmax(Float64)]                 # Custo variavel de produçao do gerador 1 e 2, por unidade de energia (MWh)
p = [5, 10, 0]                      # Capacidade maxima de produçao do gerador 1 e 2, por unidade de energia (MWh)

c_exp = [50.0, 100.0, floatmax(Float64)]                # Custo maximo de expansao do gerador 1 e 2, por unidade de energia (R$/MWh)
cap_max = [typemax(Int64), 30, 0]   # Capacidade maxima de expansão do gerador 1 e 2, por unidade de energia (MWh)

nUnits      = 2;
I           = 1:nUnits;

F = [0.0  5.0  10.0;
     5.0  0.0  35.0;
     10.0 35.0 0.0;]

# ============================     Data Read    ============================== #

Pathread    = string(filePath, "\\IN_d - Q6.csv");
df          = DataFrame(CSV.File(Pathread));
d           = df.d[:];
prob        = df.p[:];
Ω           = 1:length(d);

# ================================ letra (c) ================================= #

# =================     Problema Amostral    ===================== #

CapExpModel = Model(GLPK.Optimizer);
# CapExpModel = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(CapExpModel, x[I] >= 0);
@variable(CapExpModel, y[I,Ω] >= 0);

# ========== Restrições ========== #

@constraint(CapExpModel, Rest1[i in I], x[i] <= p[i] + cap_max[i]);
@constraint(CapExpModel, Rest2[i in I, ω in Ω], y[i,ω] <= x[i] + p[i]);
@constraint(CapExpModel, Rest3[ω in Ω], sum(y[i,ω] for i in I) >= d[ω]);

# ========== Função Objetivo ========== #

@objective(CapExpModel, Min, sum(c_exp[i]*x[i] for i in I) + sum(prob[ω]*c_v[i]*y[i,ω] for i in I for ω in Ω));

optimize!(CapExpModel);

status      = termination_status(CapExpModel);

TotalCost   = JuMP.objective_value(CapExpModel);
xOpt        = JuMP.value.(x);
yOpt        = JuMP.value.(y);

println("\n=================================")

println("\nStatus: ", status, "\n");

for i in I
    println("   x[", i, "] = ", xOpt[i])
end

for i in I
        println("   y[", i, "] = ", sum(prob[ω]*yOpt[i,ω] for ω in Ω))
end

println("\nExpansion Cost:  ", sum(c_exp[i]*xOpt[i] for i in I));
println("Operations Cost: ", sum(prob[ω]*c_v[i]*yOpt[i,ω] for i in I for ω in Ω));
println("\nTotal Cost:      ", TotalCost);

println("\n=================================")

# # ================================ letra (d) ================================= #
function checkFeasability(F,yOpt, ω)
    last = 3
    f = deepcopy(F)
    for i in I
        direct = min(yOpt[i,ω], f[i,last])
        f[i, last] -= direct; f[last, i] = f[i, last]

        remaing = yOpt[i,ω] - direct
        mid_node = findfirst(!isequal(i), I)

        indirect = min(remaing, f[i,mid_node], f[mid_node, last])
        f[i, mid_node] -=  indirect; f[mid_node, i] = f[i, mid_node]
        f[mid_node, last] -=  indirect; f[last, mid_node] = f[mid_node, last]

        # println(f)
        if remaing - indirect > 0
            return false
        end
    end
    return true
end

f_list = []
for ω in Ω
    push!(f_list, checkFeasability(F, yOpt, ω))
end

println("Número de cenários que continuam viáveis após rede de transmissão: ", count(f_list))
println("Número de cenários que deixam de ser viáveis após rede de transmissão: ",  count(i -> i==false, f_list))
# println(f_list)

# ================================ letra (e) ================================= #

# =================     Problema Amostral    ===================== #

CapExpModelFlow = Model(GLPK.Optimizer);
# CapExpModel = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

IFlow = 1:(nUnits+1)
@variable(CapExpModelFlow, x[IFlow] >= 0);
@variable(CapExpModelFlow, y[IFlow,Ω] >= 0);
@variable(CapExpModelFlow, f[IFlow,IFlow,Ω] >= 0);

# ========== Restrições ========== #

@constraint(CapExpModelFlow, Rest1[i in IFlow[1:nUnits]], x[i] <= p[i] + cap_max[i]);
@constraint(CapExpModelFlow, Rest2[i in IFlow[1:nUnits], ω in Ω], y[i,ω] <= x[i] + p[i]);
@constraint(CapExpModelFlow, Rest3[ω in Ω], sum(y[i,ω] for i in IFlow[1:nUnits]) >= d[ω]);

# @constraint(CapExpModelFlow, Rest4[ω in Ω, j in IFlow[1:nUnits]], sum(f[i,j,ω] for i in IFlow[1:nUnits]) == sum(f[j,i,ω] for i in IFlow[1:nUnits]))

@constraint(CapExpModelFlow, Rest4[ω in Ω, j in IFlow[1:nUnits]], sum(f[:,j,ω]) + y[j,ω] == sum(f[j,:,ω]))
# # @constraint(CapExpModelFlow, Rest5[ω in Ω], sum(f[:,(nUnits+1),ω]) >= d[ω])
@constraint(CapExpModelFlow, Rest7[ω in Ω, i in IFlow, j in IFlow], f[i,j,ω] <= F[i,j])

# ========== Função Objetivo ========== #

@objective(CapExpModelFlow, Min, sum(c_exp[i]*x[i] for i in IFlow[1:nUnits]) + sum(prob[ω]*c_v[i]*y[i,ω] for i in IFlow[1:nUnits] for ω in Ω));

optimize!(CapExpModelFlow);

status      = termination_status(CapExpModelFlow);

TotalCost   = JuMP.objective_value(CapExpModelFlow);
xOptFlow    = JuMP.value.(x);
yOptFlow    = JuMP.value.(y);
fOptFlow    = JuMP.value.(f);

println("\n=================================")

println("\nStatus: ", status, "\n");

for i in IFlow
    println("   x[", i, "] = ", xOptFlow[i])
end

for i in IFlow
    println("   y[", i, "] = ", sum(prob[ω]*yOptFlow[i,ω] for ω in Ω))
end

# println(fOptFlow)

println("\nExpansion Cost:  ", sum(c_exp[i]*xOptFlow[i] for i in I));
println("Operations Cost: ", sum(prob[ω]*c_v[i]*yOptFlow[i,ω] for i in IFlow for ω in Ω));
println("\nTotal Cost:      ", TotalCost);

println("\n=================================")