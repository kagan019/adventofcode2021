begin
input = read("day17/input.txt", String)
pattern = r"target area: x=(-?[0-9]*)..(-?[0-9]*), y=(-?[0-9]*)..(-?[0-9]*)"
cap = match(pattern, input).captures
@assert nothing ∉ cap
@assert length(cap) == 4
targetX = (cap[1], cap[2]) .|> Base.Fix1(parse,Int)
targetX = min(targetX...), max(targetX...)
#flip horizontally so we only have to think about positive
# (or 0) x velocities
if abs(targetX[1]) > abs(targetX[2])
    targetX = (-targetX[2],-targetX[1])
end
# lob off negative side, why would I need that?
targetX = max(0,targetX[1]), targetX[2]
targetY = (cap[3], cap[4]) .|> Base.Fix1(parse,Int) 
targetY = min(targetY...), max(targetY...)
end

insideX(x :: Int) = targetX[1] <= x <= targetX[2] 
insideY(y :: Int) = targetY[1] <= y <= targetY[2]

function simulate(vel)
    Pos = []
    posi = (0,0)
    veli = vel |> deepcopy
    for i=1:26
        push!(Pos,posi)
        posi = posi .+ veli
        veli = (sign(veli[1]) * max(0,(abs(veli[1]) - 1)), veli[2] - 1)
    end
    Pos
end

simulate((6,9)) |> repr

# arithmetic series has self-similarity
# 0 + 1 + 2 + (3+0) + (3+1) + (3+2) ...
# this can be done ternary as above or binary, heptary, k-ary
# k*#steps - arith(#steps-1) = y position with inital y-velocity k after #steps
# arith(z) = 0 + 1 + 2 + .... + ((k+0) + (k+1) + (k+2) + ... + (z=k+n-1) = k*n + arith(n-1))
# k*n+arith(n-1) = arith(k+n-1)-arith(k-1)
# goal: find #steps required to put y position inside acceptable range
# 
# #steps is between 1 and initial xvel

arithcache = Dict(
    0 => 0
)

function arith(n :: Int)
    if n < 0
        return -arith(-n)
    end
    l = 1
    cursm = 1
    stepsz = 1
    while !haskey(arithcache,n)
        get!(arithcache,l,cursm)
        nxl = l + stepsz
        nxsm = cursm + (l+1)*stepsz + arith(stepsz-1)
        if nxl > n
            stepsz = fld(stepsz,2)
        else
            l = nxl
            cursm = nxsm
            stepsz *= 2
        end
    end
    get(arithcache,n,-1)
end


function find_arith_steps_equals(totsum :: Int)
    if totsum < 0
        return -find_arith_steps_equals(-totsum)
    end
    cursm = 1
    l = 1
    stepsz = 1
    while stepsz >= 1
        get!(arithcache,l,cursm)
        nxl = l + stepsz
        nxsm = cursm + (l+1)*stepsz + arith(stepsz-1)
        if nxsm == totsum
            return nxl
        elseif nxsm > totsum
            stepsz = fld(stepsz,2)
        else
            cursm = nxsm
            l = nxl
            stepsz *= 2
        end
    end
    return cursm == totsum ? l : -1
end


# 0, 0+1, 0+1+2, 0+1+2+3, ...
(s = [arith(i) for i=1:20]) |> repr
[find_arith_steps_equals(x) for x=s] |> repr

# find all valid #steps that put x in target area
# arith(initial xvel) = maximum x position for that velocity

can_collide(x :: Int, numst :: Int) = (x + arith(numst-1)) % numst == 0

begin
valid_xvels = Dict()
for tgtx=targetX[1]:targetX[2]
    xvels = Dict()
    for nmstps=1:tgtx
        init_xvel = (tgtx + arith(nmstps-1)) / nmstps
        if !isinteger(init_xvel)
            continue
        end
        init_xvel = Integer(init_xvel)
        if init_xvel < nmstps
            break
        end
        push!(get!(xvels,init_xvel,Set()),nmstps)
    end
    mergewith!(union,valid_xvels,xvels)
end
valid_xvels
end

function simy(init_yvel,steps)
    ypos = [0]
    v = init_yvel
    for i=1:steps
        push!(ypos,ypos[end]+v)
        v -= 1
    end
    ypos
