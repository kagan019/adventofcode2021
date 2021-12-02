using Base.Iterators

input = map(cd("day01") do 
    split(read("input.txt", String),"\n")
end) do s; parse(Int,s) end 

sonar_test(lst) =
    map(firstindex(lst)+1:lastindex(lst)) do i; lst[i] > lst[i-1] end
is_inc = sonar_test(input)
print("\npart 1: ",sum(is_inc))

# part 2

windows = (itr for itr=map(enumerate(input)) do (i,el)
    take(rest(input,i),3)
end if length(collect(itr)) == 3)
is_inc2 = sonar_test(map(sum,windows))
print("\npart 2: ", sum(is_inc2))
