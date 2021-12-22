begin
input = read("day09/input.txt", String)
input = split(input, "\n")
input = map(input) do ln
    map(ln |> collect) do ch
        parse(Int, ch)
    end'
end |> Base.Fix1(foldl,vcat)
end

dir(i,j) = begin
    xs = zip([-1,1], Iterators.repeated(0)) 
    ys = zip(Iterators.repeated(0), [-1,1])
    k = map(Iterators.flatten([xs,ys]) |> collect) do p
        (i,j) .+ p
    end
    [e for e=k if foldl((&), (1,1) .<= e .<= size(input))]
end

lowpts = map(keys(input)) do coord :: CartesianIndex
    println(coord)
    verdicts = [input[c...] > input[Tuple(coord)...] for c=dir(Tuple(coord)...)]
    verdict = reduce((&), verdicts)
end
risk_levels = [input[k]+1 for k=keys(input) if lowpts[k]]
sum(risk_levels)

#part 2
function bfs(pt)
    expl = Set()
    q = [pt]
    while length(q) > 0
        tgt = popfirst!(q)
        push!(expl, tgt)
        foreach(dir(tgt...)) do np
            if input[np...] != 9 && np ∉ expl
                push!(q,np)    
            end        
        end
    end
    length(expl)
end
lens = [bfs(Tuple(k)) for k=keys(input) if lowpts[k]]
reduce(lens, init = []) do curmaxes,nxt
    push!(curmaxes,nxt)
    sort!(curmaxes, rev=true)
    if length(curmaxes) > 3; pop!(curmaxes) end
    curmaxes
end |> Base.Fix1(reduce, (*))