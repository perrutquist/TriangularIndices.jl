[![Build status](https://github.com/perrutquist/TriangularIndices.jl/workflows/CI/badge.svg)](https://github.com/perrutquist/TriangularIndices.jl/actions)

# TriangularIndices.jl

This small package is intended to help with iterating over the indices of triangular matrices. For example:

```julia
using TriangularIndices

z = zeros(Int, (3,3))
for (k, (i,j)) in enumerate(UpperTriangularIndices(z))
    z[i,j] = k
end
```
will result in 
```julia
z == [ 1  2  4
       0  3  5
       0  0  6 ]
```

Of course, the above code could just as easily have been written
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
which would not require the use of TriangularIndices.jl, and which might even be faster for single-threaded code. However, `UpperTriangularIndices` objects support `length` as well as partitioning using `getindex`, which makes them
useful with macros that distribute the iterator over threads or processes, such as `@distributed` from [Distributed](https://docs.julialang.org/en/v1/manual/distributed-computing/), `@threads` from [Threads](https://docs.julialang.org/en/v1/manual/multi-threading/), or `@floop` from [FLoops](https://github.com/JuliaFolds/FLoops.jl).

For reverse indexing, there is a fast specialization of `findfirst`
```julia
findfirst(==((2,3)), UpperTriangularIndices(3)) # returns 5
```

Note: There's currently no corresponding implementation of `LowerTriangularIndices`. If somebody is interested in writing one, the linear-to-cartesian indexing operation could use [this code](https://discourse.julialang.org/t/iterating-over-elements-of-upper-triangular-matrix-but-cartesian-indices-are-needed/65498/3).
