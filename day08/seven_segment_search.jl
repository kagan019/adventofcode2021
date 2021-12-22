# I give each segment a universal name
#  1111   
# 2    3  
# 2    3 
#  4444   
# 5    6 
# 5    6  
#  7777   

# 0:      1:      2:      3:      4:
#  aaaa    ....    aaaa    aaaa    ....
# b    c  .    c  .    c  .    c  b    c
# b    c  .    c  .    c  .    c  b    c
#  ....    ....    dddd    dddd    dddd
# e    f  .    f  e    .  .    f  .    f
# e    f  .    f  e    .  .    f  .    f
#  gggg    ....    gggg    gggg    ....

#  5:      6:      7:      8:      9:
#  aaaa    aaaa    aaaa    aaaa    aaaa
# b    .  b    .  .    c  b    c  b    c
# b    .  b    .  .    c  b    c  b    c
#  dddd    dddd    ....    dddd    dddd
# .    f  e    f  .    f  e    f  .    f
# .    f  e    f  .    f  e    f  .    f
#  gggg    gggg    ....    gggg    gggg

segments_of_digit = Dict(
    0 => [1,2,3,5,6,7],
    1 => [3,6],
    2 => [1,3,4,5,7],
    3 => [1,3,4,6,7],
    4 => [2,3,4,6],
    5 => [1,2,4,6,7],
    6 => [1,2,4,5,6,7],
    7 => [1,3,6],
    8 => [1,2,3,4,5,6,7],
    9 => [1,2,3,4,6,7]
)

begin
digits_of_segcount = Dict{Int,Vector{Int}}()
foreach(keys(segments_of_digit)) do d
    segs = segments_of_digit[d]
    r = get!(digits_of_segcount, length(segs), Int[])
    push!(r, d)
end
digits_of_segcount
end

begin
one_length_digits = [d for (d,cfg)=pairs(digits_of_segcount) if length(cfg) == 1]
end

parserow(ln) = begin
    signal_patterns, output_digits = split(ln, " | ")
    signal_patterns = split(signal_patterns, " ") |> Base.Fix1(map, String)
    output_digits = split(output_digits, " ") |> Base.Fix1(map, String)
    (signal_patterns,output_digits)
end

begin
input = read("day08/input.txt", String)
input = split(input, "\n")
input = map(parserow, input)
end

#part 1
begin
trivially_crackable = map(input) do k
    signal_patterns, output_values = k
    map(output_values) do ov
        length(ov) ∈ unique_segcounts
    end |> sum
end |> sum
end

#part 2
function decode_output(signal_patterns :: Vector{String}, output_digits :: Vector{String})
    begin
    seg_poss_by_char = Dict{Char, Set{Int}}() #char to what segments?
    foreach('a':'g') do c
        seg_poss_by_char[c] = Set(1:7)
    end
    map([signal_patterns ; output_digits]) do pat
        poss_digits = digits_of_segcount[length(pat)]
        poss_segs = union(map(poss_digits) do dig
            segments_of_digit[dig]  
        end...)
        foreach(pat) do c :: Char
            # each character can only be one of the segments in any digit
            # with a number of segments equal to length(pat)
            # poss_segs is all such segments
            intersect!(seg_poss_by_char[c], poss_segs)  
        end
    end
    seg_poss_by_char
    end

    #and now the other direction, to impose bidirectional uniqueness
    begin
    char_poss_by_seg = Dict{Int, Set{Char}}() #segment to what chars?
    foreach(1:7) do seg
        char_poss_by_seg[seg] = Set([key for (key,vals)=pairs(seg_poss_by_char) if seg ∈ vals])
    end
    map([signal_patterns ; output_digits]) do pat
        poss_digits = digits_of_segcount[length(pat)]
        poss_segs = intersect(map(poss_digits) do dig
            segments_of_digit[dig]  
        end...)
        foreach(poss_segs) do seg :: Int
            # the common segments of all digit possibilities must be some character
            # in the pattern
            intersect!(char_poss_by_seg[seg], pat)  
        end
    end
    char_poss_by_seg
    end

    # assume char_pos_by_seg deduces an exact wire/segment connection
    begin
    decoded_segment = Dict{Char,Int}()
    ezkeys = [key for (key,v)=pairs(char_poss_by_seg) if length(v) == 1]
    hardkeys = [key for (key,v)=pairs(char_poss_by_seg) if length(v) > 1]
    foreach([ezkeys,hardkeys]) do ks
        foreach(ks) do seg
            foreach(char_poss_by_seg[seg]) do ch
                get!(decoded_segment,ch,seg)
            end
        end
    end
    @assert length(decoded_segment) == length(Set(values(decoded_segment))) ==
        length(char_poss_by_seg) == length(seg_poss_by_char) # means solved
    decoded_segment
    end 

    # turn letters into decoded numbers
    bitify_segment(list :: Vector{Int}) = reduce(list, init=0) do last,cur
        last | (1 << cur)
    end
    digits_by_segment_config = Dict(map(pairs(segments_of_digit) |> collect) do (k,v)
        bitify_segment(v) => k
    end) :: Dict{Int,Int}
    decode_signal(word :: String) = digits_by_segment_config[
        bitify_segment(map(word |> collect) do ch
            decoded_segment[ch] :: Int
        end)
    ]
    int_from_digits(list :: Vector{Int}) = reduce(list, init=0) do last,cur
        last * 10 + cur
    end
    int_from_digits(map(decode_signal,output_digits))
end

sample() = begin
    ln = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf"
    parserow(ln) |> Base.splat(decode_output)
end
sample()

map(Base.splat(decode_output), input) |> sum
