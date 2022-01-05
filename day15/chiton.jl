
mutable struct MinHeap{T}
    coll :: Vector{T} 
    cmp :: Function
    function MinHeap{T}(cmp :: Function) where T
        h = new()
        h.coll = T[]
        h.cmp = cmp 
        h
    end
end

import Base.push!
function push!(h :: MinHeap{T}, e :: T) where T
    if isempty(h.coll)
        push!(h.coll,e)
    else
        o = pop!(h.coll)
        push!(h.coll,argmax(h.cmp,[o,e]))
        push!(h.coll,argmin(h.cmp,[o,e]))
    end
end

import Base.pop!
function pop!(h :: MinHeap{T}) where T
    x  = pop!(h.coll)
    sort!(h.coll; by = h.cmp, rev=true)
    x
end

import Base.length
function length(h :: MinHeap{T}) where T
    length(h.coll)
end

begin
cave = split(read("day15/input.txt",String),"\n")
cave = map(cave) do row
    map(row |> collect) do c
        parse(Int,c)
    end'
end |> Base.Fix1(foldl,vcat)
end

using Base.Iterators

struct Coord
    i :: Int
    j :: Int
    cost :: Float64
end
function dijkstras(mtx :: Matrix{Int})
    function dirs(p :: Tuple{Int64, Int64})
        map([(-1,0),(1,0),(0,1),(0,-1)]) do (a,b)
            i,j = (a,b) .+ p
            d1,d2 = size(mtx)
            if !(1 <= j <= d2) | !(1 <= i <= d1)
                []
            else
                [(i,j)]
            end
        end |> flatten |> collect
    end

    costs = fill(Inf,size(mtx))
    costs[1,1] = 0
    visited = Set{Tuple{Int,Int}}()
    frontier = MinHeap{Coord}(x->x.cost)
    push!(frontier,Coord(1,1,0))
    while length(frontier) > 0
        tgt = pop!(frontier) :: Coord
        tgtp = (tgt.i,tgt.j)
        if tgtp ∈ visited
            continue
        end
        push!(visited, tgtp)
        for (i,j)=dirs(tgtp)
            costs[i,j] = min(costs[i,j], costs[tgtp...]+mtx[i,j])
            push!(frontier, Coord(i,j,costs[i,j]))
        end
    end
    costs
end
dijkstras(cave)
# part 2
repeatcall(fun :: Function) = begin
    Iterators.accumulate(∘, repeated(fun))
end

rolling(cavesys) = Iterators.map(
    repeatcall(Base.Fix1(map,loc->(loc % 9)+1))
) do inceach
    inceach(cavesys)
end
begin
# horizontal reps
newcave = [ 
    [cave],take(rolling(cave), 4)
] |> flatten |> Base.Fix1(foldl,hcat)
# vertical reps
newcave = [
    [newcave],take(rolling(newcave),4)
] |> flatten |> Base.Fix1(foldl,vcat)
end
dijkstras(newcave)