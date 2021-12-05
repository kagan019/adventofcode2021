# (called_nums, (last_called,boardsstr)) = 
cd("day04") do 
    read("sample.txt",String)
end |> x->split(x,",")# |> 
    x-> ( 
        x[:end-1],
        x[end] |> y->(y[1],y[4:end]) # final char, then bingo tables
    )


