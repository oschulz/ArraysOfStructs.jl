# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).

using ArraysOfStructs
using Test

using ArraysOfStructs: val_of_fieldnames, de_struct_type, de_struct, re_struct
using ArraysOfStructs: soarepr_category, soa_coltype, soa_coltype_impl


using Random
using StaticArrays


struct SimpleFoo
    x::Int
    y::Float64
end


struct Point{T} <: FieldVector{3,T}
    x::T
    y::T
    z::T
end


struct NestedFoo{T}
    a::Int
    b::SimpleFoo
    c::Point{T}
end

struct FooBar{
    T<:Real,
    U<:Real,
    TV<:AbstractVector{Point{T}},
    UM<:AbstractMatrix{U},
}
    a::T
    b::U
    cv::TV
    dm::UM
    e::SimpleFoo
end


simplefoo = SimpleFoo(42, 7)
simplent = (x = 42, y = 7)

point = Point(1.2, 2.3, 3.4)
pointnt = (x = 1.2, y = 2.3, z = 3.4)

nestedfoo = NestedFoo(4, simplefoo, point)
nestednt = (a = 4, b = simplent, c = pointnt)

foobar = FooBar(42, 4.2, [Point(1,2,3), Point(4,5,6)], rand(4,5), simplefoo)



@testset "array_of_structs" begin
    @test @inferred(val_of_fieldnames(FooBar)) == Val((:a, :b, :cv, :dm, :e))

    @test @inferred(de_struct(simplefoo)) == simplent
    @test @inferred(de_struct(nestedfoo)) == nestednt
    # @test @inferred(de_struct(foobar)) == foobarnt

    @test @inferred(de_struct(simplefoo)) isa @inferred(de_struct_type(typeof(simplefoo)))
    @test @inferred(de_struct(nestedfoo)) isa @inferred(de_struct_type(typeof(nestedfoo)))
    # @test @inferred(de_struct(foobar)) isa @inferred(de_struct_type(typeof(foobar)))

    @test @inferred(re_struct(SimpleFoo, simplent)) == simplefoo
    @test @inferred(re_struct(NestedFoo, nestednt)) == nestedfoo
    # @test @inferred(re_struct(FooBar, foobar)) == foobarnt

    #=
    @test (val_of_fieldnames(FooBar)) == Val((:a, :b, :cv, :dm, :e))

    @test (de_struct(simplefoo)) == simplent
    @test (de_struct(nestedfoo)) == nestednt
    # @test (de_struct(foobar)) == foobarnt

    @test (de_struct(simplefoo)) isa (de_struct_type(typeof(simplefoo)))
    @test (de_struct(nestedfoo)) isa (de_struct_type(typeof(nestedfoo)))
    # @test (de_struct(foobar)) isa (de_struct_type(typeof(foobar)))

    @test (re_struct(SimpleFoo, simplent)) == simplefoo
    @test (re_struct(NestedFoo, nestednt)) == nestedfoo
    # @test (re_struct(FooBar, foobar)) == foobarnt
    =#
end
