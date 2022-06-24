# Based on code from julia/base/iterators.jl (MIT license)

struct OffsetEnumerate{T}
    offset::Int
    itr::T
end

Base.length(e::OffsetEnumerate) = length(e.itr)

Base.size(e::OffsetEnumerate) = size(e.itr)

Base.eltype(::Type{OffsetEnumerate{I}}) where {I} = Tuple{Int, eltype(I)}

Base.IteratorSize(::Type{OffsetEnumerate{I}}) where {I} = Base.IteratorSize(I)

Base.IteratorEltype(::Type{OffsetEnumerate{I}}) where {I} = Base.IteratorEltype(I)

Base.@propagate_inbounds function Base.iterate(e::OffsetEnumerate, state=(1+e.offset,))
    i, rest = state[1], Base.tail(state)
    n = iterate(e.itr, rest...)
    n === nothing && return n
    (i, n[1]), (i+1, n[2])
end

# Needed for Threads.@threads, etc

Base.getindex(x::OffsetEnumerate, k::Integer) = (k + x.offset, getindex(x.itr, k))

Base.getindex(x::OffsetEnumerate, r::UnitRange{<:Integer}) = OffsetEnumerate(first(r)-1 + x.offset, getindex(x.itr, r))
   
Base.view(x::OffsetEnumerate, r::UnitRange{<:Integer}) = getindex(x, r)

Base.firstindex(x::OffsetEnumerate) = 1

Base.lastindex(x::OffsetEnumerate) = length(x)

Base.keys(x::OffsetEnumerate) = Base.OneTo(length(x))

# Interface to TriangularIndices

Base.enumerate(x::UpperTriangularIndices) = OffsetEnumerate(0, x)

# Interface to SplittablesBase

function SplittablesBase.halve(x::OffsetEnumerate)
    (left, right) = SplittablesBase.halve(x.itr)
    (OffsetEnumerate(x.offset, left), OffsetEnumerate(x.offset + length(left), right))
end

SplittablesBase.amount(x::OffsetEnumerate) = SplittablesBase.amount(x.itr)
