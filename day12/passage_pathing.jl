begin
input = read("day12/input.txt", String)
cxns = Dict{String, Vector{String}}()
input = map(split(input, "\n")) do ln
    a,b = split(ln, "-")
    push!(get!(cxns, a, []), b)
    push!(get!(cxns, b, []), a)
end
cxns
end

function countpaths(from :: String, inpath :: Set{String})
    if from == "end"; return 1 end
    if islowercase(from[1]); push!(inpath, from) end
    map(cxns[from]) do nbr
        if nbr ∉ inpath
            countpaths(nbr, copy(inpath))
        else
            0
        end
    end |> sum
end

function countpaths()
    countpaths("start", Set{String}())
end
countpaths()

function explore_criteria(candidate :: String, inpath :: Vector{String})
    appearances = Base.count(==(candidate), inpath)
    if candidate == "start" || candidate == "end"
        appearances < 1
    elseif isuppercase(candidate[1])
        true
    else
        appearances == 0 || 
        allunique(Iterators.filter(inpath) do s
            s != "start" && s != "end" && islowercase(s[1])            
        end)
    end
end

function countpaths2(from :: String, inpath :: Vector{String})
    if from == "end"
        return 1 
    end
    push!(inpath,from)
    s = map(sort(cxns[from])) do nbr
        if explore_criteria(nbr,inpath)
            countpaths2(nbr, inpath)
        else
            0
        end
    end  |> sum
    pop!(inpath)
    s
end

function countpaths2()
    countpaths2("start",String[])
end
countpaths2()
