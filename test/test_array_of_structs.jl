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

simplefoo = SimpleFoo(42, 7)

nestedfoo = NestedFoo(4, 5, simplefoo)

foobar = FooBar(42, 4.2, [3, 4, 5], rand(4,5), simplefoo)

simplent = (x = 42, y = 7)
nestednt = (x = 4, y = 5, z = simplent)


using ArraysOfStructs: fieldnames_as_val, de_struct_type, de_struct, re_struct


@testset "array_of_structs" begin
    @test @inferred(fieldnames_as_val(FooBar)) == Val((:a, :b, :cv, :dm, :e))

    @inferred(de_struct(simplefoo)) == simplent
    @inferred(de_struct(nestedfoo)) == nestednt
    # @inferred(de_struct(foobar)) == foobarnt

    @test @inferred(de_struct(simplefoo)) isa @inferred(de_struct_type(typeof(simplefoo)))
    @test @inferred(de_struct(nestedfoo)) isa @inferred(de_struct_type(typeof(nestedfoo)))
    # @test @inferred(de_struct(foobar)) isa @inferred(de_struct_type(typeof(foobar)))

    @inferred(re_struct(SimpleFoo, simplent)) == simplefoo
    @inferred(re_struct(NestedFoo, nestedfoo)) == nestedfoo
    # @inferred(re_struct(FooBar, foobar)) == foobarnt

    #=
    @test (fieldnames_as_val(FooBar)) == Val((:a, :b, :cv, :dm, :e))

    (de_struct(simplefoo)) == simplent
    (de_struct(nestedfoo)) == nestednt
    # (de_struct(foobar)) == foobarnt

    @test (de_struct(simplefoo)) isa (de_struct_type(typeof(simplefoo)))
    @test (de_struct(nestedfoo)) isa (de_struct_type(typeof(nestedfoo)))
    # @test (de_struct(foobar)) isa (de_struct_type(typeof(foobar)))

    (re_struct(SimpleFoo, simplent)) == simplefoo
    (re_struct(NestedFoo, nestedfoo)) == nestedfoo
    # (re_struct(FooBar, foobar)) == foobarnt
    =#
end
