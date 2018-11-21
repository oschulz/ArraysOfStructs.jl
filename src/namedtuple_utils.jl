# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).


Base.@pure de_struct_type(T::Type{<:AbstractArray{U,N}}) where {U,N} = AbstractArray{<:de_struct_type(U),N}

# Base.@pure de_struct_type(T::Type{<:StaticArray{N,U}}) where {U,N} = StaticArray{N,<:de_struct_type(U)}

Base.@pure de_struct_type(::Type{T}) where {T<:FieldVector} = _de_struct_type_impl(T)

Base.@pure de_struct_type(::Type{T}) where {T} = _de_struct_type_impl(T)

Base.@pure function _de_struct_type_impl(::Type{T}) where {T}
    if @generated
        if isstructtype(T)
            syms = :(())
            types = :(Tuple{})
            for i in Base.OneTo(fieldcount(T))
                push!(syms.args, QuoteNode(fieldname(T, i)))
                push!(types.args, de_struct_type(fieldtype(T, i)))
            end
            :(NamedTuple{$syms,$types})
        else
            :T
        end
    else
        if isstructtype(T)
            syms = fieldnames(T)
            types = ntuple(i -> de_struct_type(fieldtype(T, i)), fieldcount(T))
            NamedTuple{syms,Tuple{types...}}
        else
            T
        end
    end
end


@inline function de_struct(x::T) where {T}
    if @generated
        if isstructtype(T)
            nt = :(())
            for sym in fieldnames(T)
                push!(nt.args, :($sym = de_struct(x.$sym)))
            end
            :($nt)
        else
            :x
        end
    else
        if isstructtype(T)
            syms = fieldnames(T)
            vals = map(sym -> de_struct(getfield(x, sym)), syms)
            NamedTuple{syms}(vals)
        else
            x
        end
    end
end


@inline re_struct(::Type{T}, x) where {T} = convert(T, x)

@inline function re_struct(::Type{T}, x::NT) where {T,NT<:NamedTuple}
    val_of_fieldnames(T) == val_of_fieldnames(NT) || throw(ArgumentError("Can't convert type $NT to type $T with different field names."))
    if @generated
        expr = :($T())
        for i in Base.OneTo(fieldcount(NT))
            sym = fieldname(NT, i)
            U = fieldtype(T, i)
            push!(expr.args, :(re_struct($U, x.$sym)))
        end
        expr
    else
        T(ntuple(i -> re_struct(fieldtype(T, i), getfield(x, i)), fieldcount(T))...)
    end
end


Base.@pure val_of_fieldnames(::Type{<:NamedTuple{names, types}}) where {names, types} = Val{names}()

Base.@pure function val_of_fieldnames(::Type{T}) where {T}
    if @generated
        :(Val{$(fieldnames(T))}())
    else
        Val(fieldnames(T))
    end
end
