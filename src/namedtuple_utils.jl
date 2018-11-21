# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


#Base.@pure namedtuple_type(::Type{T<:NamedTuple}) where {T} = T

Base.@pure function namedtuple_type(::Type{T}) where {T}
    if @generated
        syms = :(())
        types = :(Tuple{})
        for i in Base.OneTo(fieldcount(T))
            push!(syms.args, QuoteNode(fieldname(T, i)))
            push!(types.args, fieldtype(T, i))
        end
        :(NamedTuple{$syms,$types})
    else
        syms = fieldnames(T)
        types = ntuple(i -> fieldtype(T, i), fieldcount(T))
        NamedTuple{syms,Tuple{types...}}
    end
end


# Note: isstructtype() may be useful


ntconvert(::Type{NamedTuple}, x::NamedTuple) = x

ntconvert(::Type{T}, x::T) where {T<:NamedTuple} = x

@inline function ntconvert(::Type{NamedTuple}, x::T) where {T}
    if @generated
        nt = :(())
        for name in fieldnames(T)
            push!(nt.args, :($name = x.$name))
        end
        :($nt)
    else
        syms = fieldnames(T)
        vals = ((getfield(x, sym) for sym in syms)...,)
        NamedTuple{syms}(vals)
    end
end


@inline function ntconvert(::Type{T}, x::NT) where {T,NT<:NamedTuple}
    _getfieldnames(T) == _getfieldnames(NT) || throw(ArgumentError("Can't convert type $NT to type $T with different field names."))
    if @generated
        expr = :($T())
        for i in Base.OneTo(fieldcount(NT))
            sym = fieldname(NT, i)
            push!(expr.args, :(x.$sym))
        end
        expr
    else
        T(x...)
    end
end


Base.@pure _getfieldnames(::Type{<:NamedTuple{names, types}}) where {names, types} = Val{names}()

Base.@pure function _getfieldnames(::Type{T}) where {T}
    if @generated
        :(Val{$(fieldnames(T))}())
    else
        Val(fieldnames(T))
    end
end


# Base.@pure _getfieldtypes(::Type{<:NamedTuple{names, types}}) where {names, types} = types # necessary?
# @inline _getfieldvalues(x::NamedTuple) = values(x)
