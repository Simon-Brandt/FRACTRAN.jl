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
# Last Modification: 2026-09-01

using Test: @test, @testset, @test_throws

using Aqua: Aqua
using DataStructures: Accumulator
using JET: JET

using FRACTRAN

# Define the prime numbers from 1 to 200 and the factorizations of 1 to
# 100 as global constants for repeated usage in the tests.
const PRIMES = [
           2,   3,        5,        7,
     11,       13,                 17,       19,
               23,                           29,
     31,                           37,
     41,       43,                 47,
               53,                           59,
     61,                           67,
     71,       73,                           79,
               83,                           89,
                                   97,
    101,      103,                107,      109,
              113,
                                  127,
    131,                          137,      139,
                                            149,
    151,                          157,
              163,                167,
              173,                          179,
    181,
    191,      193,                197,      199,
]

const FACTORIZATIONS = Dict(
    # The factorization for `1` is the empty product, see
    # https://math.stackexchange.com/a/47161.
      1 => Accumulator{Int64, Int64}(),
      2 => Accumulator( 2 => 1                  ),
      3 => Accumulator( 3 => 1                  ),
      4 => Accumulator( 2 => 2                  ),
      5 => Accumulator( 5 => 1                  ),
      6 => Accumulator( 2 => 1,  3 => 1         ),
      7 => Accumulator( 7 => 1                  ),
      8 => Accumulator( 2 => 3                  ),
      9 => Accumulator( 3 => 2                  ),
     10 => Accumulator( 2 => 1,  5 => 1         ),
     11 => Accumulator(11 => 1                  ),
     12 => Accumulator( 2 => 2,  3 => 1         ),
     13 => Accumulator(13 => 1                  ),
     14 => Accumulator( 2 => 1,  7 => 1         ),
     15 => Accumulator( 3 => 1,  5 => 1         ),
     16 => Accumulator( 2 => 4                  ),
     17 => Accumulator(17 => 1                  ),
     18 => Accumulator( 2 => 1,  3 => 2         ),
     19 => Accumulator(19 => 1                  ),
     20 => Accumulator( 2 => 2,  5 => 1         ),
     21 => Accumulator( 3 => 1,  7 => 1         ),
     22 => Accumulator( 2 => 1, 11 => 1         ),
     23 => Accumulator(23 => 1                  ),
     24 => Accumulator( 2 => 3,  3 => 1         ),
     25 => Accumulator( 5 => 2                  ),
     26 => Accumulator( 2 => 1, 13 => 1         ),
     27 => Accumulator( 3 => 3                  ),
     28 => Accumulator( 2 => 2,  7 => 1         ),
     29 => Accumulator(29 => 1                  ),
     30 => Accumulator( 2 => 1,  3 => 1,  5 => 1),
     31 => Accumulator(31 => 1                  ),
     32 => Accumulator( 2 => 5                  ),
     33 => Accumulator( 3 => 1, 11 => 1         ),
     34 => Accumulator( 2 => 1, 17 => 1         ),
     35 => Accumulator( 5 => 1,  7 => 1         ),
     36 => Accumulator( 2 => 2,  3 => 2         ),
     37 => Accumulator(37 => 1                  ),
     38 => Accumulator( 2 => 1, 19 => 1         ),
     39 => Accumulator( 3 => 1, 13 => 1         ),
     40 => Accumulator( 2 => 3,  5 => 1         ),
     41 => Accumulator(41 => 1                  ),
     42 => Accumulator( 2 => 1,  3 => 1,  7 => 1),
     43 => Accumulator(43 => 1                  ),
     44 => Accumulator( 2 => 2, 11 => 1         ),
     45 => Accumulator( 3 => 2,  5 => 1         ),
     46 => Accumulator( 2 => 1, 23 => 1         ),
     47 => Accumulator(47 => 1                  ),
     48 => Accumulator( 2 => 4,  3 => 1         ),
     49 => Accumulator( 7 => 2                  ),
     50 => Accumulator( 2 => 1,  5 => 2         ),
     51 => Accumulator( 3 => 1, 17 => 1         ),
     52 => Accumulator( 2 => 2, 13 => 1         ),
     53 => Accumulator(53 => 1                  ),
     54 => Accumulator( 2 => 1,  3 => 3         ),
     55 => Accumulator( 5 => 1, 11 => 1         ),
     56 => Accumulator( 2 => 3,  7 => 1         ),
     57 => Accumulator( 3 => 1, 19 => 1         ),
     58 => Accumulator( 2 => 1, 29 => 1         ),
     59 => Accumulator(59 => 1                  ),
     60 => Accumulator( 2 => 2,  3 => 1,  5 => 1),
     61 => Accumulator(61 => 1                  ),
     62 => Accumulator( 2 => 1, 31 => 1         ),
     63 => Accumulator( 3 => 2,  7 => 1         ),
     64 => Accumulator( 2 => 6                  ),
     65 => Accumulator( 5 => 1, 13 => 1         ),
     66 => Accumulator( 2 => 1,  3 => 1, 11 => 1),
     67 => Accumulator(67 => 1                  ),
     68 => Accumulator( 2 => 2, 17 => 1         ),
     69 => Accumulator( 3 => 1, 23 => 1         ),
     70 => Accumulator( 2 => 1,  5 => 1,  7 => 1),
     71 => Accumulator(71 => 1                  ),
     72 => Accumulator( 2 => 3,  3 => 2         ),
     73 => Accumulator(73 => 1                  ),
     74 => Accumulator( 2 => 1, 37 => 1         ),
     75 => Accumulator( 3 => 1,  5 => 2         ),
     76 => Accumulator( 2 => 2, 19 => 1         ),
     77 => Accumulator( 7 => 1, 11 => 1         ),
     78 => Accumulator( 2 => 1,  3 => 1, 13 => 1),
     79 => Accumulator(79 => 1                  ),
     80 => Accumulator( 2 => 4,  5 => 1         ),
     81 => Accumulator( 3 => 4                  ),
     82 => Accumulator( 2 => 1, 41 => 1         ),
     83 => Accumulator(83 => 1                  ),
     84 => Accumulator( 2 => 2,  3 => 1,  7 => 1),
     85 => Accumulator( 5 => 1, 17 => 1         ),
     86 => Accumulator( 2 => 1, 43 => 1         ),
     87 => Accumulator( 3 => 1, 29 => 1         ),
     88 => Accumulator( 2 => 3, 11 => 1         ),
     89 => Accumulator(89 => 1                  ),
     90 => Accumulator( 2 => 1,  3 => 2,  5 => 1),
     91 => Accumulator( 7 => 1, 13 => 1         ),
     92 => Accumulator( 2 => 2, 23 => 1         ),
     93 => Accumulator( 3 => 1, 31 => 1         ),
     94 => Accumulator( 2 => 1, 47 => 1         ),
     95 => Accumulator( 5 => 1, 19 => 1         ),
     96 => Accumulator( 2 => 5,  3 => 1         ),
     97 => Accumulator(97 => 1                  ),
     98 => Accumulator( 2 => 1,  7 => 2         ),
     99 => Accumulator( 3 => 2, 11 => 1         ),
    100 => Accumulator( 2 => 2,  5 => 2         ),
)

