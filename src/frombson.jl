import Mongoc
using Dates
using NamedTupleTools
using DataStructures


"""
Get the types from a union type.
https://stackoverflow.com/a/43305886/1133481
"""
union_types(x::Union) = (x.a, union_types(x.b)...)
union_types(x::Type) = (x,)


struct TypeValueMismatch <: Exception
    msg::AbstractString
end

struct FieldsMismatch <: Exception
    msg::AbstractString
end


field_names_as_string(type) = map(fnSymbol -> string(fnSymbol), fieldnames(type))


"""
Convert the given bson document or value to the specified type, recursively converting 
arrays, tuples, dicts and sub-documents according to the same structure produced by
`Mongoc.BSON(value::Any)`
"""
function as_type(type, value)
    valueType = typeof(value)

    # println("as_type   $(type)   $(value)   valueType: $(valueType)")

    if valueType <: type
        return value
    end

    # Attempt to `convert` the value.
    try
        converted = convert(type, value)
        # println("converted: $(converted)")
        return converted
    catch
        # println("could not convert")
    end
    
    if type <: Tuple
        vals = []
        for (index, val) in enumerate(value)
            elementType = eltype(type)
            convertedVal = as_type(elementType, val)
            push!(vals, (index, convertedVal))
        end
        sort!(vals, by = x -> x[1])
        vals = map(x -> x[2], vals)
        return (vals...,)
    elseif type == DataType
        return eval(Meta.parse(value))
    elseif type <: Dict
        kt = keytype(type)
        vt = valtype(type)
        
        dkeys = []
        for k in keys(value)
            push!(dkeys, as_type(kt, k))
        end
        
        dvalues = []
        for v in Base.values(value)
            push!(dvalues, as_type(vt, v))
        end
        
        return Dict(zip(dkeys, dvalues))
    elseif type <: NamedTuple
        symbols = fieldnames(type)
        vals = []
        for (s, t) in zip(symbols, type.types)
            push!(vals, as_type(t, value[string(s)]))
        end
        return namedtuple(symbols, vals)
    elseif type <: Number && valueType <: AbstractString
        return parse(type, value)
    elseif typeof(type) <: Union
        # Try to convert the value to each type in the union type.
        for ut in union_types(type)
            try
                return as_type(ut, value)
            catch
            end
        end
        throw(TypeValueMismatch("could not convert $(value) to any of the types in $(type)"))
    end

    typeFieldNames = field_names_as_string(type)

    if valueType <: AbstractDict
        valueFieldNames = [ keys(value)... ]
        # println("keys from dict/bson: $(valueFieldNames)")
    else
        valueFieldNames = field_names_as_string(valueType)
        # println("keys from other: $(valueFieldNames)")
    end

    
    if isempty(typeFieldNames) || isempty(valueFieldNames)
        throw(TypeValueMismatch("invalid value for type $(type): $(value)"))
    end

    if Set(typeFieldNames) != Set(valueFieldNames)
        throw(FieldsMismatch("value and type have mismatched fields: type fields = $(typeFieldNames); value fields = $(valueFieldNames)"))
    end

    values = []
    for (fname, ftype) in zip(typeFieldNames, type.types)
        push!(values, as_type(ftype, value[fname]))
    end
    return type(values...)
end
