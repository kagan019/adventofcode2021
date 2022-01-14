begin
input = read("day17/sample.txt", String)
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

#of those, find the ysteps that land in the target area
begin
maxyvel = -Inf
for (xvel,stps)=valid_xvels|>collect
    for yv=targetY[1]:targetY[2]
        for stp=stps |> collect
            stationary = xvel == stp # due to drag
            if stationary 
                #find the maximum and solve there
            else
                #must reach yv after exactly stp steps
                yvel = (yv + arith(stp-1)) / stp
                if isinteger(yvel)
                    maxyvel = max(maxyvel,yv)
                end
            end
        end
    end
end
maxyvel
end