import Mongoc
using Dates
using NamedTupleTools
using DataStructures


"""
Create a BSON document from an arbitrary value.
Recursively converts the internal structure of arrays, tuples, structs, etc.
"""
function Mongoc.BSON(value::Any)
    fnames = fieldnames(typeof(value))
    if isempty(fnames)
        error("cannot create BSON from DataType $(typeof(value)) with no fields")
    end

    doc = Mongoc.BSON()
    for (fname, ftype) in zip(fnames, typeof(value).types)
        doc[string(fname)] = getfield(value, fname)
    end
    return doc
end


# Mongoc only supports Float64, add other float types that fit into float64.
Base.setindex!(document::Mongoc.BSON, value::Union{Float16, Float32}, key::AbstractString) = setindex!(document, Float64(value), key)

# Mongoc only supports Int32 and Int64, and smaller signed int types.
Base.setindex!(document::Mongoc.BSON, value::Union{Int8, Int16}, key::AbstractString) = setindex!(document, Int64(value), key)

# Mongoc supports no unsigned integer types, add the ones which will fit into (signed) Int32/Int64.
Base.setindex!(document::Mongoc.BSON, value::Union{UInt8, UInt16}, key::AbstractString) = setindex!(document, Int32(value), key)
Base.setindex!(document::Mongoc.BSON, value::UInt32, key::AbstractString) = setindex!(document, Int64(value), key)

# Mongoc does not support using numbers as Dict keys.
Base.setindex!(document::Mongoc.BSON, value::Any, key::Number) = setindex!(document, value, string(key))

Base.setindex!(document::Mongoc.BSON, value::Tuple, key::AbstractString) = setindex!(document, collect(value), key)

function Base.setindex!(document::Mongoc.BSON, value::NamedTuple, key::AbstractString) 
    tupleKeys = map(String, keys(value))
    tupleValues = values(value)
    data = Mongoc.BSON()
    for (k, v) in zip(tupleKeys, tupleValues)
        data[k] = v
    end
    setindex!(document, data, key)
end

Base.setindex!(document::Mongoc.BSON, value::DataType, key::AbstractString) = setindex!(document, string(value), key)

Base.setindex!(document::Mongoc.BSON, value::Any, key::AbstractString) = setindex!(document, Mongoc.BSON(value), key)
