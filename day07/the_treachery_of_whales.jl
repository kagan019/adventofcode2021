begin
    input = cd("day07") do
        split(read("input.txt", String), ",")
    end
    input = map(input) do i
        parse(Int,i)
    end
end

#accumulate sum from left, and right, and zip
#move linearly from left to right, adding the zipped accumulates

begin
    pos = Vector{Int}(undef, 1+max(input...))
    pos = map(pos) do _; 0 end
    pos = foldl(input, init=pos) do vec, v
        vec[v+1] += 1
        vec
    end
end

#pos = [c0, c1, c2, ...]
pos |> repr
# sum from left up to excluding cur plus sum from right down to excluding cur
lsum = [0 ; accumulate(+, pos[begin:end-1])] 
rsum = reverse([0 ; accumulate(+,pos[end:-1:begin+1])])
rsum |> repr
# lsum = [0, c0, c0+c1, c0+c1+c2, c0+c1+c2+c3, ...]
# rsum = [..., c0'+c1'+c2'+c3', c0'+c1'+c2', c0'+c1', c0', 0] where x' = N-x

lcosts = accumulate(+, lsum)
rcosts = reverse(accumulate(+,reverse(rsum)))
lcosts |> repr
rcosts |> repr
# lsum = [0, c0, 2c0+c1, 3c0+2c1+c2, 4c0+3c1+2c2+1c3, ...]
# rsum = [..., 4c0'+3c1'+2c2'+c3', 3c0'+2c1'+c2', 2c0'+c1', c0', 0] 

fuelreq = map(Base.splat(+), zip(lcosts,rcosts))
min(fuelreq...)

#part 2

lexp = accumulate(+,lcosts)
rexp = reverse(accumulate(+,reverse(rcosts)))

crabeng = map(Base.splat(+), zip(lexp,rexp))
min(crabeng...)