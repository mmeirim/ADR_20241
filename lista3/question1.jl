# ============================================================================ #
# ======================       Newsvendor Problem       ====================== #
# ============================================================================ #
println("AQUI")
using Distributions, Random
using Plots
using JuMP
# using GLPK              # Solver Gratuito de Programação Linear & Inteira Mista - https://github.com/jump-dev/GLPK.jl | https://www.gnu.org/software/glpk/

using Gurobi            # Solver Comercial de Programação Matemática - https://github.com/jump-dev/Gurobi.jl | https://www.gurobi.com/
                        #   --> A PUC-Rio possui licença acadêmica gratuita para os alunos.

include("utils.jl");

# ======================     Parâmetros do Problema   ======================== #

u = 150;
q = 60;
r = 10;
c = 20;
Rmin = -1000;                    # Risk Budget


# ========================     Sampling Process     ========================== #

function generateScenarios(nCenarios)
    Ω = 1:nCenarios;                    # Set of Scenarios
    p = ones(nCenarios)*(1/nCenarios);  # Equal Probability

    dmin = 50;
    dmax = 150;

    Random.seed!(1);
    d  = rand(Uniform(dmin, dmax), nCenarios);
    return d, Ω, p
end

# ========================     Sample Problem     ============================ #

function solveNewsvendorProblem(nCenarios, useCVaR, useLambda) 
    d, Ω, p = generateScenarios(nCenarios)

    # NewsVendorProb = Model(GLPK.Optimizer);
    NewsVendorProb = Model(Gurobi.Optimizer);
    set_silent(NewsVendorProb);

    @variable(NewsVendorProb,0 <= x <= u, Int);
    @variable(NewsVendorProb, y[Ω] >= 0);
    @variable(NewsVendorProb, z[Ω] >= 0);
    @variable(NewsVendorProb, R_a[Ω]);

    @constraint(NewsVendorProb, Rest1[ω in Ω], R_a[ω] == q*y[ω] + r*z[ω] - c*x);
    @constraint(NewsVendorProb, Rest2[ω in Ω], y[ω] <= d[ω]);
    @constraint(NewsVendorProb, Rest3[ω in Ω], y[ω] + z[ω] <= x);
    @constraint(NewsVendorProb, Rest4[ω in Ω], z[ω] <= 0.1*x);

    if (useCVaR)
        @variable(NewsVendorProb, z_CVaR);
        @variable(NewsVendorProb, β[Ω] >= 0);
        
        @constraint(NewsVendorProb, Rest5, z_CVaR - sum(p[ω]*β[ω] for ω in Ω)/(1-α) >= -Rmin);
        @constraint(NewsVendorProb, Rest6[ω in Ω], β[ω] >= z_CVaR - R_a[ω]);
    end;

    if (useLambda)
        @variable(NewsVendorProb, z_CVaR);
        @variable(NewsVendorProb, β[Ω] >= 0);
        @constraint(NewsVendorProb, Rest6[ω in Ω], β[ω] >= z_CVaR - R_a[ω]);

        @objective(NewsVendorProb, Max, (1-λ)*sum(R_a[ω]*p[ω] for ω in Ω) + λ*(z_CVaR - sum(p[ω]*β[ω] for ω in Ω)/(1-α)));
    else
        @objective(NewsVendorProb, Max, sum(R_a[ω]*p[ω] for ω in Ω));
    end

    optimize!(NewsVendorProb);

    status      = termination_status(NewsVendorProb);

    Profit      = JuMP.objective_value(NewsVendorProb);
    xOpt        = JuMP.value.(x);
    yOpt        = JuMP.value.(y);
    zOpt        = JuMP.value.(z);
    ROpt        = JuMP.value.(R_a);
    if (useLambda)
        z_CVaROpt   = JuMP.value.(z_CVaR);
        βOpt        = JuMP.value.(β);
        return status, Profit, xOpt, yOpt, zOpt, ROpt, z_CVaROpt, βOpt
    end
    return status, Profit, xOpt, yOpt, zOpt, ROpt
end

# ========================  letra b  ============================ #

ll = [sum((1/100)*(q*min(x,d) + r*min(max(x-d, 0), 0.1*x) - c*x) for d in 50:150) for x in 1:150]
e, xx = findmax(ll)

# ========================  letra c  ============================ #
# O Resultado é um pouco diferente do real devido ao pequeno número de cenários que faz com que a realidade não seja bem representada
nCenarios = 20
useCVaR = false
useLambda = false
status, Profit, xOpt = solveNewsvendorProblem(nCenarios, useCVaR, useLambda)
println("============ letra (c) ==================\n")
println("Status: ", status);
println("Lucro Jornaleiro: ", Profit);
println("Quant. Jornais: ", xOpt);
println("\n==============================")

