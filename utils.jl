# ============================================================================ #
# ======================       Utilitarie Codes       ======================== #
# ============================================================================ #


# ======================    Fisrt Order Plot   ========================= #

function plot_FstOrder(Rev1, Rev2, pr, Ω)

    MinRev = min(minimum(Rev1), minimum(Rev2)) - 0.1*(min(minimum(Rev1), minimum(Rev2)));
    MaxRev = max(maximum(Rev1), maximum(Rev2)) + 0.1*(max(maximum(Rev1), maximum(Rev2)));

    SetRange = MinRev:1:MaxRev;
    Tamanho = length(SetRange);

    ProbAcum1 = zeros(Tamanho);
    ProbAcum2 = zeros(Tamanho);
    global iter = 1;

    for t in SetRange
        ProbAcum1[iter] = sum(pr[ω]*(Rev1[ω] <= t) for ω in Ω);
        ProbAcum2[iter] = sum(pr[ω]*(Rev2[ω] <= t) for ω in Ω);
        iter += 1;
    end

    p = plot(SetRange, ProbAcum1, label = "Q1", title = "Cumulative Distribution", lw = 3);
    p = plot!(SetRange, ProbAcum2, label = "Q2", lw = 3, legend=:topleft);
    display(p)
    savefig(p,"Plot_FstOrder.png")

end;

# ======================    Second Order Plot   ========================= #

function plot_ScdOrder(Rev1, Rev2, pr, Ω)

    MinRev = min(minimum(Rev1), minimum(Rev2)) - 0.1*(min(minimum(Rev1), minimum(Rev2)));
    MaxRev = max(maximum(Rev1), maximum(Rev2)) + 0.1*(max(maximum(Rev1), maximum(Rev2)));

    SetRange = MinRev:1:MaxRev;
    Tamanho = length(SetRange);

    ProbAcum1 = zeros(Tamanho);
    ProbAcum2 = zeros(Tamanho);
    global iter = 1;

    for z in SetRange
        ProbAcum1[iter] = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
        ProbAcum2[iter] = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
        iter += 1;
    end

    p = plot(SetRange, ProbAcum1, label = "Q1", title = "Second Order -- Cumulative Distribution", lw = 3);
    p = plot!(SetRange, ProbAcum2, label = "Q2", lw = 3, legend=:topleft);
    display(p)
    savefig(p,"Plot_ScdOrder.png")

end;

# ======================    First Order Function   ========================= #

function calc_FstOrder(Rev1, Rev2, pr, Ω)

    # println("3) Dominância Estocástica de Primeira Ordem")
    #### -> Q1 Dominate Q2 <- ####

    global flagDEPO_Q1 = true;

    for z in Rev1

        F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
        F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
        
        if (F_Q1 > F_Q2)
            global flagDEPO_Q1 = false;
        end
        
    end

    for z in Rev2

        F_Q1 = sum(pr[ω]*(Rev1[ω] <= z) for ω in Ω);
        F_Q2 = sum(pr[ω]*(Rev2[ω] <= z) for ω in Ω);
        
        if (F_Q1 > F_Q2)
            global flagDEPO_Q1 = false;
        end

    end
    return flagDEPO_Q1
end

# ======================    Second Order Function   ========================= #

function calc_ScdOrder(Rev1, Rev2, pr, Ω)
        
    flagDESO_Q1 = true;

    for z in Rev1

        F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
        F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
        
        if (F2_Q1 > F2_Q2)
            flagDESO_Q1 = false;
        end

    end

    for z in Rev2

        F2_Q1 = sum(pr[ω]*max(z - Rev1[ω],0) for ω in Ω);
        F2_Q2 = sum(pr[ω]*max(z - Rev2[ω],0) for ω in Ω);
        
        if (F2_Q1 > F2_Q2)
            flagDESO_Q1 = false;
        end

    end

    return flagDESO_Q1
end

# ====================     Value-at-Risk     ===================== #

function calc_VaR(Rev1, pr, α)  
    MatAux = [Rev1 pr];
    Rev1_Ord = MatAux[sortperm(MatAux[:,1]),:];

    # Value-at-Risk -> Q1 #
    flagVaR = true;
    ωOp = 1;
    ProbAc = 0;

    while (flagVaR)
        ProbAc = ProbAc + Rev1_Ord[ωOp,2];
        if (ProbAc > (1 - α))
            flagVaR = false;
        else
            ωOp += 1;
        end
    end

    VaR_Q1 = -Rev1_Ord[ωOp,1];
    return VaR_Q1
end

# ===============     Conditional Value-at-Risk     =============== #

function calc_CVaR(Rev1, pr, α)
    VaR_Q1 = calc_VaR(Rev1, pr, α)
    CVaR_Q1 = VaR_Q1 + sum(pr[ω]*max(-VaR_Q1 - Rev1[ω],0) for ω in Ω)/(1 - α);
    return CVaR_Q1
end