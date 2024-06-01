function plot_tax(u, q, c, β1, β2)

    R_antes = [i for i = 0:1:u*(q-c)];
    R_depoi = zeros(length(R_antes), nLines);
    R_fim   = zeros(length(R_antes));
    for i in 0:1:u*(q-c)
        for j in 1:1:nLines
            R_depoi[i+1,j] = β1[j] + β2[j]*R_antes[i+1];
        end
        R_fim[i+1] = minimum(R_depoi[i+1,:])
    end

    p = plot(R_antes, R_depoi, label = ["Tax = 0%" "Tax = 15%" "Tax = 50%"], title = "Post-Tax Revenue")
    p = plot!(R_antes, R_fim, label = "Tax Function", 
            xlabel = "Gross Revenue", ylabel = "Post-Tax Revenue", 
            legend=:topleft, width = 2, color = "black", fillalpha = 0.35, linestyle = :dashdot)

    display(p)
    savefig(p,"postTax_Rev.png")

end;