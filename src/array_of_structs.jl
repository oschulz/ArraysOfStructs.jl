# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


abstract type AbstractArrayOfStructs{T,N} <: AbstractArray{T,N} end
export AbstractArrayOfStructs


const SOAColumn{N} = AbstractArray{T,N} where T
const SOACols{N,ncols,colnames} = NamedTuple{colnames,<:NTuple{ncols,SOAColumn{N}}} where {N,ncols,colnames}



struct ArrayOfStructs{T,N,VI<:Tuple,P<:SOACols} <: AbstractArrayOfStructs{T,N}
    _entries::P
    _outeridxs::VI
end

export ArrayOfStructs


ArrayOfStructs{T,N}(::Val{:unsafe}, entries::P, outeridxs::VI = ()) where {T,N,VI<:Tuple,P<:SOACols} = begin
    #@info T, outeridxs 

    ArrayOfStructs{T,N,VI,P}(entries, outeridxs)
end


ArrayOfStructs{T,N}(entries::Any) where {T,N} = soa_repr(Val{(N,)}(), T, entries)


const VectorOfStructs{T} = ArrayOfStructs{T,1}
export VectorOfStructs



struct NestedArrayOfStructs{T<:AbstractArrayOfStructs,N,VI<:Tuple,P<:SOACols} <: AbstractArrayOfStructs{T,N}
    _entries::P
    _outeridxs::VI

    NestedArrayOfStructs{T,N}(::Val{:unsafe}, entries::P, outeridxs::VI = ()) where {T<:AbstractArrayOfStructs,N,VI<:Tuple,P<:SOACols} =
        new{T,N,VI,P}(entries, outeridxs)
end



const MaybeNestedArrayOfStructs{T,N} = Union{ArrayOfStructs{T,N}, NestedArrayOfStructs{T,N}}



@inline soa_repr(dims::Val, ::Type{T}, x::AbstractArray{U,N}) where {T,N,U} =
    _soa_repr_leaf(abstract_nestedarray_type(T, dims), x)

_soa_repr_leaf(::Type{T}, x::T) where {T} = x
_soa_repr_leaf(::Type{T}, x::U) where {T,U} = convert(T, x)

@inline function soa_repr(::Val{dims}, ::Type{<:AbstractArray{T,N}}, x::NamedTuple{syms}) where {dims,T,N,syms}
    repr = soa_repr(Val{(dims...,N)}(), T, x)
    @assert repr isa AbstractArrayOfStructs
    AT = typeof(repr)
    entries = _getentries(repr)
    NestedArrayOfStructs{AT,N}(Val{:unsafe}(), entries)
end

# TODO: Not implemented yet:
# soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T<:StaticArray,N,syms}

@inline soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T<:FieldVector,N,syms} =
    _soa_repr_struct(Val{dims}(), T, x)

@inline soa_repr(::Val{dims}, ::Type{T}, x::NamedTuple{syms}) where {dims,T,N,syms} =
    _soa_repr_struct(Val{dims}(), T, x)

#Base.@pure xyz2(::Val{dims}) where {dims} = ntuple(i -> NTuple{dims[1],Int}, Val(length(dims)))
#Base.@pure outeridxs_type(::Val{dims}) where {dims} = NTuple{sum(dims),Int}
Base.@pure dummy_outeridxs(::Val{dims}) where {dims} = ntuple(i -> 1, Val{sum(dims) - 1}())

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
    outeridxs = dummy_outeridxs(Val{dims}())
    ArrayOfStructs{T,first(dims)}(Val{:unsafe}(), colsnt, outeridxs);
end


@inline _canonical_idxs(shape::NTuple{1,Integer}, idx) = (idx,)
@inline _canonical_idxs(shape::NTuple{N,Integer}, idx) where {N} = Tuple(CartesianIndices(shape)[idx])
@inline _canonical_idxs(shape::NTuple{N,Integer}, idxs...) where {N} = ntuple(i -> idxs[i], Val{N}())


@inline _getentries(A::ArrayOfStructs) = getfield(A, :_entries)
@inline _getentries(A::NestedArrayOfStructs) = getfield(A, :_entries)

@inline _getouteridxs(A::ArrayOfStructs) = getfield(A, :_outeridxs)
@inline _getouteridxs(A::NestedArrayOfStructs) = getfield(A, :_outeridxs)

@inline _getcolvalues(A::MaybeNestedArrayOfStructs) = values(_getentries(A))

@inline _getfirstcol(A::MaybeNestedArrayOfStructs) = _getentries(A)[1]

@inline Base.getproperty(A::MaybeNestedArrayOfStructs, sym::Symbol) = getproperty(_getentries(A), sym)
@inline Base.propertynames(A::MaybeNestedArrayOfStructs) = propertynames(_getentries(A))

@inline Base.size(A::MaybeNestedArrayOfStructs) = size(_getfirstcol(A))

Base.@propagate_inbounds function Base.getindex(A::ArrayOfStructs{T,N}, idxs...) where {T,N}
    Base.@boundscheck checkbounds(A, idxs...)
    canon_idxs = _canonical_idxs(size(A), idxs...)
    # T(map(col -> getindex(col, idxs...), _getcolvalues(A))...)

    #@info "simple getindex" T _getouteridxs(A) idxs canon_idxs
    #T(map(col -> deepgetindex(col, _getouteridxs(A)..., canon_idxs...), _getcolvalues(A))...)
    map(col -> deepgetindex(col, _getouteridxs(A)..., canon_idxs...), _getcolvalues(A))
end


Base.@propagate_inbounds function Base.getindex(A::NestedArrayOfStructs{T,N}, idxs::Integer) where {T,N}
    #@info "nested getindex" T _getouteridxs(A) idxs
    Base.@boundscheck checkbounds(A, idxs...)
    canon_idxs = _canonical_idxs(size(A), idxs...)
    T(_getentries(A), (_getouteridxs(A)..., canon_idxs...))
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
