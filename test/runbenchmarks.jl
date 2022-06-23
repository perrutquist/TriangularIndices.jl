using Distributed
addprocs(3)

@everywhere push!(LOAD_PATH, splitdir(@__DIR__)[1])
@everywhere using TriangularIndices

using FLoops
using BenchmarkTools

function s1(n)
    s = 0.0
    for j = 1:n
        for i = 1:j
            s += i/j
        end
    end
    s
end

function s2(n)
    s = 0.0
    for (i,j) = UpperTriangularIndices(n)
        s += i/j
    end
    s
end

function s3(n)
    s = 0.0
    FLoops.@floop for (i,j) = UpperTriangularIndices(n)
        @reduce s += i/j
    end
    s
end

function s4(n)
    @distributed (+) for (i,j) = UpperTriangularIndices(n)
        i/j
    end
end

@assert s1(1000) ≈ s2(1000) 
@assert s2(1000) ≈ s3(1000)
@assert s3(1000) ≈ s4(1000)

@btime s1(1000)
@btime s2(1000)
@btime s3(1000)
@btime s4(1000)

function t1!(A)
    @assert size(A,1) == size(A,2)
    k = 1
    for j = 1:size(A,1)
        for i = 1:j
            @inbounds A[i,j] = k
            k += 1
        end
    end
    A
end

function t2!(A)
    @assert size(A,1) == size(A,2)
    for (k, (i,j)) in enumerate(UpperTriangularIndices(size(A,1)))
        @inbounds A[i,j] = k
    end
    A
end

function t3!(A)
    @assert size(A,1) == size(A,2)
    @floop for (k, (i,j)) in enumerate(UpperTriangularIndices(size(A,1)))
        @inbounds A[i,j] = k
    end
    A
end

function t4!(A)
    @assert size(A,1) == size(A,2)
    Threads.@threads for (i,j) in UpperTriangularIndices(size(A,1))
        @inbounds A[i,j] = findfirst(==((i,j)), UpperTriangularIndices(size(A,1)))
    end
    A
end

A = zeros(Int, 1000, 1000)

@btime t1!($A)
@btime t2!($A)
@btime t3!($A)
@btime t4!($A)

nothing
