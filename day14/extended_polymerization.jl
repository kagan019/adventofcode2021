begin
input = read("day14/input.txt",String)
template,rrules = split(input,"\n\n")
template = String(template)
rrules = map(split(rrules,"\n")) do rr
    a,b = split(rr," -> ")
    String(a),String(b)
end |> Dict{String,String}
end

function step(template :: String)
    matched = map(1:length(template)-1) do i
        pat = template[i:i+1]
        get(rrules,pat,nothing)
    end
    rewritten = []
    for (m,t)=zip(matched,template)
        push!(rewritten,t)
        if ~isnothing(m)
            push!(rewritten,m)
        end
    end
    push!(rewritten,last(template))
    join(rewritten)
end

plymr = reduce(
    Iterators.take(Iterators.repeated(nothing),10), 
    init=template
) do red,_
    step(red)
end

counts = reduce(plymr, init=Dict{Char,Int}()) do red,cur
    red[cur] = get!(red,cur,0)+1
    red
end
max(values(counts)...) - min(values(counts)...)

#part2
# this is my first attempt thats O(length of final string = 2^40) which is much much too large

function recurse(pat :: String, level=0 :: Int, store=Dict{Char,Int}() :: Dict{Char,Int})
    if level == 40 || !haskey(rrules,pat)
        store
    else
        store[rrules[pat] |> only] = get!(store,rrules[pat] |> only,0) + 1
        begin # left
            newpat = "$(pat[1])$(rrules[pat])"
            recurse(newpat,level+1,store)
        end
        begin # right
            newpat = "$(rrules[pat])$(pat[2])"  
            recurse(newpat,level+1,store)
        end
        store
    end
end

function dfs(pat :: String)
    store = Dict{Char,Int}()
    frontier = [(pat,0)]
    while length(frontier) > 0
        tgt,lvl = pop!(frontier)
        if lvl == 25
            continue
        end
        if haskey(rrules,tgt)
            gen = rrules[tgt] |> only
            store[gen] = get!(store,gen,0) + 1
            lpat = "$(tgt[1])$(gen)"
            rpat = "$(gen)$(tgt[2])"
            push!(frontier,(lpat,lvl+1))
            push!(frontier,(rpat,lvl+1))
        end
    end
    store
end

function tooslow()
    counttemplate = reduce(template,init=Dict{Char,Int}()) do red,cur
        red[cur] = get!(red,cur,0)+1
        red
    end
    counts = mergewith(+,counttemplate,
        map(1:length(template)-1) do i
            pat=template[i:i+1]
            dfs(pat)
        end...
    )
    max(values(counts)...) - min(values(counts)...)
end

#part2, take 2
# how many letters does the input use?
letters = [
    map(keys(rrules) |> collect) do str
        [str[1],str[2]]
    end |> Iterators.flatten,
    map(only,values(rrules))    
] |> Iterators.flatten |> Set |> collect
length(letters)
#so what is the size of a (sparse) transition matrix from every possible 2-pattern
#to every other possible 2-pattern?
num_2pats = length(letters)^2
matrix_size = num_2pats^2
#then roughly how many multiplications would matrix multiplication between two
#such matrixes require? 
multiplications = matrix_size^2
# a hundred million multiplications in a fast loop should take about 12 seconds
# on my high end laptop.  but, well use sparse matrixes AND throw in fast 
#exponentiation, which is already impl in julia. watch this:
using SparseArrays
m =sprandn(num_2pats,num_2pats, 0.2)
@time m^40
# about a hundredth of a second. magic!
# this exponentiated vector of the initial pattern->pattern transition matrix
# will be the transition for 40 steps. all you do is dot it with the vector
# of the counts of appearences of each pattern. the final vector is the vector of
# appearances of a patterns in the final polymer. 
#every letter appears once every two times it occurs in some pattern--except for the 
#letters on the ends! fortunately, those don't change, so we can straightforwardly 
# realize this final polymer vector into the number of appearences of each character.
letterpos = reduce(enumerate(letters), init=Dict{Char,Int}()) do d, (i,v)
    d[v]=i
    d
end
# pat is basically a number in base length(letters)
patpos(pat :: String) = (letterpos[pat[1]]-1)*(length(letters)) +
    (letterpos[pat[2]]-1) + 1 #
pospat(pos :: Int) = "$(letters[fld(pos-1,length(letters))+1])$(letters[(pos-1) % length(letters)+1])"
begin
patvec = zeros(Int,num_2pats)
for i=1:length(template)-1
    p="$(template[i])$(template[i+1])"
    patvec[patpos(p)]+=1
end 
end
begin
transition = zeros(Int,(num_2pats,num_2pats))
for (k,v)=pairs(rrules)
    lpat = "$(k[1])$(v)"
    rpat = "$(v)$(k[2])"
    transition[patpos(lpat),patpos(k)] = 1
    transition[patpos(rpat),patpos(k)] = 1
end
end
final_vec = (transition)^40 * patvec
# turns out using a SparseMatrix makes this no faster.
length(final_vec)
begin
#the number of occurences of a pattern that contains a given letter
letappearances = Dict{Char,Int}()
for (i,patc)=enumerate(final_vec)
    lchar = pospat(i)[1]
    rchar = pospat(i)[2]
    letappearances[lchar] = get!(letappearances,lchar,0) + patc
    letappearances[rchar] = get!(letappearances,rchar,0) + patc
end
letappearances
end
# the characters on the ends of the template stay on the ends of the final polymer.
#therefore, the characters on the end of the template should have an odd count and 
# the remaining characters should have an even count
begin
# the counts of each letter in the final polymer
letcount = Iterators.map(letappearances |> collect) do (k,v)
    k,(v % 2 + fld(v,2))
end |> Dict
end
max(values(letcount)...) - min(values(letcount)...)