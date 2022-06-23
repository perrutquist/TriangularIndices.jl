# TriangularIndices

This small package is intended to help with iterating over the indices of triangular matrices. For example:

```julia
using  TriangularIndices

z = zeros(Int, (3,3))
for (k, (i,j)) in enumerate(UpperTriangularIndices(z))
    z[i,j] = k
end
```
will result in 
```julia
z == [ 1  2  4
       0  3  5
       0  0  6]
```

Of course, the above `for`-loop could just as easily have been written
```julia
z = zeros(Int, (3,3))
k = 1
for j in 1:size(z,1)
    for i in 1:j
        z[i,j] = k
        k += 1
    end
end
```
which would not require the use of TriangularIndices.jl, and might even be faster for single-threaded code. However, `UpperTriangularIndices` objects support `length` as well as `getindex` slicing operations, which makes them
useful with macros that partition the iterator, such as `@distributed` from [Distributed](https://docs.julialang.org/en/v1/manual/distributed-computing/), `@threads` from [Threads](https://docs.julialang.org/en/v1/manual/multi-threading/), or `@floops` from [FLoops](https://github.com/JuliaFolds/FLoops.jl).

For reverse indexing, there is a fast specialization of `findfirst`
```julia
findfirst(==((3,3)), UpperTriangularIndices(10)) # returns 6
```

Note: There's currently no implementation of `LowerTriangularIndices`.
