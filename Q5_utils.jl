# ============================================================================ #
# ======================       Utilitarie Codes       ======================== #
# ============================================================================ #


# ======================    Cumulative Distribution Plot   ========================= #

function plot_FstOrder(Rev1, pr, Ω, nameFig, labelGraph)

    MinRev = minimum(Rev1) - 0.25*abs(minimum(Rev1));
    MaxRev = maximum(Rev1) + 0.25*maximum(Rev1);

    SetRange = MinRev:1:MaxRev;
    Tamanho = length(SetRange);

    ProbAcum1 = zeros(Tamanho);
    global iter = 1;

    for t in SetRange
        ProbAcum1[iter] = sum(pr[ω]*(Rev1[ω] <= t) for ω in Ω);
        iter += 1;
    end

    p = plot(SetRange, ProbAcum1, 
        label = "Decião Ótima :: $labelGraph", title = "Distribuição Acumulada :: Decisão Ótima",
        ylabel = "Probabilidade Acumulada",
        lw = 3
    );
    display(p);
    savefig(p, "$nameFig.png");

end;

# ======================    Distribution Plot   ========================= #

function plot_FstOrder_PDF(Rev1, pr, nameFig, labelGraph)

       p = bar(Rev1, pr, 
        label = "Perfil de Risco :: $labelGraph",
        title = "Perfil de Risco :: Decisão Ótima",
        ylabel = "Densidade de Probabilidade",
        xticks = Rev1,
        bar_width = 0.1
    )

    display(p)
    savefig(p, "$nameFig.png")

end;