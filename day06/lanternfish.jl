lanternfish = cd("day06") do
    map(read("input.txt", String) |>
        Base.Fix2(split, ",")) do s
        parse(Int, s)
    end
end

function day(ltnf)
    ages = Iterators.map(ltnf) do lf
        lf -1
    end
    ready = Iterators.filter(ages) do lf
        lf < 0
    end
    full = Iterators.map(ages) do lf
        (lf < 0) ? 6 : lf
    end
    newfish = Iterators.map(ready) do lf
        9 + lf
    end
    Iterators.flatten([full,newfish])
end

function efficient_day(ltnf :: AbstractArray{Int}) :: Dict{Int,Int}
    reduce(ltnf; init=Dict{Int,Int}()) do dict,i
        get!(dict,i,0)
        dict[i] += 1
        dict
    end |> efficient_day
end
function efficient_day(ltnf :: Dict{Int,Int}) :: Dict{Int,Int}
    zeros = get(ltnf,0,0)
    ages = Iterators.map(filter((!=)(0), keys(ltnf))) do i
        i-1 => get(ltnf,i) do; @assert false end
    end |> Dict
    mergewith((+),ages, Dict(6 => zeros, 8 => zeros))
end

days = Iterators.take(
    Iterators.accumulate(Iterators.repeated(nothing), init=lanternfish) do last,_
        day(last) |> collect
    end,
    80
) |> collect 
 
day256 = reduce(
    Iterators.repeated(nothing, 256), 
    init=lanternfish
) do last, _
    efficient_day(last)
end
day256 |> values |> sum

function showdays()
    foreach(enumerate(days |> collect)) do (i,x)
        print("$i: $x\n")
    end
end

# showdays()

