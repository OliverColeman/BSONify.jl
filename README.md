# BSONify

BSONify.jl is a Julia package for painlessly converting Julia data structures to and from BSON [Binary JSON](http://bsonspec.org/). 

Only the data is stored in the BSON document, in a minimal and clear way. No metadata is stored, making it efficient and convenient for communication with other systems.

The resulting BSON document can be stored in a MongoDB or to files via [Mongoc.jl](https://github.com/felipenoris/Mongoc.jl).

*BSONify* can handle just about any data structure, including primitive types, arbitrary composite types defined by other modules or your own data structures, recursive data structures, complicated parametrised types, and even type unions.

## Example

```julia
using BSONify, Dates
import Mongoc # BSONify extends the Mongoc API to handle arbitrary types when creating BSON documents.

# Define a custom parametric struct.
struct MyStruct{T, S}
    myDateTime::DateTime
    myArray::Array{S}
    myParametric::T
    myDict::Dict{T, S}
    myNamedTuple::NamedTuple{(:a, :b), Tuple{Int16, Float32}}
    myChild::Union{MyStruct{T, S}, Nothing}
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

# Convert our data to BSON.
bson = Mongoc.BSON(myData)

println("\nbson:\n", bson)

# Convert BSON back to our custom type.
myReconstitutedData = as_type(MyType, bson)

println("\nmyReconstitutedData:\n", myReconstitutedData)

```

### Result:
```
myData:
MyStruct{UInt8, String}(DateTime("2021-05-24T11:51:44.322"), ["The", "answer", "is"], 0x2a, Dict{UInt8, String}(0x04 => "is", 0x02 => "answer?!"), (a = 1, b = 2.3f0), MyStruct{UInt8, String}(DateTime("2021-05-24T11:51:44.322"), ["It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time"], 0x00, Dict{UInt8, String}(), (a = 1, b = 2.0f0), nothing))

bson:
BSON("{ "myDateTime" : { "$date" : "2021-05-24T11:51:44.322Z" }, "myArray" : [ "The", "answer", "is" ], "myParametric" : 42, "myDict" : { "4" : "is", "2" : "answer?!" }, "myNamedTuple" : { "a" : 1, "b" : 2.2999999523162841797 }, "myChild" : { "myDateTime" : { "$date" : "2021-05-24T11:51:44.322Z" }, "myArray" : [ "It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time" ], "myParametric" : 0, "myDict" : {  }, "myNamedTuple" : { "a" : 1, "b" : 2.0 }, "myChild" : null } }")

myReconstitutedData:
MyStruct{UInt8, String}(DateTime("2021-05-24T11:51:44.322"), ["The", "answer", "is"], 0x2a, Dict{UInt8, String}(0x04 => "is", 0x02 => "answer?!"), (a = 1, b = 2.3f0), MyStruct{UInt8, String}(DateTime("2021-05-24T11:51:44.322"), ["It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time"], 0x00, Dict{UInt8, String}(), (a = 1, b = 2.0f0), nothing))
```
