begin
input = read("day10/input.txt", String)
input = split(input, "\n") |> Base.Fix1(map,String)
end


closing = Dict{Char, Char}(
    ')' => '(',
    ']' => '[',
    '}' => '{',
    '>' => '<'
)

scores = Dict{Char, Int}(
    ')' => 3,
    ']' => 57,
    '}' => 1197,
    '>' => 25137
)

function score_line(ln :: String)
    illegal = []
    Iterators.accumulate(ln, init=[]) do stack, cur
        if cur ∈ values(closing)
            push!(stack, cur)
            stack
        elseif length(stack) == 0
            push!(illegal, (:opening, cur))
            stack
        elseif last(stack) == closing[cur]
            pop!(stack)
            stack
        else
            push!(illegal, (last(stack),cur))
            stack
        end
    end |> collect
    try
        scores[Iterators.first(illegal)[2]]
    catch e
        if isa(e, BoundsError)
            0
        else
            rethrow()
        end
    end
end
map(score_line, input) |> sum


scores2 = Dict(
    '(' => 1,
    '[' => 2,
    '{' => 3,
    '<' => 4
)

function fix_line(ln :: String)
    illegal = []
    stack = (Iterators.accumulate(ln, init=[]) do stack, cur
        if cur ∈ values(closing)
            push!(stack, cur)
            stack
        elseif length(stack) == 0
            push!(illegal, (:opening, cur))
            stack
        elseif last(stack) == closing[cur]
            pop!(stack)
            stack
        else
            push!(illegal, (last(stack),cur))
            stack
        end
    end |> collect)[1]
    try
        Iterators.first(illegal)[2]
        0
    catch e
        if isa(e, BoundsError)
            reduce(reverse(stack), init = 0) do l,s
                l*5 + scores2[s]
            end
        else
            rethrow()
        end
    end
end
autocmp = map(input) do ln
    fix_line(ln)
end |> sort |> Base.Fix1(Iterators.dropwhile, (==)(0)) |> collect
autocmp = autocmp[cld(length(autocmp),2)]