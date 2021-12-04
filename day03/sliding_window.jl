function sliding_window(itr, N)
    # each continugous window of size exactly N, which is only generated when you iterate to it
    cdr = cur -> begin
        el,rem = try peel(cur) catch; (nothing,nothing) end
        rem
    end
    successors = takewhile(
        (!) ∘ isnothing, 
        Iterators.accumulate(repeated(itr)) do last, _
            cdr(last)
        end
    )
    filter(map(successors) do rst
        collect(take(rst,N))
    end) do window
        length(window) == N
    end
end

@timev mywindow = sliding_window(['a','b','c','d','e','f','g'],3)
@timev collect(mywindow)
