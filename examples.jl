using BSONify, Dates
import Mongoc # BSONify extends the Mongoc API to handle arbitrary types when creating BSON documents.

# Define a custom parametric struct.
struct MyStruct{T, S}
    myDateTime::DateTime
    myArray::Array{S}
    myParametric::T
    myDict::Dict{T, S}
    myNamedTuple::NamedTuple{(:a, :b), Tuple{Int16, Float32}}
    myChild::Union{MyStruct{T, S}, Nothing} # Support for recursive structures and type unions.
end

# Define a custom type from the custom struct.
MyType = MyStruct{UInt8, String}

# Create some data.
myData = MyType(
    now(),
    ["The", "answer", "is"],
    42,
    Dict(4 => "is", 2 => "answer?!"),
    (a=1, b=2.3),
    MyType(
        now(),
        split("It's not a question, but an answer learned in time"),
        0,
        Dict(),
        (a=1, b=2),
        nothing
    )
)

println("myData:\n", myData)

bson = Mongoc.BSON(myData)

println("\nbson:\n", bson)

myReconstitutedData = as_type(MyType, bson)

println("\nmyReconstitutedData:\n", myReconstitutedData)
