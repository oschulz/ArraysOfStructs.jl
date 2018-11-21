# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).

using ArraysOfStructs
using Test

using Random


struct SimpleFoo
    x::Int
    y::Float64
end

struct NestedFoo
    x::Int
    y::Float64
    z::SimpleFoo
end

struct FooBar{
    T<:Real,
    U<:Real,
    TV<:AbstractVector{T},
    UM<:AbstractMatrix{U},
}
    a::T
    b::U
    cv::TV
    dm::UM
    e::SimpleFoo
end

simplefoo = SimpleFoo(33, 7.1)

nestedfoo = NestedFoo(33, 7.1, simplefoo)

foobar = FooBar(42, 4.2, [3, 4, 5], rand(4,5), simplefoo)

simplent = (x = 42, y = 7)
nestednt = (x = 42, y = 7, z = (x = 2, y = 3))


using ArraysOfStructs: _fast_fieldnames, de_struct_type, de_struct, re_struct


@testset "array_of_structs" begin
    @test de_struct(simplefoo) isa de_struct_type(typeof(simplefoo))
    @test de_struct(nestedfoo) isa de_struct_type(typeof(nestedfoo))
    @test de_struct(foobar) isa de_struct_type(typeof(foobar))
end
