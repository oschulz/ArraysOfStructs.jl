# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


abstract type AbstractArrayOfStructs{T,N} <: AbstractArray{T,N} end
export AbstractArrayOfStructs


const SOAColumn{N} = AbstractArray{T,N} where T
const SOACols{N,ncols,colnames} = NamedTuple{colnames,<:NTuple{ncols,SOAColumn{N}}} where {N,ncols,colnames}


struct ArrayOfStructs{T,N,P<:SOACols{N}} <: AbstractArrayOfStructs{T,N}
    _entries::P

    ArrayOfStructs{T,N,P}(::Val{:unsafe}, entries::P) where {T,N,P<:SOACols{N}} = new{T,N,P}(entries)
end

export ArrayOfStructs

ArrayOfStructs{T,N}(entries::Any) where {T,N} = soa_repr(Val{(N,)}(), T, entries)


const VectorOfStructs{T,P<:SOACols{1}} = ArrayOfStructs{T,1,P}
export VectorOfStructs



# Need: Array{ArrayOfStructs}

struct NestedArrayOfStructs{T<:AbstractArrayOfStructs,N} <: AbstractArrayOfStructs{T,N}
    _inner::T
end







Base.@pure function nested_array_type(::Type{T}, outer::Val{dims}) where {T,dims}
    _nested_array_type_impl(T, dims...)
end

Base.@pure _nested_array_type_impl(::Type{T}) where {T} = T

Base.@pure _nested_array_type_impl(::Type{T}, N) where {T} = AbstractArray{T, N}

Base.@pure _nested_array_type_impl(::Type{T}, N, M, dims...) where {T} =
    AbstractArray{<:_nested_array_type_impl(T, M, dims...), N}


@inline soa_repr(dims::Val, ::Type{T}, x::AbstractArray{U,N}) where {T,N,U} =
    _soa_repr_leaf(nested_array_type(T, dims), x)

@inline soa_repr(::Val{dims}, ::Type{<:AbstractArray{T,N}}, x::NamedTuple{syms}) where {dims,T,N,syms} =
    soa_repr(Val{(dims...,N)}(), T, x)

# Not implemented yet:
# soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T<:StaticArray,N,syms}

@inline soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T<:FieldVector,N,syms} =
    _soa_repr_struct(Val{dims}(), T, x)

@inline soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T,N,syms} =
    _soa_repr_struct(Val{dims}(), T, x)


_soa_repr_leaf(::Type{T}, x::T) where {T} = x
_soa_repr_leaf(::Type{T}, x::U) where {T,U} = convert(T, x)


function _soa_repr_struct(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T,syms}
    nfields_T = fieldcount(T)
    nfields_N = length(syms)
    nfields_T == nfields_N || throw(ArgumentError("Type $T has $nfields_T fields, can't represent by NamedTuple with $nfields_N fields"))
    cols = map(Base.OneTo(nfields_T)) do i
        sym_T = fieldname(T,i)
        sym_N = syms[i]
        sym_T == sym_N || throw(ArgumentError("Expected field $sym_T in named tuple but got sym_N"))
        U = fieldtype(T, i)
        value = getfield(x, i)
        soa_repr(Val{dims}(), U, value)
    end
    colsnt = NamedTuple{syms}(cols)
    ArrayOfStructs{T,first(dims),typeof(colsnt)}(Val(:unsafe), colsnt);
end



@inline _getentries(A::ArrayOfStructs) = getfield(A, :_entries)
@inline _getcolvalues(A::ArrayOfStructs) = values(_getentries(A))
@inline _getfirstcol(A::ArrayOfStructs) = _getentries(A)[1]

@inline Base.getproperty(A::ArrayOfStructs, sym::Symbol) = getproperty(_getentries(A), sym)
@inline Base.propertynames(A::ArrayOfStructs) = propertynames(_getentries(A))

@inline Base.size(A::ArrayOfStructs) = size(_getfirstcol(A))

Base.@propagate_inbounds function Base.getindex(A::ArrayOfStructs{T,N}, i::Real) where {T,N}
    #!!!T(map(col -> getindex(col, i), _getcolvalues(A))...)
    map(col -> getindex(col, i), _getcolvalues(A))
end



#=


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
