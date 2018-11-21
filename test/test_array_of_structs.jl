# This file is part of ArraysOfStructs.jl, licensed under the MIT License (MIT).

using ArraysOfStructs
using Test

using Random


struct SimpleFoo
    x::Int
    y::Float64
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

foobar = FooBar(42, 4.2, [3, 4, 5], rand(4,5), simplefoo)

nt = (x = 42, y = 7)


using ArraysOfStructs: _getfieldnames, _getfieldtypes, namedtuple_type, ntconvert


@testset "array_of_structs" begin
    @test ntconvert(NamedTuple, foobar) isa namedtuple_type(typeof(foobar))
end
