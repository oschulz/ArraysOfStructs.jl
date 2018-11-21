# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


Base.@pure soarepr_category(::Type{<:Array}) = Val{:array}()
Base.@pure soarepr_category(::Type{<:Tuple}) = Val{:tuple}()
Base.@pure soarepr_category(::Type{<:StaticArray}) = Val{:tuple}()
Base.@pure soarepr_category(::Type{<:FieldVector}) = Val{:struct}()

Base.@pure function soarepr_category(::Type{T}) where T
    #if @generated
    #    :(Val{$(isstructtype(T) ? :struct : primitive)}())
    #else
        Val{isstructtype(T) ? :struct : primitive}()
    #end
end



Base.@pure soa_coltype(::Type{AbstractArray{<:AbstractArray{T,M},N}}) where {T,M,N} =
    soa_coltype_impl(soarepr_category(T), AbstractArray{T,N}, Val(M))

Base.@pure soa_coltype(::Type{AbstractArray{T,N}}) where {T,N} =
    soa_coltype_impl(soarepr_category(T), AbstractArray{T,N})

Base.@pure soa_coltype(::Type{AbstractArray{T,N}}) where {T<:StaticArray,N} =
    soa_coltype_impl(soarepr_category(T), AbstractArray{T,N})


Base.@pure soa_coltype_impl(::Val{:primitive}, AT::Type{AbstractArray{T,N}}) where {T,N} =
    AbstractArray{T,N}

Base.@pure soa_coltype_impl(::Val{:primitive}, AT::Type{AbstractArray{T,N}}, Val{M}) where {T,N,M} =
    AbstractArray{<:AbstractArray{T,M},N}}


Base.@pure function soa_coltype_impl(::Val{:struct}, AT::Type{AbstractArray{T,N}}) where {T,N}
    syms = fieldnames(T)
    types = ntuple(Val(fieldcount(T))) do i
        U = fieldtype(T, i)
        soa_coltype(AbstractArray{U,N})
    end
    NamedTuple{syms,Tuple{types...}}
end

Base.@pure function soa_coltype_impl(::Val{:struct}, AT::Type{AbstractArray{T,N}}, ::Val{M}) where {T,N,M}
    syms = fieldnames(T)
    ntuple(Val(fieldcount(T))) do i
        U = fieldtype(T, i)
        soa_coltype(AbstractArray{AbstractArray{U,M},N})
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

 

#=


abstract type AbstractArrayOfStructs end


struct ArrayOfStructs{T,N,P<:NamedTuple}
    _entries::P

    ArrayOfStructs{T,N}(::Val{:unsafe}, entries::NamedTuple) where {T,N} =
        new{T,N,typeof(entries)}(entries)
end


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
