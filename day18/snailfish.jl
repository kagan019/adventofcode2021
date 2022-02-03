begin
    input = [ convert(Vector{Any}, Meta.parse(ln) |> eval)
        for ln=split(read("day18/input.txt", String),"\n")
    ]
end

mutable struct Node
    val :: Union{Vector{Node},Int}
    depth :: Int
    parent :: Union{Node,Nothing}
end

function collapse(n :: Node)
    if isleaf(n)
        n.val
    else
        [collapse(left(n)), collapse(right(n))]
    end
end

function isleaf(n :: Node)
    return typeof(n.val) == Int
end
function isterm(n :: Node)
    # both left and right are ints
    return !isleaf(n) && isleaf(left(n)) && isleaf(right(n))
end

function side(n :: Node)
    if n.parent === nothing
        return :root
    end
    if n === left(n.parent)
        :left
    elseif n === right(n.parent)
        :right
    else
        error("tree structured incorrectly")
    end
end

function join(a :: Node, b :: Node)
    @assert ((side(a), side(b)) .== :root) |> all
    function inc_depth(x :: Node)
        x.depth += 1
        if !isleaf(x)
            inc_depth(left(x))
            inc_depth(right(x))
        end
        x
    end
    newparent = Node(
        Node[inc_depth(a),inc_depth(b)],
        0,
        nothing
    ) 
    a.parent = newparent
    b.parent = newparent
    newparent
end

function left(n :: Node)
    @assert !isleaf(n)
    n.val[1]
end
function right(n :: Node)
    @assert !isleaf(n)
    n.val[2]
end

function leftmost_child(n :: Node) :: Node
    c = n
    while !isleaf(c)
        c = left(c)
    end
    c
end
function rightmost_child(n :: Node) :: Node
    c = n
    while !isleaf(c)
        c = right(c)
    end
    c
end

function left_nbr(n :: Node) :: Union{Node,Nothing}
    c = n
    while side(c) == :left
        c = c.parent
    end
    if side(c) === :root
        return nothing
    end
    
    rightmost_child(c.parent |> left)
end
function right_nbr(n :: Node) :: Union{Node,Nothing}
    c = n
    while side(c) == :right
        c = c.parent
    end
    if side(c) === :root
        return nothing
    end
    
    leftmost_child(c.parent |> right)
end


function snaxsplode_crit(cand :: Node)
    return isterm(cand) && cand.depth == 4
end
function snaxsplode(sna :: Node)
    l = left_nbr(sna)
    r = right_nbr(sna)
    if !isnothing(l)
        l.val += left(sna).val
    end
    if !isnothing(r)
        r.val += right(sna).val
    end
    sna.val = 0
    sna
end

function snasplit_crit(cand :: Node)
    return isleaf(cand) && cand.val >= 10
end
function snasplit(sna :: Node)
    lnd = Node(
        fld(sna.val,2),
        sna.depth+1,
        sna
    ) 
    rnd = Node(
        cld(sna.val,2),
        sna.depth+1,
        sna
    ) 
    sna.val = Node[lnd,rnd]
    sna
end

function maketree(
    sn, 
    parent, 
) :: Node
    depth = if !isnothing(parent)
        parent.depth+1
    else
        0
    end
    if typeof(sn) == Int
        Node(
            sn,
            depth,
            parent
        )
    else
        nd = Node(
            Vector{Node}(undef,2),
            depth,
            parent
        ) 
        nd.val[1] = maketree(sn[1], nd)
        nd.val[2] = maketree(sn[2], nd)
        nd
    end
end

function maketree(sna :: Vector{Any})
    maketree(sna, nothing)
end

function snasimplify(sna :: Node)
    todos = [:split, :explode]
    crit = Dict(
        :split => snasplit_crit,
        :explode => snaxsplode_crit
    )
    oper = Dict(
        :split => snasplit,
        :explode => snaxsplode
    )
    while todos |> length > 0
        todo = pop!(todos)
        stack = [sna]
        while (stack |> length) > 0
            v = pop!(stack)
            if crit[todo](v)
                oper[todo](v)
                todos = [:split, :explode]
                break
            end
            
            if !isleaf(v)
                append!(stack, [
                    right(v),
                    left(v)
                ])
            end
        end
    end
    sna
end

function snailfish_add(sna :: Node, snb :: Node)
    snasimplify(join(sna,snb))
end

function dbg(x :: Vararg{<:Any})
    println(x...)
    x[1]
end

function magnitude(sna :: Int)
    sna
end
function magnitude(sna :: Vector{<:Any})
    return 3*magnitude(sna[1]) + 2*magnitude(sna[2])
end

# maketree.(input) .|> (x->x) .|> collapse
# reduce(snailfish_add,maketree.(input)) |> collapse |> magnitude



begin
nodes = maketree.(input)
m = -1
for i=1:lastindex(nodes)-1
    for j=i+1:lastindex(nodes)
        global m = max(
            m,
            snailfish_add(deepcopy(nodes[i]),deepcopy(nodes[j])) |> 
                collapse |> magnitude,
            snailfish_add(deepcopy(nodes[j]),deepcopy(nodes[i])) |> 
                collapse |> magnitude
        )
    end
end
m
end