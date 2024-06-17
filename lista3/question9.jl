using JuMP
using Plots

using Ipopt

# ======================     Parâmetros do Problema   ======================== #

μ  = [0.24 ; 0.10]; # Mercado; Ativo A

Σ  = [0.320  0.254 ;
      0.254  0.280 ;
];

nAtivos = 2;
J = 1:nAtivos;

# xDW = [ 0.00 , 0.00 , 0.00];
# xUP = [ 0.50 , 0.50 , 0.50];

# ======================  letra (b) ========================== #

min_x      = -1.0;
max_x      =  2.0;
step_x     =  0.01;

global Expect = [];
global Varian = [];

flag_desvpad = true;

for x = min_x:step_x:max_x
    if (x + (1-x) ≤ 1)
        global Expect = push!(Expect, μ[1]*x + μ[2]*(1-x));
        global Varian = push!(Varian, (x^2)*Σ[1,1]^2 + ((1-x)^2)*Σ[2,2]^2 + 2*x*(1-x)*Σ[1,2]*Σ[1,1]*Σ[2,2]);
    end;
end;

label_y = "Risk -- Variance";
if (flag_desvpad)
     Varian = sqrt.(Varian);
     label_y = "Risk -- Standard Deviation";
end;

p2 = plot!(Varian, Expect,
      kind="scatter",
      mode="lines",
      title = "Efficient Frontier",
      ylabel = "Expected Return",
      xlabel = label_y,
      linewidth=2,
      labels="Efficient Frontier - 9b",
);

mvar, mexp = findmin(Varian)
display(p2);
# savefig(p2, "lista3/images/q9b_efficientfrontier.png")

# ======================  letra (c) ========================== #

Rmin = Expect[mexp]
MarkowitzModel = Model(Ipopt.Optimizer);
set_silent(MarkowitzModel)
# ========== Variáveis de Decisão ========== #

@variable(MarkowitzModel, x[J]);

# ========== Restrições ========== #

# @constraint(MarkowitzModel, Rest1, sum(μ[j]*x[j] for j in J) == Rmin);  # Conjunto de Aceitação
@constraint(MarkowitzModel, Rest2, sum(x[j] for j in J) == 1);
@constraint(MarkowitzModel, Rest4[j in J], x[j] >= 0);
# @constraint(MarkowitzModel, Rest5[j in J], x[j] <= 2);


# ========== Função Objetivo ========== #

@objective(MarkowitzModel, Min, sum(x[i]^2*Σ[i,i]^2 for i in J) + sum(x[i]*x[j]*Σ[i,j]*Σ[i,i]*Σ[j,j] for i in J, j in filter(x->x!=i, J)));

optimize!(MarkowitzModel);

status         = termination_status(MarkowitzModel);

Variance       = JuMP.objective_value(MarkowitzModel);
xOpt           = JuMP.value.(x);

println("\n=================================")

println("\nStatus: ", status, "\n");

println("\nMinimum Variance: ", sqrt(Variance));
println("Allocation: (", xOpt[1], ", ", xOpt[2], ")");
println("\nExpect: ", sum(μ[j]*xOpt[j] for j in J));

println("\n=================================")

p3 = plot!(p2, [sqrt(Variance)], [sum(μ[j]*xOpt[j] for j in J)],seriestype="scatter", labels="Allocation - Min DP - 9b")
display(p3);
# savefig(p3, "lista3/images/q9c_minvar.png")

# ======================  letra (d) ========================== #
# tg = (μ[1] -μ[2]) / (Σ[1,1]- Σ[1,2]*Σ[2,2])

# ======================  letra (e) ========================== #
# Expect = μ[1]*x + 0.06*(1-x)
# DP = x*Σ[1,1]

# ======================  letra (f) ========================== #
global Expect_lr = [];
global Varian_lr = [];

flag_desvpad = true;

for x = min_x:step_x:max_x
    if (x + (1-x) ≤ 1)
        global Expect_lr = push!(Expect_lr, μ[1]*x + 0.06*(1-x));
        global Varian_lr = push!(Varian_lr, (x^2)*Σ[1,1]^2);
    end;
end;

p4 = plot!(p3,sqrt.(Varian_lr), Expect_lr,
      kind="scatter",
      mode="lines",
      linewidth=2,
      labels="Efficient Frontier - 9f",
);

display(p4)
# savefig(p4, "lista3/images/q9f_efficientfrontier.png")

# ======================  letra (g) ========================== #

μ  = [0.24 ; 0.06]; # Mercado; RF

Σ  = [0.320 0 ;
        0   0 ;
];

MarkowitzModel_g = Model(Ipopt.Optimizer);
set_silent(MarkowitzModel_g)

# ========== Variáveis de Decisão ========== #

@variable(MarkowitzModel_g, x[J]);

# ========== Restrições ========== #

@constraint(MarkowitzModel_g, Rest1, sum(μ[j]*x[j] for j in J) == Rmin);  # Conjunto de Aceitação
@constraint(MarkowitzModel_g, Rest2, sum(x[j] for j in J) == 1);

# ========== Função Objetivo ========== #

@objective(MarkowitzModel_g, Min, sum(x[i]^2*Σ[i,i]^2 for i in J[1]));

optimize!(MarkowitzModel_g);

status         = termination_status(MarkowitzModel_g);

Variance       = JuMP.objective_value(MarkowitzModel_g);
xOpt           = JuMP.value.(x);

println("\n=================================")

println("\nStatus: ", status, "\n");

println("\nMinimum Variance: ", Variance);
println("Allocation: (", xOpt[1], ", ", xOpt[2], ")");

println("\n=================================")

p5 = plot!(p4, [sqrt(Variance)], [Expect[mexp]],seriestype="scatter", labels="Allocation - Min DP - 9g")
display(p5);

# savefig(p5, "lista3/images/q9g_efficientfrontiermindp.png")

# ======================  letra (h) ========================== #
# a partir da formula da variancia => x = +- sqrt(V(Lc))/σm
# a partir do valor esperado => E[Lc] = rf - x(μm -rf) =: E[Lc] = rf +- (μm -rf)/σm * sqrt(V(Lc))

# ======================  letra (i) ========================== #
# igualando => (μm -μa)/(σm - ρam*σa) = (μm -rf)/σm
# σm*μm - σm*μa - σm*μm + σm*rf + ρam*σa*μm - ρam*σa*rf = 0
# -σm*(μa-rf) + ρam*σa*(μm -rf) = 0
# μa-rf = (ρam*σa/σm)*(μm -rf)
# μa = rf + (ρam*σa/σm)*(μm -rf), sendo βa = (ρam*σa/σm)

# ======================  letra (j) ========================== #
