flat = collect ∘ Iterators.flatten 

struct Rot
    xface :: Union{Tuple{Bool, Bool}, Bool} # either num turns around z or +/-z
    yface :: Tuple{Bool, Bool} # around new z
end

const Pos = Tuple{Int,Int,Int}

function rotate(r :: Rot, p :: Pos) :: Pos
    signify(b :: Bool) = Int(!b)*2-1
    x,y,z = tuple(p)
    y,z = begin
        t,o = r.yface
        y = signify(t) * y
        if o
            z,y
        else
            y,z
        end
    end
    x,y,z = if isa(r.xface,Bool)
        x = signify(r.xface)*x
        y,z,x
    else
        t,o = r.xface
        x = signify(t)*x
        if o
            y,x,z
        else
            x,y,z
        end
    end 
    (x,y,z)
end
rotate(Rot(false,(false,false)), (1,-1,0))

[[[1]],[[2]],[[3]],[]] .|> flat

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
    map(scnr) do ln
        m = match(r"([-]?[0-9]+),([-]?[0-9]+),([-]?[0-9]+)",ln)
        if m !== nothing
            [(parse.([Int],m.captures)...)]
        else
            Pos[]
        end
    end |> Iterators.flatten |> collect
end 
end :: Vector{Vector{Pos}}


function eachrot()
    both = [false,true]
    er = Iterators.product(both,both)
    er = Iterators.product(Iterators.flatten([er,both]),er)
    Iterators.map(er) do r
        Rot(r...)
    end |> collect
end

begin
sloc = [nothing for _ in input]
sloc[1] = (Pos(0,0,0),Rot((false,false),(false,false)))
end

function trymatch(s1 :: Int, s2 :: Int)
    for b1=eachindex(input[s1])
        for b2=eachindex(input[s2])
            for rot=eachrot()
                translation = tuple(input[s1][b1]) .- tuple(input[s2][b2])
                rotated = rotate.([rot],input[s2])
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

# relative pos from scanner colidx to rowidx
function rp()
    relpos = Matrix{Union{Tuple{Pos,Rot},Nothing}}(nothing,length(input),length(input))
    project(dims :: Int, beacon :: Pos) = getindex(tuple(beacon), 1:dims)
    ovlp_range = -2000:2000
    origins1d = Pos.(ovlp_range,[0],[0])
    for si=eachindex(input)
        print("$(si)/$(lastindex(input))\n")
        for rot=eachrot
            rotated = rotate.([rot], input[si])
            #fully translated scanner for each origin
            transformed1d = [
                orgn.x => (project.([1], gallilean.([orgn],rotated))) 
                for orgn=origins1d
            ] |> Dict
            for sj=si+1:lastindex(input)
                proj1d = project.([1],input[sj]) |> Set
                proj2d = project.([2],input[sj]) |> Set
                scannerj = input[sj] |> Set
                successx = map(ovlp_range) do tryx
                    isect = intersect(transformed1d[tryx],proj1d)
                    if length(isect) >= 12
                        Int[tryx]
                    else
                        Int[]
                    end
                end |> flat
                successx :: Vector{Int}
                
                successxy = Tuple{Int,Int}[]
                for (x,)=successx
                    origins2d = Pos.([x],ovlp_range,[0])
                    transformed2d = [
                        orgn.y => (project.([2],gallilean.([orgn],rotated))) 
                        for orgn=origins2d
                    ] |> Dict
                    for tryy=ovlp_range
                        isect = intersect(transformed2d[tryy],proj2d)
                        if length(isect) >= 12
                            push!(successxy,(x,tryy))
                        end
                    end
                end

                for (x,y)=successxy
                    origins3d = Pos.([x],[y],ovlp_range)
                    transformed3d = [
                        orgn.z => (gallilean.([orgn],rotated)) 
                        for orgn=origins3d
                    ] |> Dict
                    for tryz=ovlp_range
                        isect = intersect(transformed3d[tryz],scannerj)
                        if length(isect) >= 12
                            if relpos[si,sj] !== nothing
                                throw(DomainError([relpos[si,sj], "->", (Pos(x,y,tryz),rot)]))
                            end
                            relpos[si,sj] = (Pos(x,y,tryz),rot)
                        end
                    end
                end
            end
        end
    end
    return relpos
end

print(rp())
# here I cached the output
relpos = Union{Nothing, Tuple{Pos, Rot}}[
    nothing nothing nothing nothing nothing; 
    nothing nothing nothing (Pos(-160, 1134, 23), Rot((false, false), (false, false))) nothing; 
    nothing nothing nothing nothing nothing; 
    nothing nothing nothing nothing nothing; 
    nothing nothing nothing nothing nothing
]

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