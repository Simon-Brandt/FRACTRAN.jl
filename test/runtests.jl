#!/usr/bin/env julia

###############################################################################
#                                                                             #
# Copyright 2026 Simon Brandt                                                 #
#                                                                             #
# Licensed under the Apache License, Version 2.0 (the "License");             #
# you may not use this file except in compliance with the License.            #
# You may obtain a copy of the License at                                     #
#                                                                             #
#     http://www.apache.org/licenses/LICENSE-2.0                              #
#                                                                             #
# Unless required by applicable law or agreed to in writing, software         #
# distributed under the License is distributed on an "AS IS" BASIS,           #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    #
# See the License for the specific language governing permissions and         #
# limitations under the License.                                              #
#                                                                             #
###############################################################################

# Author: Simon Brandt
# E-Mail: simon.brandt@uni-greifswald.de
# Last Modification: 2026-08-27

using Test: @test, @testset, @test_throws

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

    # Test FRACTRAN's prime number generation.
    @testset "Prime number generation" begin
        primes = [
              2,
              3,
              5,
              7,
             11,
             13,
             17,
             19,
             23,
             29,
             31,
             37,
             41,
             43,
             47,
             53,
             59,
             61,
             67,
             71,
             73,
             79,
             83,
             89,
             97,
            101,
            103,
            107,
            109,
            113,
            127,
            131,
            137,
            139,
            149,
            151,
            157,
            163,
            167,
            173,
            179,
            181,
            191,
            193,
            197,
            199,
        ]

        @test generate_primes(3, 5) == [3, 5]
        @test generate_primes(200) == primes

        # There are 78,498 prime numbers below 1 million, see
        # https://www.mathematical.com/primes0to1000k.html.
        @test length(generate_primes(1_000_000)) == 78_498

        @test_throws ArgumentError generate_primes(1, 10)
        @test_throws "`min_n` must be `≥2`." generate_primes(1, 10)

        @test_throws ArgumentError generate_primes(4, 10)
        @test_throws "`min_n` must be odd." generate_primes(4, 10)
    end
end
