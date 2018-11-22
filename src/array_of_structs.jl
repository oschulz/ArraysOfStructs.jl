# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


Base.@pure soarepr_category(::Type{<:AbstractArray}) = Val{:array}()
Base.@pure soarepr_category(::Type{<:Tuple}) = Val{:tuple}()
Base.@pure soarepr_category(::Type{<:StaticArray}) = Val{:tuple}()
Base.@pure soarepr_category(::Type{<:FieldVector}) = Val{:struct}()
Base.@pure soarepr_category(::Type{T}) where T = Val{isstructtype(T) ? :struct : :primitive}()



soa_coltype(X::Type{<:AbstractArray{T,N}}) where {T,N} = begin
    @info "soa_coltype($X)"
    soa_coltype_impl(soarepr_category(T), T, Val{N}())
end


soa_coltype_impl(::Val{:array}, ::Type{<:AbstractArray{T,N}}, outerdims::Val...) where {T,N} = begin
    @info "soa_coltype_impl(::Val{:array}, <:AbstractArray{$T,$N}, $outerdims)"
    soa_coltype_impl(soarepr_category(T), T, Val{N}(), outerdims...)
end


soa_coltype_impl(::Val{:primitive}, ::Type{T}) where {T} = begin
    @info "soa_coltype_impl(::Val{:primitive}, $T)"
    T
end

soa_coltype_impl(::Val{:primitive}, ::Type{T}, ::Val{N}, outerdims::Val...) where {T,N} = begin
    @info "soa_coltype_impl(::Val{:primitive}, $T, Val{$N}(), $outerdims)"
    AbstractArray{<:soa_coltype_impl(Val{:primitive}(), T, outerdims...),N}
end

function soa_coltype_impl(::Val{:struct}, ::Type{T}, outerdims::Val...) where {T}
    @info "soa_coltype_impl(::Val{:struct}, $T, $outerdims)"
    syms = fieldnames(T)
    types = ntuple(Val(fieldcount(T))) do i
        U = fieldtype(T, i)
        C = soarepr_category(U)
        @info "    field $(fieldname(T, i)) has type $U and category $C"
        soa_coltype_impl(soarepr_category(U), U, outerdims...)
    end
    NamedTuple{syms,Tuple{types...}}
end




#=
Base.@pure soa_fieldtypes(T::Type{<:AbstractArray{U,N}}) where {U,N} = throw(ArgumentError("Can't determine SOA fieldtypes for non-static arrays"))

Base.@pure soa_fieldtypes(T::Type{<:StaticArray{N,U}}) where {U,N} = throw(ArgumentError("Can't determine SOA fieldtypes for static arrays"))

Base.@pure soa_fieldtypes(::Type{T}) where {T<:FieldVector} = _de_struct_type_impl(T)

Base.@pure soa_fieldtypes(::Type{T}) where {T} = _de_struct_type_impl(T)

Base.@pure function _de_struct_type_impl(::Type{T}) where {T}
    if @generated
        if isstructtype(T)
            syms = :(())
            types = :(Tuple{})
            for i in Base.OneTo(fieldcount(T))
                push!(syms.args, QuoteNode(fieldname(T, i)))
                push!(types.args, soa_fieldtypes(fieldtype(T, i)))
            end
            :(NamedTuple{$syms,$types})
        else
            :T
        end
    else
        if isstructtype(T)
            syms = fieldnames(T)
            types = ntuple(i -> soa_fieldtypes(fieldtype(T, i)), fieldcount(T))
            NamedTuple{syms,Tuple{types...}}
        else
            T
        end
    end
end
=#


#=

p
a(p)
s(p)
s(a(p))
s(a(s))
s(s)

a(p)
a(a())
a(a(s)) tuple()

=#

 



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

#=
function ArrayOfStructs{T}(entries::SOACols{N,ncols,colnames}) where {T,N,p<:SOACols{N}}
    refcolumn = _getrefcolumn(entries)
    N = ndims(refcolumn)
    P = typeof(entries)
    U = eltype(refcolumn)
    R = typeof(refcolumn)

    # TODO: Wrap inner named tuples in ArrayOfStructs

    ArrayOfStructs{T,N,P,U,R}(Val{:unsafe}(), entries, refcolumn)
end
=#


# Note: Probably can't support static arrays, as index/fieldname duality would be ambiguous


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




#soa_repr(::Type{T}, AbstractArray{T,N}, x::NamedTuple) where {T,N} = ArrayOfStructs{T}(x)

#soa_repr(::Type{T}, AbstractArray{IAT,N}, x::NamedTuple, Val{N}) where {T,N,IAT<:AbstractArray} = ArrayOfStructs{T}(x)


@inline _getentries(A::ArrayOfStructs) = getfield(A, :_entries)
@inline _getfirstcol(A::ArrayOfStructs) = _getentries(A)[1]

@inline Base.getproperty(A::ArrayOfStructs, sym::Symbol) = getproperty(_getentries(A), sym)
@inline Base.propertynames(A::ArrayOfStructs) = propertynames(_getentries(A))

@inline Base.size(A::ArrayOfStructs) = size(_getfirstcol(A))



#=


@inline soacolumn_repr_impl(::Val{:primitive}, ::Type{AbstractArray{T,N}}, x::AbstractArray{T,N}) = x

@inline soacolumn_repr(CT::Type{AbstractArray{<:AbstractArray{T,M},N}}, x::AbstractArray{<:AbstractArray{T,M},N}) where {T,M,N} =
    soacolumn_repr(soarepr_category(T), CT, x)

@inline soacolumn_repr_impl(::Val{:primitive}, ::Type{AbstractArray{<:AbstractArray{T,M},N}}, x::AbstractArray{<:AbstractArray{T,M},N})




@inline _nonstruct_soacolumn(::Type{AbstractArray{T,N}}, x::AbstractVector{<:T,N}) where {T,N} = x

@inline _nonstruct_soacolumn(::Type{AbstractArray{T,N}}, x::AbstractVector{U,N}) where {T,N,U} =
    convert(Array{T,N}, x)

@inline _nestedarray_soacolumn(::Type{AbstractArray{AbstractArray,N}}, x::AbstractVector{U,N}) where {T<:,N,U} =
    convert(Array{T,N}, x)


@inline _nestedarray_soacolumn(::Type{AbstractArray{<:AbstractArray{T,M},N}}, x::AbstractVector{U,N}) where {T<:,N,U} =

AbstractArray{<:AbstractArray{T,M},N}



@inline function soacolumn(AT::Type{AbstractArray{T,N}}, x) where {T,N}
    if @generated
        if isstructtype(T)
        else
            :(_nonstruct_soacolumn(AT,$x))
        end
    else
        @error "Not implemented yet"
    end
end

#function ArrayOfStructs{T,N}(columns::Tuple) where {T<:AbstractArray,N}

function ArrayOfStructs{T,N}(columns::NTuple{M,AbstractArray{<:Any,N}}) where {T,M}
    nfields = fieldcount(T)
    ncols == nfields || throw(ArgumentError("Can't construct ArrayOfStructs over type $T with $nfields from $M columns."))
    if @generated
        nt = :(())
        for i in Base.OneTo(M)
            sym = fieldname(T, i)
            U = fieldtype(T, i)
            push!(nt.args, :($sym = soacolumn($U, columns[$i])))
        end
        :(ArrayOfStructs(Val{:unsafe}(), $nt))
    else
        @error "Not implemented yet"
    end
end


=#




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
