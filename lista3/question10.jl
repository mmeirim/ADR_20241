using CSV
using Distributions
using DataFrames
using JuMP
using Statistics
using Ipopt
using Plots

filePath = @__DIR__;
Pathread    = string(filePath, "\\IN_HistData.csv");
df          = DataFrame(CSV.File(Pathread));
Ativo1           = df.Ativo1[:];
Ativo2           = df.Ativo2[:];
Ativo3           = df.Ativo3[:];

Ret1 = mean(Ativo1); Ret2 = mean(Ativo2); Ret3 = mean(Ativo3); 
Var1 = var(Ativo1); Var2 = var(Ativo2); Var3 = var(Ativo3)
Cov12 = cov(Ativo1, Ativo2); Cov13 = cov(Ativo1, Ativo3); Cov23 = cov(Ativo2, Ativo3)

μ  = [Ret1 ; Ret2 ; Ret3];

Σ  = [Var1   Cov12  Cov13 ;
      Cov12   Var2  Cov23 ;
      Cov13  Cov23   Var3 ;
];

nAtivos = 3;
J = 1:nAtivos;

function runMarkowitzModel(J, Rmin)
    MarkowitzModel = Model(Ipopt.Optimizer);
    set_silent(MarkowitzModel)
    
    @variable(MarkowitzModel, x[J]);

    @constraint(MarkowitzModel, Rest1, sum(μ[j]*x[j] for j in J) == Rmin);  # Conjunto de Aceitação
    @constraint(MarkowitzModel, Rest2, sum(x[j] for j in J) == 1);

    @objective(MarkowitzModel, Min, sum(x[i]*Σ[i,j]*x[j] for i in J, j in J));

    optimize!(MarkowitzModel);

    status         = termination_status(MarkowitzModel);
    Variance       = JuMP.objective_value(MarkowitzModel);
    xOpt           = JuMP.value.(x);
    return status, Variance, xOpt
end

# ======================  letra (a)  ========================== #

Rmin = 0.14

status, Variance, xOpt = runMarkowitzModel(J, Rmin)
println("\n========= letra (a) =========")
println("\nStatus: ", status,);
println("Minimum Variance: ", Variance);
println("Allocation: (", xOpt[1], ", ", xOpt[2], ", ", xOpt[3], ")");
println("\n ============================")

# ======================  letra (b)  ========================== #

global Expect = [];
global Varian = [];
for r in 0:0.001:0.25
    s, v, xo = runMarkowitzModel(J, r)
    global Expect = push!(Expect, r);
    global Varian = push!(Varian, v);
end

flag_desvpad = true;

label_y = "Risk -- Variance";
if (flag_desvpad)
     Varian = sqrt.(Varian);
     label_y = "Risk -- Standard Deviation";
end;


p10b = plot!(Varian, Expect,
      kind="scatter",
      mode="lines",
      title = "Efficient Frontier - 10b",
      ylabel = "Expected Return",
      xlabel = label_y,      
      label = false,
      linewidth=2
);

display(p10b);
savefig(p10b, "lista3/images/q10b_efficientfrontier.png")

# ======================  letra (c)  ========================== #
