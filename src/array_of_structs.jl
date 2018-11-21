# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


abstract type AbstractArrayOfStructs end

#=
struct ArrayOfStructs{T,N,TPL<:NamedTuple}
    _entries::TPL

    ArrayOfStructs{T,N}(::Val{:unsafe}, entries::NamedTuple) where {T,N} =
        new{T,N,typeof(entries)}(entries)
end
=#


# TODO: Use `if @generated`?




#=
_create{T}


@inline _entries(A::ArraysOfStructs) = getfield(A, :_entries)


@inline Base.getproperty(A::ArraysOfStructs, p::Symbol) = getproperty(_entries(A), p)

@inline Base.propertynames(A::ArraysOfStructs) = propertynames(_entries(A))


@inline Base.size(A::ArraysOfStructs) = size(first(_entries(A)))

@inline Base.length(A::ArraysOfStructs) = length(first(_entries(A)))

@inline Base.IndexStyle(A::ArraysOfStructs{T,1}) = IndexLinear()


Base.@propagate_inbounds Base.getindex(A::ArraysOfStructs{T,N}, idxs::Real...) where {T,N} =
    map(getindex(x, idxs...), _entries(A))

Base.@propagate_inbounds function Base.getindex(A::ArraysOfStructs{T,N}, idxs::Any...) where {T,N}
    ArraysOfStructs(Val(:unsafe), map(getindex(x, idxs...), _entries(A)))


# Necessary?
# Base.@propagate_inbounds Base._getindex(l::IndexStyle, xs::DensitySampleVector, idxs::AbstractVector{<:Integer})


# Base.setindex


@inline Base.unsafe_view(A::ArraysOfStructs{T,N}, idxs...) where {T,N}
    ArraysOfStructs{T,N}(Val(:unsafe), map(x -> view(x, idxs...), _entries(A)))


# @inline Base.map(f, A::ArraysOfStructs) = map(f, _entries(A))


# @inline Base.keys(A::ArraysOfStructs) = keys(_entries(A))

# @inline Base.values(A::ArraysOfStructs) = values(_entries(A))


@inline Table.columns(A::ArraysOfStructs{T,1}) where T = _entries(A)


function Base.push!(A::ArraysOfStructs{T,N}, x::T) where {T,N}
    push!(xs.params, x.params)
    push!(xs.log_posterior, x.log_posterior)
    push!(xs.log_prior, x.log_prior)
    push!(xs.weight, x.weight)
    xs
end

=#


#=

function Base.append!(A::ArraysOfStructs{T,N}, x::T) where {T,N}
    append!(A.params, B.params)
    ...
    A
end


function Base.resize!(A::ArraysOfStructs{T,N}, n::Integer)
    resize!(A.params, n)
    ...
    A
end


function UnsafeArrays.uview(A::ArraysOfStructs{T,N})
    ArraysOfStructs{T,N}(Val(unsafe), map(uview, _entries(A)))
end

=#
