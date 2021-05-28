module BSONify

export as_type
export TypeValueMismatch
export FieldsMismatch
export TypeIsNotAMapping

include("tobson.jl")
include("frombson.jl")

end # module
