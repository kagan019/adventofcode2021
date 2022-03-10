flat = collect ∘ Iterators.flatten 

[[[1]],[[2]],[[3]],[]] .|> flat


struct Rot
    # the orientation of x, 0-3 turns around z or +/-z
    xface :: Union{Tuple{Bool, Bool}, Bool} 
    # the number of turns around the new x
    yface :: Tuple{Bool, Bool} 
end

const Pos = Tuple{Int,Int,Int}


function rotate(r :: Rot, p :: Pos) :: Pos
    signify(b :: Bool) = Int(!b)*2-1
    function turn_plane(t :: Bool,o :: Bool, x,y)
        # no. ccw turns looking toward axis +(x cross y)
        # two turns: flip
        x,y = (signify(t),) .* (x,y)
        # rotate ccw one turn
        if o
            -y,x
        else
            x,y
        end
    end

    x,y,z = p
    y,z = turn_plane(r.yface..., y,z)
    x,y,z = if isa(r.xface,Bool)
        # false: 1 turn ccw looking at (global) +y
        # true: 1 turn cw
        x,z = turn_plane(r.xface,true,x,z)
        x,y,z
    else
        x,y = turn_plane(r.xface...,x,y)
        x,y,z
    end 
    (x,y,z)
end

rotate(Rot((true,false),(false,false)), (1,-1,0))

struct Tran
    r :: Rot
    p :: Pos
end

function (t :: Tran)(p :: Pos)
    rotated = rotate(t.r,p)
    transformed = rotated .+ t.p 
end

const Scanner = Vector{Pos}

begin
input = split(read("day19/sample.txt", String),"\n")
input = reduce(input, init=[]) do red,nxt
    if red |> length == 0 || match(r"---",nxt) !== nothing
        push!(red,[nxt])
    else 
        push!(red[end],nxt)
    end
    red
end
input = map(input) do scnr
    (map(scnr :: Vector{<:AbstractString}) do ln
        m = match(r"([-]?[0-9]+),([-]?[0-9]+),([-]?[0-9]+)",ln)
        if m !== nothing
            Pos[parse.([Int],m.captures) |> Tuple]
        else
            Pos[]
        end
    end |> flat) :: Scanner
end 
end :: Vector{Scanner}


function eachrot()
    both = [false,true]
    er = Iterators.product(both,both)
    er = Iterators.product(Iterators.flatten([er,both]),er)
    Iterators.map(er) do r
        Rot(r...)
    end |> collect
end

begin
sloc = Union{Tran,Nothing}[nothing for _ = input]
sloc[1] = Tran(Rot((false,false),(false,false)),(0,0,0))
end

function trymatch(s1 :: Int, s2 :: Int) :: Tuple{Pos,Rot}
    for b1=eachindex(input[s1])
        for b2=eachindex(input[s2])
            for rot=eachrot()
                rotated = rotate.([rot],input[s2])
                translation = tuple(input[s1][b1]) .- tuple(rotated[b2])
                transformed = (tuple.(input[s2]) .+ [translation])

            end 
        end
    end
end

function matchall()
    while !all(map(nisn,haspos))
        for s1=eachindex(sloc)
            if isnothing(sloc[s1]); continue end
            for s2=eachindex(sloc)
                if !isnothing(sloc[s2]); continue end
                sloc[s2] = trymatch(s1,s2)
            end
        end
    end
end

function countbeacons()
    beacons = Set()
    for (i,scn)=enumerate(input)
        rotated = rotate.(sloc[i][2], scn)
        transformed = rotated .+ sloc[i][1]
        insert!.([beacons],scn)
    end
end


function num_beacons()
    nb = length.(input) |> sum
    for ci=eachindex(IndexCartesian(), relpos)
        if relpos[ci] !== nothing
            i,j = Tuple(ci)
            p,r = relpos[ci]
            rotated = rotate.([r],input[i])
            transformed = gallilean.([p],rotated)
            nb -= intersect(transformed, input[j]) |> length
        end
    end
    return nb
end

num_beacons()