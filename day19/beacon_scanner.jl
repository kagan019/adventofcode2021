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

function compose(second :: Tran, first :: Tran)
    # rotation r ∘ tranlation t = rotate(r,t) ∘ t
    translation after rotation (Tran)
    [ cos -sin xt
      sin cos  yt
       0    0  1]
    rotation after translation
    [ cos -sin (xt cos - yt sin)
      sin  cos 
       0   0   1 ]  
    
    
    [ cos -sin 0 
     sin cos  0
     0    0  1]
    [ 1   xt
        1 yt
          1 ]

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

function trymatch(s1 :: Int, s2 :: Int) :: Union{Tran,Nothing}
    for b1=eachindex(input[s1] :: Scanner)
        for rot=eachrot()
            rotated = rotate.([rot],input[s2])
            for b2=eachindex(rotated)
                translation = input[s1][b1] .- rotated[b2]
                transformed = [rd .+ translation for rd=rotated]
                if length(intersect(transformed,input[s1])) >= 12
                    return Tran(rot,translation)
                end
            end
        end
    end
    return nothing
end

function matchall()
    while !all(map((!) ∘ isnothing,haspos))
        for s1=eachindex(sloc)
            if isnothing(sloc[s1]); continue end
            for s2=eachindex(sloc)
                if !isnothing(sloc[s2]); continue end
                # s1 is something, s2 is nothing
                mtch = trymatch(s1,s2)
                sloc[s2] = (!isnothing(mtch)) ? compose(mtch,sloc[s1]) : nothing
            end
        end
    end
end

function countbeacons()
    assert(length(sloc) == length(input))
    beacons = Set()
    for (i,scn)=enumerate(input)
        scn :: Scanner
        sloc[i] :: Tran
        transformed = sloc[i].(scn) :: Scanner
        insert!.([beacons],transformed)
    end
    beacons |> length
end


function main()
    matchall()
    countbeacons()
end