# ========================  letra e  ============================ #
# É possível ver que com mais cenários o resultado começa a convergir para valores próximos ao do problema real. Para igualar o valor é necessário mais cenários com o gurobi
# nCenarios = 100000
# useCVaR = false
# useLambda = false
# tCenarios = collect(1:1000:nCenarios)
# prof = []
# xs = []
# for n in tCenarios
#     print("(n=$n)")
#     status, Profit, xOpt = solveNewsvendorProblem(n, useCVaR, useLambda)
#     append!(xs, xOpt)
#     append!(prof, Profit)
# end

# pe = plot(tCenarios, prof, xlabel="Número de Cenários", ylabel="Receita Esperada", label="", title="Gráfico de  Nº de Cenários X Receita Esperada", legend=false)
# display(pe)
# pe2 = plot(tCenarios, xs, xlabel="Número de Cenários", ylabel="Solução ótima", label="", title="Gráfico de  Nº de Cenários X Solução ótima", legend=false)
# display(pe2)
# savefig(pe, "lista3/images/q1e_profCenarios.png")
savefig(pe2, "lista3/images/q1e_solCenarios.png")


# ========================  letra f  ============================ #
nCenarios = 100000
α = 0.95;
d, Ω, p = generateScenarios(nCenarios)
xStar = 120
ROrd = sort([q*min(xStar,d[ω]) + r*min(max(xStar-d[ω], 0), 0.1*xStar) - c*xStar for ω in Ω])
nStar = Int(floor((1 - α)*nCenarios));
println("============ letra (f) ==================\n")
println(" Conditional Value at Risk: ", -mean(ROrd[1:nStar]));
println("\n==============================")

# ========================  letra g  ============================ #

nCenarios = 100000
useCVaR = true
useLambda = false
α= 0.95; 
Rmin = -2000;                    # Risk Budget
status, Profit, xOpt, yOpt, zOpt, ROpt = solveNewsvendorProblem(nCenarios,useCVaR,useLambda)
ROrd = sort(Array(ROpt[:]));
nStar = Int(floor((1 - α)*nCenarios));
println("============ letra (g) ==================\n")
println("Status: ", status);
println("Lucro Jornaleiro: ", Profit);
println("Quant. Jornais: ", xOpt);
println(" Conditional Value at Risk: ", -mean(ROrd[1:nStar]));
println("\n==============================")

# ========================  letra h  ============================ #
nCenarios = 100000
useCVaR = false
useLambda = true
α = 0.95; 
λ = 0.5
status, Profit, xOpt, yOpt, zOpt, ROpt = solveNewsvendorProblem(nCenarios,useCVaR, useLambda)
ROrd = sort(Array(ROpt[:]));
nStar = Int(floor((1 - α)*nCenarios));
CVaR = -mean(ROrd[1:nStar])

println("============ letra (h) ==================\n")
println("Status: ", status);
println("Lucro Jornaleiro: ", Profit);
println("Quant. Jornais: ", xOpt);
println("\n==============================")

# ========================  letra i  ============================ #

# nCenarios = 100000
# useCVaR = false
# useLambda = true
# tLambdas = collect(0:0.01:1)
# xStars = []
# expValues = []
# CVaRValues = []
# for n in tLambdas
#     λ = n
#     print("(λ=$λ)")
#     status, Profit, xOpt, yOpt, zOpt, rOpt, z_CVaROpt, βOpt = solveNewsvendorProblem(nCenarios, useCVaR, useLambda)
#     append!(expValues, sum(rOpt[ω]*p[ω] for ω in Ω))
#     append!(CVaRValues, z_CVaROpt - sum(p[ω]*βOpt[ω] for ω in Ω)/(1-α))
#     append!(xStars, xOpt)
#     println(xOpt, sum(rOpt[ω]*p[ω] for ω in Ω),  z_CVaROpt - sum(p[ω]*βOpt[ω] for ω in Ω)/(1-α))
# end

# p_i = plot(xStars, tLambdas, xlabel="x*", ylabel="λ", label="", title="Gráfico de x* X λ", legend=false)
# display(p_i)
# p_i2 = plot(CVaRValues, expValues, xlabel="CVaR", ylabel="Valor esperado", label="", title="Gráfico de CVaR X Valor Experado", legend=false)
# display(p_i2)
# savefig(p_i, "lista3/images/q1i_xstarlambdas.png")
# savefig(p_i2, "lista3/images/q1i_CVaRExpect.png")