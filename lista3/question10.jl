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
    
    @variable(MarkowitzModel, x[J] >=0);

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
# savefig(p10b, "lista3/images/q10b_efficientfrontier.png")

# ======================  letra (c)  ========================== #
# Teoricamente podemos justificar que com essa alocação, o retorno é de 11.2%, com desvio padr\~ao de 37.28% e é possível obter este mesmo retorno com uma variÂnia menor.
fix = [0.2, 0.2, 0.6]
varianc = sqrt(sum(fix[i]*Σ[i,j]*fix[j] for i in J, j in J))
expec = sum(μ[j]*fix[j] for j in J)

p10c = plot!(p10b, [varianc], [expec] ,seriestype="scatter", labels="Allocation - 10c")
display(p10c);
# savefig(p10c, "lista3/images/q10c_efficientfrontierAllocation.png")

status, Variance, xOpt = runMarkowitzModel(J, expec)
println("\n========= letra (c) =========")
println("\nStatus: ", status,);
println("Minimum Variance: ", Variance);
println("Allocation: (", xOpt[1], ", ", xOpt[2], ", ", xOpt[3], ")");
println("\n ============================")

# ======================  letra (d)  ========================== #
function runMarkowitzModelFixedAtv3(J, Rmin)
    MarkowitzModel = Model(Ipopt.Optimizer);
    set_silent(MarkowitzModel)
    
    @variable(MarkowitzModel, x[J]);

    @constraint(MarkowitzModel, Rest1, sum(μ[j]*x[j] for j in J) == Rmin);  # Conjunto de Aceitação
    @constraint(MarkowitzModel, Rest2, sum(x[j] for j in J) == 1);
    @constraint(MarkowitzModel, Rest3, x[3] == 0.4)

    @objective(MarkowitzModel, Min, sum(x[i]*Σ[i,j]*x[j] for i in J, j in J));

    optimize!(MarkowitzModel);

    status         = termination_status(MarkowitzModel);
    Variance       = JuMP.objective_value(MarkowitzModel);
    xOpt           = JuMP.value.(x);
    return status, Variance, xOpt
end

sd, vd, xOptd = runMarkowitzModelFixedAtv3(J, Rmin)
println("\n========= letra (d) =========")
println("\nStatus: ", sd,);
println("Minimum Variance: ", vd);
println("Allocation: (", xOptd[1], ", ", xOptd[2], ", ", xOptd[3], ")");
println("\n ============================")

# ======================  letra (e)  ========================== #
println("\n========= letra (e) =========")

retE = sum(Ativo1[i] * xOptd[1] + Ativo2[i] * xOptd[2] + Ativo3[i] * xOptd[3] < Rmin for i in 1:length(Ativo1))
probE = retE/length(Ativo1)
println(probE)

# ======================  letra (f)  ========================== #
# Não é viável

sf, vf, xOptf = runMarkowitzModel(J, 0.2)
println("\n========= letra (f) =========")
println("\nStatus: ", sf,);
println("Minimum Variance: ", vf);
println("Allocation: (", xOptf[1], ", ", xOptf[2], ", ", xOptf[3], ")");
println("\n ============================")

# ======================  letra (g)  ========================== #
# Alocar tudo na renda fixa pq ja alcanço o retorno desejado e com variancia/risco 0
μ  = [Ret1 ; Ret2 ; Ret3; Rmin];

Σ  = [Var1   Cov12  Cov13  0 ;
      Cov12   Var2  Cov23  0 ;
      Cov13  Cov23   Var3  0 ;
        0       0     0    0
];

nAtivos = 4;
J = 1:nAtivos;
sg, vg, xOptg = runMarkowitzModel(J, Rmin)
println("\n========= letra (g) =========")
println("\nStatus: ", sg,);
println("Minimum Variance: ", vg);
println("Allocation: (", xOptg[1], ", ", xOptg[2], ", ", xOptg[3], ", ", xOptg[4], ")");
println("\n ============================")