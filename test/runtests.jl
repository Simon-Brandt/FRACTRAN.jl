using FRACTRAN
using Test
using Aqua
using JET

@testset "FRACTRAN.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(FRACTRAN)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(FRACTRAN; target_defined_modules = true)
    end
    # Write your tests here.
end
