#!/usr/bin/env julia

using BSONify, Test, SafeTestsets

@time begin
@time @safetestset "Reconstitute" begin include("reconstitute_test.jl") end
end
