part = :winfirst
input = cd("day04") do 
    read("sample.txt",String)
end |> x->split(x,",") 
begin
    callednums, boards = (vcat(input[begin:end-1], input[end][1]),input[end][4:end])
    callednums = map(callednums) do num
        parse(Int,num)
    end
    boards = Iterators.filter((>)(0) ∘ length, split(boards, "\n")) 
    collect(boards) :: Vector{SubString{String}}
    boards = Iterators.map(boards) do str
        map(Iterators.partition(str,3)) do chars
            [parse(Int,String(chars))]
        end |> Base.Fix1(foldl, hcat)
    end
    boards = map(Iterators.partition(boards,5)) do grp
        foldl(vcat,grp)
    end
end 
boards :: Vector{Matrix{Int}}

abstract type AbstractBingoCellLocation end
struct BingoCellLocation <: AbstractBingoCellLocation
    # There are better impls, but thisll be the implementation that
    # just searches for the number called in the Matrix
    boardidx :: Int
    coord :: CartesianIndex{2}
end


function board_of(b :: BingoCellLocation) :: Matrix{Int}
    boards[b.boardidx]
end

function cooresponding_cell(b :: BingoCellLocation) :: Int
    board_of(b)[b.coord]
end

function has_bingo(mark :: Matrix{Bool})
    has_vertical = mapslices(mark, dims=[1]) do vslice
        reduce((&), vslice)
    end |> Base.Fix1(reduce, (|))
    has_horiz = mapslices(mark, dims=[2]) do hslice
        reduce((&), hslice)
    end |> Base.Fix1(reduce, (|))
    has_vertical || has_horiz
end 

function find_first_bingo(marks :: Vector{Matrix{Bool}}) :: Union{Int,Symbol}
    try
        Iterators.dropwhile(enumerate(map(has_bingo,marks))) do (i,h)
            !h
        end |> first |> x->x[1]
    catch y
        if isa(y,ArgumentError)
            :nobingo
        end
    end
end

function find_last_bingo(marks :: Vector{Matrix{Bool}}) :: Int
    stack_of_winners = Iterators.reduce(enumerate(map(has_bingo,marks)), init=(Set(),Vector{Int}())) do (s,v), (i,h)
        s :: Set; v :: Vector{Int}
        if h && i ∉ s 
            push!(last,i)
            push!(v, i)
        end
    end
    all_done_stack = Iterators.dropwhile(stack_of_winners) do s,v
        length(v) < length(boards)
    end
    try
        first(all_done_stack) |> x->last(x[1])
    catch z
        if isa(z, ArgumentError)
            stack_of_winners |> collect |> last |> x->last(x[1])
        end
    end
end

begin
    begin
        marks = similar(boards, Matrix{Bool})
        foreach(eachindex(marks)) do boardi
            marks[boardi] = similar(boards[1], Bool)
            foreach(eachindex(marks[boardi])) do i
                marks[boardi][i]=false
            end
        end
        marks
    end

    begin
        locations = Dict{Int, Vector{BingoCellLocation}}()
        # where Int is a number that might be called next
        foreach(enumerate(boards)) do (i,board)
            foreach(CartesianIndices(board)) do coord
                coord :: CartesianIndex{2}
                n = board[coord]
                if !haskey(locations,n)
                    locations[n] = Vector{BingoCellLocation}[]
                end
                push!(locations[n], BingoCellLocation(i,coord))
            end
        end
    end

    call_num(called :: Int) = begin
        global marks
        for loc=locations[called]
            marks[loc.boardidx][loc.coord] = true
        end
    end

    bingo_rounds = Iterators.map(callednums) do n
        call_num(n)
        map(has_bingo, marks)
    end
    
end

first_bingo = Iterators.dropwhile(x -> true ∉ x, bingo_rounds) |> first
    findall((==)(true), first_bingo)[0]
bingo_call = callednums[callidx]
bingo_board = boards[bingo_board_idx]
mark_board = marks[bingo_board_idx]

begin
    score = bingo_board[.~mark_board] |> sum
    score = score * bingo_call
end
