#!/usr/bin/env julia

# Author: Simon Brandt
# E-Mail: simon.brandt@uni-greifswald.de
# Last Modification: 2026-08-26

using Test: @testset

using Aqua: Aqua
using JET: JET

using FRACTRAN

@testset "FRACTRAN.jl" begin
    # Test the code quality.
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(FRACTRAN)
    end

    # Lint the code.
    @testset "Code linting (JET.jl)" begin
        JET.test_package(FRACTRAN, target_modules=(FRACTRAN,))
    end
end
