# Hydrothermal Venture
module day05

part = :parttwo
input = cd("day05/data") do 
    read("input.txt", String)
end

struct Line
    x1 :: Int
    y1 :: Int
    x2 :: Int
    y2 :: Int
end
vertical(l :: Line) = l.y1 == l.y2
horizontal(l :: Line) = l.x1 == l.x2
diagonal(l :: Line) = abs(l.y1-l.y2)/abs(l.x1-l.x2) == 1.0

input_lines = map(split(input,"\n")) do t
    x1y1,x2y2 = map(split(t," -> ")) do v
        map(split(v,",")) do i
            parse(Int, i)
        end
    end
    x1,y1 = x1y1
    x2,y2 = x2y2
    Line(x1,y1,x2,y2)
end
onlyvh = filter(input_lines) do l
    horizontal(l) || vertical(l)
end
onlyvhd = filter(input_lines) do l
    horizontal(l) || vertical(l) || diagonal(l)
end

gcd(x,y) = begin
    x_,y_ = abs(x), abs(y)
    if y_ == 0
        x_
    else
        gcd(y_,x_ % y_)
    end
end
red(x,y) = begin
    g = gcd(x,y)
    (Int(x/g),Int(y/g))
end
between(p,l) = begin
    xin = min(l.x1,l.x2) <= p[1] <= max(l.x1,l.x2)
    yin = min(l.y1,l.y2) <= p[2] <= max(l.y1,l.y2)
    xin && yin
end
counts_of_points = map(
    (part == :partone) ? onlyvh : onlyvhd 
) do l
    dx,dy = red(l.x2-l.x1,l.y2-l.y1)
    all_points_on_line = Iterators.takewhile(
        p->between(p,l),
        Iterators.accumulate(
            (.+),
            [[(l.x1,l.y1)], Iterators.repeated((dx,dy))] |>
                Iterators.flatten
        )
    ) |> collect
    reduce(all_points_on_line; init=Dict()) do dict,p
        get!(dict,p,0)
        dict[p] += 1
        dict
    end
end |> Base.Fix1(reduce, mergewith(+))

filter(counts_of_points) do k
    k[2] >= 2
end |> keys |> length

function showgrid()
    for i=0:9
        for j=0:9
            ch = get(counts_of_points, (j,i), 0)
            ch = (ch > 0) ? string(ch) : "."
            print(ch)
        end
        print("\n")
    end
end


end # module