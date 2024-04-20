
using Plots

include("utils.jl");

function calc_Utility(x)
    if x >= -2000 && x < -500
        return (x/100) + 3
    end
    if x >= -500 && x < 500
        return x/250
    end
    if x >= 500 && x <= 2500
        return (x/500) + 1
    end
end

function calc_UtilityNew(x)
    return 5*calc_Utility(x) + 10    
end

# ============================     Item (b)     ============================== #
opcX = round(calc_Utility(3000-500) * 0.5 + calc_Utility(500-500) * 0.2 + calc_Utility(-1500-500) * 0.3; digits=2)
opcY = round(calc_Utility(1000-50) *0.5 + calc_Utility(300-50) * 0.2 + calc_Utility(-600-50) * 0.3; digits=2)

if opcX > opcY
    println("A relação de preferência é opcX ($opcX) > opcY ($opcY)")
elseif opcY > opcX
    println("A relação de preferência é opcY ($opcY) > opcX ($opcX)")
else
    println("A relação de preferência é opcX ($opcX) == opcY ($opcY)")
end

# ============================     Item (c)     ============================== #
# Considerando que a utilidade é 0.6, é possível identificar que ela esta no trecho da função utilidade definido por x/250.
#Trecho 1 é compreende o intervalo de utilidades: [-17;-2) 
#Trecho 2 é compreende o intervalo de utilidades: [-2;2) 
#Trecho 3 é compreende o intervalo de utilidades: [2;6] 

# Para calcular o Eq. Certo devemos olhar para o inverso da utilidade, logo:
eqC = opcY * 250
println("O equivalente certo é: ", eqC)

# Para calcular o Prêmio de risco devemos calcular o valor monetário esperado desta opção e calcular a diferênca entre ele e o 
# Eq. certo.

VME = round((1000-50) *0.5 + (300-50) * 0.2 + (-600-50) * 0.3; digits=2)
println("O prêmio de risco é: ", VME - eqC)

# ============================     Item (d)     ============================== #
opcX_d = round(calc_UtilityNew(3000-500) * 0.5 + calc_UtilityNew(500-500) * 0.2 + calc_UtilityNew(-1500-500) * 0.3; digits=2)
opcY_d = round(calc_UtilityNew(1000-50) *0.5 + calc_UtilityNew(300-50) * 0.2 + calc_UtilityNew(-600-50) * 0.3; digits=2)

if opcX_d > opcY_d
    println("A relação de preferência é opcX ($opcX_d) > opcY ($opcY_d)")
elseif opcY_d > opcX_d
    println("A relação de preferência é opcY ($opcY_d) > opcX ($opcX_d)")
else
    println("A relação de preferência é opcX ($opcX_d) == opcY ($opcY_d)")
end

# Justificar através do conceito de utilidade equivalente, pois é do formato α * u(x) + β

# ============================     Item (e)     ============================== #
nCenarios = 3
Ω = 1:nCenarios
pr = [0.5, 0.2, 0.3]
Kx = [3000, 500, -1500]
Ky = [1000, 300, -600]
Ix = 500
Iy = 50
RevX = zeros(nCenarios);
RevY = zeros(nCenarios);

for ω in Ω
    RevX[ω] = Kx[ω] - Ix
    RevY[ω] = Ky[ω] - Iy
end

for k in collect(0:10000)
    RevRF = repeat([k], nCenarios)
    flagDESO_RF_RevX = calc_ScdOrder(RevRF, RevX, pr, Ω)
    flagDESO_RF_RevY = calc_ScdOrder(RevRF, RevY, pr, Ω)
    if (flagDESO_RF_RevX && flagDESO_RF_RevY)
        println("RF possui dominância estocástica de Segunda Ordem sobre opção X e a opção Y, quando o Retorno é no mínimo: ", k);
        plot_ScdOrder(RevRF, RevY, pr, Ω);
        break
    end
end

# ============================     Item (f)     ============================== #
α = 0.70;     

VaR_opcY = calc_VaR(RevY, pr, α)
CVaR_opcY = calc_CVaR(RevY, pr, α);

println("Value-at-Risk - opcY: ", VaR_opcY);
println("Conditional Value-at-Risk - opcY: ", CVaR_opcY);
