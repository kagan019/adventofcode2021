bins = map(split(
    cd("day03") do; read("input.txt",String) end
    , "\n"
)) do ln
    [ parse(Bool,elem) for elem=split(ln, "") ]
end |> collect 
bins :: Vector{Vector{Bool}}
ones_count_by_digit = mapslices(sum, bins; dims=[1])
gamma_list = [ length(bins) - tot1s <= tot1s for tot1s=ones_count_by_digit ]   
eps_list = [ length(bins) - tot1s > tot1s for tot1s=ones_count_by_digit ]  
int_from_bitlist(lst :: Vector{Bool}) = begin
    reduce(lst) do lastBits, nextBit
        Int(lastBits) << 1 | nextBit
    end :: Int
end
gamma,epsilon = map(int_from_bitlist,[gamma_list,eps_list])
gamma*epsilon

# part 2
most_common_bit_in_pos(rem :: Vector{Vector{Bool}}, i::Int) = begin
    # tiebreaker 1
    tot1s = sum(map(v->v[i],rem))
    tot0s = length(rem) - tot1s
    tot1s >= tot0s
end
least_common_bit_in_pos(rem,i) = !most_common_bit_in_pos(rem,i)

rating(select_bit_to_match) = begin
    nbits = bins[1] |> length
    bit_criteria = map(1:nbits) do bit_position
        rem -> begin
            bit_to_match = select_bit_to_match(rem,bit_position)
            v -> bit_to_match == v[bit_position]
        end
    end
    candidates = accumulate(bit_criteria,init=bins) do last,crit
        c = crit(last)
        filter(c,last)
    end

    Iterators.dropwhile((>)(1) ∘ length, candidates) |> first |> only
end

O2_rating = rating(most_common_bit_in_pos) |> int_from_bitlist
CO2_rating = rating(least_common_bit_in_pos) |> int_from_bitlist
O2_rating * CO2_rating