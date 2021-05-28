using BSONify, Test, Dates, NamedTupleTools
import Mongoc


function testReconstitutePrimitive(T, value)
    original = Dict("v" => value)
    # println("original: ", original)
    # println()
    bson = Mongoc.BSON(original)
    # println("bson: ", bson)
    # println()

    reconstituted = as_type(Dict{String, T}, bson)
    # println("reconstituted: ", reconstituted)
    # println()
    @test original["v"] == reconstituted["v"]
end


function testReconstituteStruct(T, value)
    # println(value)
    bson = Mongoc.BSON(value)
    # println(bson)
    reconstituted = as_type(T, bson)
    # println(reconstituted)
    @test value == reconstituted
end


numberTypes = [ Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, Float16, Float32, Float64 ]


####### Primitives (and dict, given implementation of testReconstitutePrimitive)

testReconstitutePrimitive(Bool, true)
testReconstitutePrimitive(Bool, false)

for T in numberTypes
    testReconstitutePrimitive(T, convert(T, 42))
end
testReconstitutePrimitive(String, "42")
testReconstitutePrimitive(DateTime, now())
testReconstitutePrimitive(DataType, Int16)

# Auto convert string to number (really only used when converting numeric map keys to strings to be bson compatible)
as_type(Int32, "123") == 123
as_type(Float64, "12.3") == 12.3


######## Numbers as dict keys

testReconstitutePrimitive(Dict{Int32, Int32}, Dict(12 => 34, 56 => 78))
testReconstitutePrimitive(Dict{Float32, Int32}, Dict(1.2f0 => 34, 5.6f0 => 78))

######## Arrays of primitives

for T in numberTypes
    testReconstitutePrimitive(Array{T}, collect(0:42))
end
testReconstitutePrimitive(Array{String}, split("It's not a question, but an answer learned in time"))
testReconstitutePrimitive(Array{DateTime}, [ now() ])


####### Tuples of primitives

for T in numberTypes
    testReconstitutePrimitive(Tuple{T}, tuple(collect(0:42)...))
end
testReconstitutePrimitive(Tuple{String}, tuple(split("It's not a question, but an answer learned in time")...))
testReconstitutePrimitive(Tuple{DateTime}, ( now(), ))


######## Named tuple

symbols = Meta.parse.(string.(numberTypes))
vals=[collect(1:length(numberTypes))...]
nt = namedtuple(symbols, vals)
testReconstitutePrimitive(typeof(nt), nt)



####### UNION TYPES

TestUnionType = Union{Int32, String, Nothing}

testReconstitutePrimitive(TestUnionType, 123)
testReconstitutePrimitive(TestUnionType, "blah")
testReconstitutePrimitive(TestUnionType, nothing)



########## STRUCTS #######

# Allow comparing structs with (mutable) arrays: https://stackoverflow.com/questions/62336686/struct-equality-with-arrays
abstract type Comparable end
import Base.==
function ==(a::T, b::T) where T <: Comparable
    f = fieldnames(T)
    getfield.(Ref(a),f) == getfield.(Ref(b),f)
end


####### Simple struct

struct SimpleStruct
    primitive1::Int32
    primitive2::String
end
testReconstituteStruct(SimpleStruct, SimpleStruct(123, "lalala"))


####### Parametric type struct

struct ParametricStruct{T} <: Comparable
    primitive1::Int32
    parametric::T
    array::Array{T}
end
testReconstituteStruct(ParametricStruct{Float32}, ParametricStruct{Float32}(
    123, 
    4.56, 
    [7, 8, 9]
))


####### Nested structs

struct GrandChildStruct{T, S} <: Comparable
    val1::T
    val2::S
    val3::Dict{T, S}
end

struct ChildStruct{T, S} <: Comparable
    grandChild::GrandChildStruct{T, S}
end

struct ParentStruct{T, S} <: Comparable
    child::ChildStruct{T, S}
end

testReconstituteStruct(
    ParentStruct{String, Int32}, 
    ParentStruct{String, Int32}(
        ChildStruct{String, Int32}(
            GrandChildStruct{String, Int32}(
                "foo", 
                123, 
                Dict("bar" => 456, "baz" => 789)
            )
        )
    )
)



mutable struct RecursiveStruct <: Comparable
    val::Int64
    child::Union{RecursiveStruct, Nothing}
end

testReconstituteStruct(
    RecursiveStruct, 
    RecursiveStruct(
        1, RecursiveStruct(
            2, RecursiveStruct(
                3, nothing
            )
        )
    )
)


# EXCEPTIONS

@test_throws TypeValueMismatch as_type(Int32, 1.2)
@test_throws TypeValueMismatch as_type(String, 12)
@test_throws TypeValueMismatch as_type(SimpleStruct, 12)
@test_throws TypeValueMismatch testReconstitutePrimitive(TestUnionType, 12.3)

@test_throws FieldsMismatch as_type(SimpleStruct, Dict("primitive1" => 12))
@test_throws FieldsMismatch as_type(SimpleStruct, Dict("primitive1" => 12, "primitive3" => "12"))
@test_throws FieldsMismatch as_type(SimpleStruct, Dict("primitive1" => 12, "primitive2" => "12", "primitive3" => "12"))

@test_throws TypeIsNotAMapping Mongoc.BSON(123)
