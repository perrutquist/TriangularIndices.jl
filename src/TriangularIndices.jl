module TriangularIndices

using SplittablesBase

export UpperTriangularIndices

"""
`UpperTriangularIndices` - Indices of a triangular matrix.

`UpperTriangleIndices(n)` yields iterator of all the (row, column) indices of an upper triangular matrix of side-length `n`.
(For an upper triangular matrix, `n` only determines the length of the sequence. It is not used in computing indices.)

`UpperTriangleIndices(A)` where `A` is a square matrix yields an iterator fitting the size of `A`.

`UpperTriangleIndices()` returns an "infinite" set, which behaves as `UpperTriangleIndices(n)` for a sufficiently large `n`

Both iteration and `getindex` are supported, but indexing operations involve square roots, so are slightly slower than iteration.

Note: The implementation may change in future releases. Code that uses the fields of this struct directly is likely to break.
"""
struct UpperTriangularIndices
    start::Tuple{Int, Int}
    stop::Tuple{Int, Int}
end
# NOTE, because too (i,j) larger than typemax(Int32) will cause Int64 overflow in k, we could use Int32 for (i,j).

"""
AllUpperTriangularIndices is an iterator of all the UpperTriangularIndicies, starting at (1,1) and ending when there is integer overflow.
"""
struct AllUpperTriangularIndices end

function UpperTriangularIndices(n::Int) 
    Int===Int32 && n > 65535 && throw(ArgumentError("UpperTriangularIndices with a side-length longer than 65535 are currently not supported with 32bit Int."))
    n > 1073741823 && throw(ArgumentError("UpperTriangularIndices with a side-length longer than 1073741823 (2^30-1) are currently not supported."))
    UpperTriangularIndices((1,1), (n,n))
end

function UpperTriangularIndices(A::AbstractMatrix)
    Base.has_offset_axes(A) && error("Triangular indices for offset axes have not been implemented.")
    ==(size(A)...) || error("Triangular indices requires a square matrix.")
    UpperTriangularIndices(size(A,1))
end

UpperTriangularIndices() = AllUpperTriangularIndices()

const UTI = Union{UpperTriangularIndices, AllUpperTriangularIndices}

"""
The index of `(i,j)` in a sufficiently large `UpperTriangleIndices` iterator that starts from `(1,1)`.
"""
function triu_ij2k(i, j) 
    ((j*(j-1))>>1) + i
end
triu_ij2k(t::Tuple{Int, Int}) = triu_ij2k(t...)

# j*(j+1)+2 == 2k implies j == -1/2 ?? sqrt(8k - 7)/2
"""
The `k`:th `(i,j)` index of an upper triangular matrix.
"""
function triu_k2ij(k::Int)
    s = Int64(k)*8-7
    if k > 1125899906842623 # 2^50 - 1
        k > typemax(Int64)>>3 && throw(OverflowError("Index calculation resulted in integer overflow."))
        jm1 = Int((isqrt(s)-1)>>1)
    else
        jm1 = trunc(Int, 0.5*(sqrt(s)-1.0)) # faster than isqrt
    end
    (k-((jm1*(jm1+1))>>1), jm1+1)
end

"""
A slightly faster, but inexact, version of `triu_k2ij`.
"""
triu_k2ij_fast(k::Real) = triu_k2ij(k) # TODO

"""
The next `(i, j)` index of an upper triangular matrix.
If `i < j`, then `i` is incremented, otherwise `j` is incremented and `i` resets to one.
"""
@inline triu_next(i, j) = i < j ? (i + 1, j) : (1, j+1)
@inline triu_next(t::Tuple{Int, Int}) = triu_next(t...)

Base.first(x::UpperTriangularIndices) = x.start
Base.first(::AllUpperTriangularIndices) = (1,1)

Base.last(x::UpperTriangularIndices) = x.stop

function Base.findfirst(ij::Union{Base.Fix2{typeof(isequal),Tuple{Int,Int}},Base.Fix2{typeof(==),Tuple{Int,Int}}}, x::UpperTriangularIndices)
    (i,j) = ij.x
    0 < i ??? j || return nothing
    reverse(x.start) <= (j, i) <= reverse(x.stop) || return nothing
    triu_ij2k(i, j) - triu_ij2k(x.start) + 1
end

function Base.findfirst(ij::Union{Base.Fix2{typeof(isequal),Tuple{Int,Int}},Base.Fix2{typeof(==),Tuple{Int,Int}}}, ::AllUpperTriangularIndices)
    (i,j) = ij.x
    0 < i ??? j || return nothing
    triu_ij2k(i, j)
end

@inline function Base.iterate(x::UpperTriangularIndices, state=x.start)
    reverse(state) > reverse(x.stop) && return nothing
    (state, triu_next(state))
end

@inline function Base.iterate(::AllUpperTriangularIndices, state=(1,1))
    (state, triu_next(state))
end

Base.IteratorSize(::Type{UTI}) = Base.HasShape{1}()

Base.length(x::UpperTriangularIndices) = triu_ij2k(last(x)) - triu_ij2k(first(x)) + 1

Base.size(x::UpperTriangularIndices) = (length(x), )

Base.size(x::UpperTriangularIndices, dim) = dim == 1 ? length(x) : 1

Base.IteratorEltype(::Type{UTI}) = Base.HasEltype()

Base.eltype(::Type{UTI}) = Tuple{Int,Int}

Base.getindex(x::UpperTriangularIndices, k::Integer) = triu_k2ij(k - triu_ij2k(first(x)) + 1)

Base.getindex(::AllUpperTriangularIndices, k::Integer) = triu_k2ij(k)

function Base.getindex(x::UpperTriangularIndices, r::AbstractUnitRange{<:Integer})
    k0 = triu_ij2k(first(x)) - 1
    UpperTriangularIndices(triu_k2ij(first(r) + k0), triu_k2ij(last(r) + k0))
end

Base.getindex(::AllUpperTriangularIndices, r::AbstractUnitRange{<:Integer}) = UpperTriangularIndices(triu_k2ij(first(r)), triu_k2ij(last(r)))

Base.view(x::UTI, r::UnitRange{<:Integer}) = getindex(x, r)

Base.firstindex(x::UTI) = 1

Base.lastindex(x::UpperTriangularIndices) = length(x)

Base.keys(x::UpperTriangularIndices) = Base.OneTo(length(x))

function SplittablesBase.halve(x::UpperTriangularIndices)
    k_half = (triu_ij2k(first(x)) + triu_ij2k(last(x))) >> 1
    ij_half = triu_k2ij_fast(k_half)
    (UpperTriangularIndices(first(x), ij_half), UpperTriangularIndices(triu_next(ij_half), last(x)))
end

SplittablesBase.amount(x::UpperTriangularIndices) = length(x)

include("enumerated.jl")

end # module
