using Base.Iterators

struct Instr
    cmd::String
    mag::Int
end


input = map(cd("day02") do 
    split(read("input.txt",String),"\n")
end) do s; 
    caps = match(r"(forward|up|down) ([0-9]*)",s).captures
    Instr(caps[1],parse(Int,caps[2]))
end

ops = Dict(
    "forward" => (1,0),
    "down" => (0,1),
    "up" => (0,-1)
)
final_pos = reduce(input, init = (0,0)) do last,instr
    last .+ ops[instr.cmd] .* instr.mag
end

#part 2
using LinearAlgebra

trav,depth = final_pos
trav*depth

ops2 = Dict(
    "forward" => X -> (
        [ 1 0 0 X  # traverse X units
          0 1 X 0  # add X*depth to aim
          0 0 1 0 ] # leave aim unchanged 
          :: Matrix{Int}
    ),
    "down" => X -> (
        [ 1 0 0 0  # leaves traverse unchanged
          0 1 0 0  # leaves depth unchanged
          0 0 1 X ] # increases aim by parameter
            :: Matrix{Int}
    ),
    "up" => X -> (
        [ 1 0 0 0  # leaves traverse unchanged
          0 1 0 0  # leaves depth by parameter
          0 0 1 -X ] # decreases aim by parameter
          :: Matrix{Int}
    )
)
(trav2,depth2,aim) = reduce(input, init = zeros(Int, 3)) do last,instr
    ops2[instr.cmd](instr.mag) * [ last ; 1 ]
end
trav2*depth2