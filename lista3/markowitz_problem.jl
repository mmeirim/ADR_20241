# ============================================================================ #
# ======================       Markowitz Problem       ======================= #
# ============================================================================ #

using JuMP
using Plots

using Ipopt             # Solver Gratuito de Programação Não Linear - https://github.com/jump-dev/Ipopt.jl | https://coin-or.github.io/Ipopt/

#using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.

# ======================     Parâmetros do Problema   ======================== #

μ  = [0.1699 ; 0.0657 ; 0.1088];

Σ  = [0.5719  -0.0248   0.0596 ;
     -0.0248   0.1522  -0.0342 ;
      0.0596  -0.0342   0.2852
];

Rmin = 0.10;

nAtivos = 3;
J = 1:nAtivos;

xDW = [ 0.00 , 0.00 , 0.00];
xUP = [ 0.50 , 0.50 , 0.50];

# ============================================================================ #

# ======================     Problema Markowitz     ========================== #

MarkowitzModel = Model(Ipopt.Optimizer);
#MarkowitzModel = Model(Gurobi.Optimizer);

# ========== Variáveis de Decisão ========== #

@variable(MarkowitzModel, x[J]);

# ========== Restrições ========== #

@constraint(MarkowitzModel, Rest1, sum(μ[j]*x[j] for j in J) == Rmin);  # Conjunto de Aceitação
@constraint(MarkowitzModel, Rest2, sum(x[j] for j in J) == 1);

@constraint(MarkowitzModel, Rest3[j ∈ J], x[j] ≤ xUP[j]);
@constraint(MarkowitzModel, Rest4[j ∈ J], x[j] ≥ xDW[j]);

# ========== Função Objetivo ========== #

@objective(MarkowitzModel, Min, sum(x[i]*Σ[i,j]*x[j] for i in J, j in J));

optimize!(MarkowitzModel);

status         = termination_status(MarkowitzModel);

Variance       = JuMP.objective_value(MarkowitzModel);
xOpt           = JuMP.value.(x);

println("\n=================================")

println("\nStatus: ", status, "\n");

println("\nMinimum Variance: ", Variance);
println("Allocation: (", xOpt[1], ", ", xOpt[2], ", ", xOpt[3], ")");

println("\n=================================")


# ============================================================================ #

# ======================     Efficient Frontier     ========================== #

min_x1      = -1.0;
max_x1      =  1.0;
step_x1     =  0.005;

min_x2      = -1.0;
max_x2      =  1.0;
step_x2     =  0.005;

global Expect = [];
global Varian = [];

flag_desvpad = true;

for x1 = min_x1:step_x1:max_x1
   for x2 = min_x2:step_x2:max_x2
      if (x1 + x2 ≤ 1)
         x3 = 1 - x1 - x2;
         global Expect = push!(Expect, μ[1]*x1 + μ[2]*x2 + μ[3]*x3);
         global Varian = push!(Varian, x1*x1*Σ[1,1] + x2*x2*Σ[2,2] + x3*x3*Σ[3,3] 
                                          + 2*x1*x2*Σ[1,2] + 2*x1*x3*Σ[1,3] 
                                          + 2*x2*x3*Σ[2,3]);
      end;
   end;
end;

label_y = "Risk -- Variance";
if (flag_desvpad)
     Varian = sqrt.(Varian);
     label_y = "Risk -- Standard Deviation";
end;

p2 = scatter(Varian, Expect,
      title = "Efficient Frontier",
      ylim = (-0.02,0.24),
      yticks = -0.02:0.02:0.24,
      ylabel = "Expected Return",
      xlim = (0,2.0),
      xticks = 0:0.2:2.0,
      xlabel = label_y,      
      label = false,
      ms=0.5, 
      ma=0.2
);

display(p2);