# Run the tests.
@testset "FRACTRAN.jl" begin
    # Test the code quality.
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(FRACTRAN)
    end

    # Lint the code.
    @testset "Code linting (JET.jl)" begin
        JET.test_package(FRACTRAN, target_modules=(FRACTRAN,))
    end

    # Test FRACTRAN's prime number generation algorithm.
    @testset "Prime number generation" begin
        # Test all prime numbers below 200 by value, first with an
        # explicit start number, then with an implicit one, using the
        # default value of `2`.
        @test generate_primes(3, 5) == [3, 5]
        @test generate_primes(200) == PRIMES

        # Test all prime numbers below 1 million by count. These are
        # 78,498, see https://www.mathematical.com/primes0to1000k.html.
        @test length(generate_primes(1_000_000)) == 78_498

        # Test invalid start numbers.
        @test_throws ArgumentError generate_primes(1, 10)
        @test_throws "`min_n` must be `≥2`." generate_primes(1, 10)

        @test_throws ArgumentError generate_primes(4, 10)
        @test_throws "`min_n` must be odd." generate_primes(4, 10)
    end

    # Test FRACTRAN's factorization algorithm.
    @testset "Factorization" begin
        # Test the module-level `FRACTRAN.factorizations` and
        # `FRACTRAN.primes` caches by poisoning them with wrong values
        # and circumventing the prime number generation in `factorize!`.
        # Then, reset the caches for the subsequent tests.
        FRACTRAN.factorizations = Dict(42 => Accumulator(5 => 1))
        FRACTRAN.primes = Int64[]
        @test ==(
            factorize!(FRACTRAN.factorizations, FRACTRAN.primes, 42),
            Accumulator(5 => 1),
        )

        FRACTRAN.factorizations = Dict()
        FRACTRAN.primes = [5, 9]
        @test ==(
            factorize!(FRACTRAN.factorizations, FRACTRAN.primes, 45),
            Accumulator(5 => 1, 9 => 1),
        )

        FRACTRAN.factorizations = Dict()
        FRACTRAN.primes = Int64[]

        # Test all factorizations up to 100 by value, first without,
        # then with the module-level caches.  Assure that the caches are
        # populated by testing their values, afterwards, and reset them.
        @testset "Factorization of $i without cache" for i in 1:100
            @test factorize(i) == FACTORIZATIONS[i]
        end

        @testset "Factorization of $i with cache" for i in 1:100
            @test ==(
                factorize!(FRACTRAN.factorizations, FRACTRAN.primes, i),
                FACTORIZATIONS[i],
            )
        end

        @test FRACTRAN.factorizations == FACTORIZATIONS
        @test FRACTRAN.primes == filter(<(ceil(Int64, sqrt(100))), PRIMES)

        FRACTRAN.factorizations = Dict()
        FRACTRAN.primes = Int64[]

        # Test invalid numbers.
        @test_throws ArgumentError factorize(-1)
        @test_throws "`n` must be `≥1`." factorize(-1)

        @test_throws ArgumentError factorize(0)
        @test_throws "`n` must be `≥1`." factorize(0)
    end
end