end

#of those, find the ysteps that land in the target area
function maxy()
    my = -Inf
    for (xvel,stps)=valid_xvels|>collect
        for yv=targetY[1]:targetY[2]
            for stp=stps |> collect
                stationary = xvel == stp # due to drag
                if stationary 
                    for k=-stp*10:stp*10
                        s = simy(k,5000)
                        if yv in s
                            i = findfirst(s .== yv)
                            if !isnothing(i)
                                my = max(my, s[1:i]...)
                            end
                        end
                    end
                else
                    #must reach yv after exactly stp steps
                    yvel = (yv + arith(stp-1)) / stp
                    if isinteger(yvel)
                        my = max(my, begin
                            yp = simy(yvel,stp)
                            @assert yp[end] == yv
                            my = max(my,yp...)
                        end)
                    end
                end
            end
        end
    end
    my
end

exmp = begin
[
    (23,-10),  (25,-9 ),  (27,-5 ),  (29,-6 ),  (22,-6 ),  (21,-7 ), ( 9,0  ),   (27,-7 ),  (24,-5
),    (25,-7 ),  (26,-6 ),  (25,-5 ), ( 6,8  ),   (11,-2 ),  (20,-5 ),  (29,-10), ( 6,3  ),   (28,-7
),   ( 8,0  ),   (30,-6 ),  (29,-8 ),  (20,-10), ( 6,7  ),  ( 6,4  ),  ( 6,1  ),   (14,-4 ),  (21,-6
),    (26,-10), ( 7,-1 ),  ( 7,7  ),  ( 8,-1 ),   (21,-9 ), ( 6,2  ),   (20,-7 ),  (30,-10),  (14,-3
),    (20,-8 ),  (13,-2 ), ( 7,3  ),   (28,-8 ),  (29,-9 ),  (15,-3 ),  (22,-5 ),  (26,-8 ),  (25,-8
),    (25,-6 ),  (15,-4 ), ( 9,-2 ),   (15,-2 ),  (12,-2 ),  (28,-9 ),  (12,-3 ),  (24,-6 ),  (23,-7
),    (25,-10), ( 7,8  ),   (11,-3 ),  (26,-7 ), ( 7,1  ),   (23,-9 ), ( 6,0  ),   (22,-10),  (27,-6
),   ( 8,1  ),   (22,-8 ),  (13,-4 ), ( 7,6  ),   (28,-6 ),  (11,-4 ),  (12,-4 ),  (26,-9 ), ( 7,4
 ),   (24,-10),  (23,-8 ),  (30,-8 ), ( 7,0  ),  ( 9,-1 ),   (10,-1 ),  (26,-5 ),  (22,-9 ), ( 6,5
 ),  ( 7,5  ),   (23,-6 ),  (28,-10),  (10,-2 ),  (11,-1 ),  (20,-9 ),  (14,-2 ),  (29,-7 ),  (13,-3
),    (23,-5 ),  (24,-8 ),  (27,-9 ),  (30,-7 ),  (28,-5 ),  (21,-10), ( 7,9  ),  ( 6,6  ),   (21,-5
),    (27,-10), ( 7,2  ),   (30,-9 ),  (21,-8 ),  (22,-7 ),  (24,-9 ),  (20,-6 ), ( 6,9  ),   (29,-5
),   ( 8,-2 ),   (27,-8 ),  (30,-5 ),  (24,-7
)]
end |> Set

function countv()
    vels = Set()
    for (xvel,stps)=valid_xvels|>collect
        for yv=targetY[1]:targetY[2]
            for stp=stps |> collect
                stationary = xvel == stp # due to drag
                if stationary 
                    for k=-stp*100:stp*100
                        s = simy(k,5000)[stp+1:end] #at or beyond when the missile
                                                    #starts dropping down
                        if yv in s
                            push!(vels,(xvel,k))
                        end
                    end
                else
                    #must reach yv after exactly stp steps
                    yvel = (yv + arith(stp-1)) / stp
                    if isinteger(yvel)
                        push!(vels,(xvel,yvel))
                    end
                end
            end
        end
    end
    vels
end

countv() |> length
