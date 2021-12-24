simple_state = """11111
19991
19191
19991
11111"""

begin
input = read("day11/input.txt", String)
input = map(split(input,"\n")) do s
    map(s |> collect) do ch
        parse(Int, ch)
    end'
end |> Base.Fix1(reduce,vcat)
end :: Matrix{Int}

dirs(coord) = begin
    ret = Iterators.product(-1:1,-1:1)
    ret = Iterators.filter(ret) do (a,b)
        a != 0 || b != 0
    end
    ret = Iterators.map(ret) do c
        CartesianIndex(Tuple(c) .+ Tuple(coord))
    end
    Iterators.filter(ret) do v
        (a,b) = Tuple(v)
        a >= 1 && b >= 1 &&
        (&)(((a,b) .<= size(input))...)
    end |> collect
end :: Vector{CartesianIndex{2}}

function dfs(newst, coords)
    visited = Set()
    frontier = coords
    while length(frontier) > 0
        tgt = pop!(coords)
        if tgt ∈ visited; continue end
        push!(visited, tgt)
        foreach(dirs(tgt)) do newcoord
            newst[newcoord] += 1
            if newcoord ∉ visited && newst[newcoord] >= 10
                push!(frontier,newcoord)
            end
        end
    end
end

flashes_by_step = []
function step(state :: Matrix{Int})
    newst = map(state) do v; v+1 end
    found = map((>=)(10), newst)
    coords = keys(found)[found]
    dfs(newst,coords)
    flashes = 0
    newst = map(newst) do octo
        if octo >= 10
            flashes += 1
            0
        else
            octo
        end
    end
    push!(flashes_by_step, flashes)
    newst
end
reduce(Iterators.repeated(nothing, 1000), init=input) do state,_
    step(state)
end
sum(flashes_by_step[begin:100])

#part 2
Iterators.dropwhile(enumerate(flashes_by_step)) do (i,flashcnt)
    flashcnt != length(input)
end |> Iterators.first |> x->x[1]





