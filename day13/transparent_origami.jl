#fold up along horizontal y=...: flip bottom vertically and superimpose on top
#fold left along vertical x=...: flip right horizontally and superimpose on left

begin
input = read("day13/input.txt", String)
coords,instr = split(input, "\n\n")
coords = map(split(coords, "\n")) do c
    a,b = split(c, ",")
    (parse(Int,a)+1, parse(Int,b)+1)
end
instr = map(split(instr,"\n")) do i
    sym, num = match(r"^fold along ([xy])=([0-9]*)$", i).captures
    (sym == "y" ? :up : :left, parse(Int,num)+1)
end
end

begin
xdim = max(map(coords) do c; c[1] end...)
ydim = max(map(coords) do c; c[2] end...)
paper = fill(false,(ydim,xdim))
for (x,y)=coords
   paper[y,x] = true 
end
end

function foldup(grid :: Matrix{Bool},ycoord :: Int)
    height,width = size(grid)
    superimposed = copy(grid)
    for idx=keys(superimposed)
        y,x = Tuple(idx)
        if y >= ycoord
            continue
        end
        superimposed[y,x] |= superimposed[height - (y-1),x]
    end
    copy(@view superimposed[begin:ycoord-1,:])
end
function foldleft(grid :: Matrix{Bool},xcoord :: Int)
    height,width = size(grid)
    superimposed = copy(grid)
    for idx=keys(superimposed)
        y,x = Tuple(idx)
        if x >= xcoord
            continue
        end
        superimposed[y,x] |= superimposed[y,width - (x-1)]
    end
    copy(@view superimposed[:,begin:xcoord-1])
end

function readinstr(grid :: Matrix{Bool}, ins :: Tuple{Symbol,Int})
    cmd,arg = ins
    Dict(
        :up => foldup,
        :left => foldleft
    )[cmd](grid, arg)
end

# part one
reduce(readinstr,[instr[1]],init=paper) |> sum
#part two
function pretty(grid :: Matrix{Bool})
    foreach(eachrow(grid)) do row
        foreach(print ∘ x->x ? "\u25A0" : "-",row)
        println()
    end
end
pretty(reduce(readinstr,instr,init=paper))
#EFLFJGRF