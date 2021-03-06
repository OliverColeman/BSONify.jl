# BSONify.jl

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Build Status](https://travis-ci.com/OliverColeman/BSONify.jl.svg?branch=master)](https://travis-ci.com/OliverColeman/BSONify.jl)
[![codecov.io](http://codecov.io/github/OliverColeman/BSONify.jl/coverage.svg?branch=master)](http://codecov.io/github/OliverColeman/BSONify.jl?branch=master)

*BSONify.jl* is a Julia package for painlessly converting Julia data structures to and from [BSON](http://bsonspec.org/) (Binary JSON). BSON is a JSON-like data storage format that is designed to be efficient and fast and also store binary data. It is supported by many languages and is native to the MongoDB database system.

*BSONify.jl* stores only the data in the BSON document, in a minimal and clear way. No metadata is stored, making it efficient and convenient for communication with other systems.

The resulting BSON document can be stored in a MongoDB database or to files via [Mongoc.jl](https://github.com/felipenoris/Mongoc.jl).

*BSONify.jl* can handle just about any data structure, including primitive types, arbitrary composite types defined by other modules or your own data structures, nested and recursive data structures, complicated parametrised types, and even type unions.


## Example

```julia
using BSONify, Dates
import Mongoc

# Define a custom parametric struct.
struct MyStruct{T, S}
    myDateTime::DateTime
    myArray::Array{S}
    myParametric::T
    myDict::Dict{T, S}
    myNamedTuple::NamedTuple{(:a, :b), Tuple{Int16, Float32}}
    myChild::Union{MyStruct{T, S}, S, Nothing} # Support for recursive structures and type unions.
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
        "sweet child o' mine"
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
MyStruct{UInt8, String}(DateTime("2021-05-28T13:12:37.742"), ["The", "answer", "is"], 0x2a, Dict{UInt8, String}(0x04 => "is", 0x02 => "answer?!"), (a = 1, b = 2.3f0), MyStruct{UInt8, String}(DateTime("2021-05-28T13:12:37.753"), ["It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time"], 0x00, Dict{UInt8, String}(), (a = 1, b = 2.0f0), "sweet child o' mine"))

bson:
BSON("{ "myDateTime" : { "$date" : "2021-05-28T13:12:37.742Z" }, "myArray" : [ "The", "answer", "is" ], "myParametric" : 42, "myDict" : { "4" : "is", "2" : "answer?!" }, "myNamedTuple" : { "a" : 1, "b" : 2.2999999523162841797 }, "myChild" : { "myDateTime" : { "$date" : "2021-05-28T13:12:37.753Z" }, "myArray" : [ "It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time" ], "myParametric" : 0, "myDict" : {  }, "myNamedTuple" : { "a" : 1, "b" : 2.0 }, "myChild" : "sweet child o' mine" } }")

myReconstitutedData:
MyStruct{UInt8, String}(DateTime("2021-05-28T13:12:37.742"), ["The", "answer", "is"], 0x2a, Dict{UInt8, String}(0x04 => "is", 0x02 => "answer?!"), (a = 1, b = 2.3f0), MyStruct{UInt8, String}(DateTime("2021-05-28T13:12:37.753"), ["It's", "not", "a", "question,", "but", "an", "answer", "learned", "in", "time"], 0x00, Dict{UInt8, String}(), (a = 1, b = 2.0f0), "sweet child o' mine"))
```


## Usage

### Exporting to BSON
*BSONify.jl* extends the *Mongoc.jl* API to handle arbitrary types when creating BSON documents.

To convert some data to a BSON document pass it to the `Mongoc.BSON()` function:
```julia
myBSON = Mongoc.BSON(myData)
```

**Note:** the root of a BSON document is always a dictionary-like structure: **the value passed to `Mongoc.BSON()` must be a key-value mapping**. Acceptable key-value mappings are things like `Dict`s, composite type (`struct`) instances, and anything that extends `AbstractDict`. More specifically, it can be any mapping for which the keys or fields are accessible via the `keys()` or `fieldnames()` functions. If you need to save data that is not at root a key-value mapping, then you can do something like this to create a BSON document with a single key, `"myArray"` in this case, that is mapped to the data you want to store:
```julia
# Store an array in a BSON document.
myArray = [1, 2, 3]
myBSON = Mongoc.BSON("myArray" => myArray)
```

### Importing from BSON
To convert data stored in a BSON document into a Julia data structure you use the `as_type(type, data)` function. `as_type` accepts two arguments: the `type` to convert the BSON document into, and `data`, the BSON document itself. It will create an instance of whatever type is passed with the values specified in the BSON document, recursively if necessary. For example:
```julia
myData = as_type(MyType, myBSON)
```
Or to retrieve the array stored in the *Exporting to BSON* section:
```julia
myArray = as_type(Array{Int64}, myBSON["myArray"])
```
Note here that we stored the array under the `"myArray"` key, so we retrieve the array using that key on the BSON document before passing it to `as_type`.

### Storing BSON documents as files or in a MongoDB
To read and write data (BSON) from and to files or a MongoDB, see this [documentation for *Mongoc.jl*](https://felipenoris.github.io/Mongoc.jl/stable/tutorial/#Read/Write-BSON-documents-from/to-IO-Stream-1).


## License

The source code for the package `BSONify.jl` is licensed under the [MIT License](https://github.com/OliverColeman/BSONify.jl/blob/master/LICENSE).

## Alternative and related libraries

* [Mongoc.jl](https://github.com/felipenoris/Mongoc.jl) -
allows converting simple data structures such as Dicts and Arrays to and from BSON. *BSONify.jl* is partly built on top of *Mongoc.jl*.

* [BSON.jl](https://github.com/JuliaIO/BSON.jl) - allows converting complex data structures to and from BSON. Stores type metadata in the BSON, producing larger and (IMHO ;)) harder to interpret BSON documents. Requires specifying the module namespace under which to restore complex/custom types (rather than the type itself like *BSONify.jl*).

* [JSON3.jl](https://github.com/quinnj/JSON3.jl) - similar API but for JSON rather than BSON.
