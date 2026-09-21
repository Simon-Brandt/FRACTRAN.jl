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
# Last Modification: 2026-09-21

using Markdown: Markdown, @md_str
using Test: @test, @testset, @test_throws

using Aqua: Aqua
using DataStructures: Accumulator
using Documenter: Documenter
using JET: JET

using FRACTRAN

# Define the data types to test, the prime numbers from 1 to 200, and
# the factorizations of 1 to 100 (including their prettified versions)
# as global constants for repeated usage in the tests.
const TYPES = (
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    UInt128,
    Int8,
    Int16,
    Int32,
    Int64,
    Int128,
)

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

const PRETTIFIED_FACTORIZATIONS = Dict(
    # The factorization for `1` is the empty product, see
    # https://math.stackexchange.com/a/47161.
      1 => (""         , ""           ),
      2 => ("2¹"       , "2"          ),
      3 => ("3¹"       , "3"          ),
      4 => ("2²"       , "2⋅2"        ),
      5 => ("5¹"       , "5"          ),
      6 => ("2¹⋅3¹"    , "2⋅3"        ),
      7 => ("7¹"       , "7"          ),
      8 => ("2³"       , "2⋅2⋅2"      ),
      9 => ("3²"       , "3⋅3"        ),
     10 => ("2¹⋅5¹"    , "2⋅5"        ),
     11 => ("11¹"      , "11"         ),
     12 => ("2²⋅3¹"    , "2⋅2⋅3"      ),
     13 => ("13¹"      , "13"         ),
     14 => ("2¹⋅7¹"    , "2⋅7"        ),
     15 => ("3¹⋅5¹"    , "3⋅5"        ),
     16 => ("2⁴"       , "2⋅2⋅2⋅2"    ),
     17 => ("17¹"      , "17"         ),
     18 => ("2¹⋅3²"    , "2⋅3⋅3"      ),
     19 => ("19¹"      , "19"         ),
     20 => ("2²⋅5¹"    , "2⋅2⋅5"      ),
     21 => ("3¹⋅7¹"    , "3⋅7"        ),
     22 => ("2¹⋅11¹"   , "2⋅11"       ),
     23 => ("23¹"      , "23"         ),
     24 => ("2³⋅3¹"    , "2⋅2⋅2⋅3"    ),
     25 => ("5²"       , "5⋅5"        ),
     26 => ("2¹⋅13¹"   , "2⋅13"       ),
     27 => ("3³"       , "3⋅3⋅3"      ),
     28 => ("2²⋅7¹"    , "2⋅2⋅7"      ),
     29 => ("29¹"      , "29"         ),
     30 => ("2¹⋅3¹⋅5¹" , "2⋅3⋅5"      ),
     31 => ("31¹"      , "31"         ),
     32 => ("2⁵"       , "2⋅2⋅2⋅2⋅2"  ),
     33 => ("3¹⋅11¹"   , "3⋅11"       ),
     34 => ("2¹⋅17¹"   , "2⋅17"       ),
     35 => ("5¹⋅7¹"    , "5⋅7"        ),
     36 => ("2²⋅3²"    , "2⋅2⋅3⋅3"    ),
     37 => ("37¹"      , "37"         ),
     38 => ("2¹⋅19¹"   , "2⋅19"       ),
     39 => ("3¹⋅13¹"   , "3⋅13"       ),
     40 => ("2³⋅5¹"    , "2⋅2⋅2⋅5"    ),
     41 => ("41¹"      , "41"         ),
     42 => ("2¹⋅3¹⋅7¹" , "2⋅3⋅7"      ),
     43 => ("43¹"      , "43"         ),
     44 => ("2²⋅11¹"   , "2⋅2⋅11"     ),
     45 => ("3²⋅5¹"    , "3⋅3⋅5"      ),
     46 => ("2¹⋅23¹"   , "2⋅23"       ),
     47 => ("47¹"      , "47"         ),
     48 => ("2⁴⋅3¹"    , "2⋅2⋅2⋅2⋅3"  ),
     49 => ("7²"       , "7⋅7"        ),
     50 => ("2¹⋅5²"    , "2⋅5⋅5"      ),
     51 => ("3¹⋅17¹"   , "3⋅17"       ),
     52 => ("2²⋅13¹"   , "2⋅2⋅13"     ),
     53 => ("53¹"      , "53"         ),
     54 => ("2¹⋅3³"    , "2⋅3⋅3⋅3"    ),
     55 => ("5¹⋅11¹"   , "5⋅11"       ),
     56 => ("2³⋅7¹"    , "2⋅2⋅2⋅7"    ),
     57 => ("3¹⋅19¹"   , "3⋅19"       ),
     58 => ("2¹⋅29¹"   , "2⋅29"       ),
     59 => ("59¹"      , "59"         ),
     60 => ("2²⋅3¹⋅5¹" , "2⋅2⋅3⋅5"    ),
     61 => ("61¹"      , "61"         ),
     62 => ("2¹⋅31¹"   , "2⋅31"       ),
     63 => ("3²⋅7¹"    , "3⋅3⋅7"      ),
     64 => ("2⁶"       , "2⋅2⋅2⋅2⋅2⋅2"),
     65 => ("5¹⋅13¹"   , "5⋅13"       ),
     66 => ("2¹⋅3¹⋅11¹", "2⋅3⋅11"     ),
     67 => ("67¹"      , "67"         ),
     68 => ("2²⋅17¹"   , "2⋅2⋅17"     ),
     69 => ("3¹⋅23¹"   , "3⋅23"       ),
     70 => ("2¹⋅5¹⋅7¹" , "2⋅5⋅7"      ),
     71 => ("71¹"      , "71"         ),
     72 => ("2³⋅3²"    , "2⋅2⋅2⋅3⋅3"  ),
     73 => ("73¹"      , "73"         ),
     74 => ("2¹⋅37¹"   , "2⋅37"       ),
     75 => ("3¹⋅5²"    , "3⋅5⋅5"      ),
     76 => ("2²⋅19¹"   , "2⋅2⋅19"     ),
     77 => ("7¹⋅11¹"   , "7⋅11"       ),
     78 => ("2¹⋅3¹⋅13¹", "2⋅3⋅13"     ),
     79 => ("79¹"      , "79"         ),
     80 => ("2⁴⋅5¹"    , "2⋅2⋅2⋅2⋅5"  ),
     81 => ("3⁴"       , "3⋅3⋅3⋅3"    ),
     82 => ("2¹⋅41¹"   , "2⋅41"       ),
     83 => ("83¹"      , "83"         ),
     84 => ("2²⋅3¹⋅7¹" , "2⋅2⋅3⋅7"    ),
     85 => ("5¹⋅17¹"   , "5⋅17"       ),
     86 => ("2¹⋅43¹"   , "2⋅43"       ),
     87 => ("3¹⋅29¹"   , "3⋅29"       ),
     88 => ("2³⋅11¹"   , "2⋅2⋅2⋅11"   ),
     89 => ("89¹"      , "89"         ),
     90 => ("2¹⋅3²⋅5¹" , "2⋅3⋅3⋅5"    ),
     91 => ("7¹⋅13¹"   , "7⋅13"       ),
     92 => ("2²⋅23¹"   , "2⋅2⋅23"     ),
     93 => ("3¹⋅31¹"   , "3⋅31"       ),
     94 => ("2¹⋅47¹"   , "2⋅47"       ),
     95 => ("5¹⋅19¹"   , "5⋅19"       ),
     96 => ("2⁵⋅3¹"    , "2⋅2⋅2⋅2⋅2⋅3"),
     97 => ("97¹"      , "97"         ),
     98 => ("2¹⋅7²"    , "2⋅7⋅7"      ),
     99 => ("3²⋅11¹"   , "3⋅3⋅11"     ),
    100 => ("2²⋅5²"    , "2⋅2⋅5⋅5"    ),
)

# Define the internal function to stringify a Markdown-formatted error
# message for `@test_throws`.
_to_str(msg::Markdown.MD)::String = sprint(show, MIME"text/plain"(), msg)

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

    # Test the prime number generation algorithm.
    @testset "Prime number generation" begin
        # Test all prime numbers below 200 by value, first with an
        # explicit start number, then with an implicit one, using the
        # default value of `2`.  Then, test all prime numbers below 1
        # million by count.  These are 78,498, see
        # https://www.mathematical.com/primes0to1000k.html.
        @testset "Values" begin
            @test generate_primes(3, 5) == [3, 5]
            @test generate_primes(200) == PRIMES
            @test length(generate_primes(1_000_000)) == 78_498
        end

        # Test different argument types.
        @testset "Argument type `$T`" for T in TYPES
            @test generate_primes(T(2), T(100)) == filter(<(100), PRIMES)
            @test generate_primes(T(100)) == filter(<(100), PRIMES)
        end

        # Test invalid start and end numbers.
        @testset "Invalid `min_n`" begin
            @test_throws FRACTRAN._MDError generate_primes(1, 10)
            @test_throws _to_str(md"`min_n` must be `≥ 2`.") generate_primes(1, 10)

            @test_throws FRACTRAN._MDError generate_primes(4, 10)
            @test_throws _to_str(md"`min_n` must be odd.") generate_primes(4, 10)

            @test_throws FRACTRAN._MDError generate_primes(big(typemax(Int)) + 1, 10)
            @test_throws _to_str(Markdown.parse(
                "`min_n` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) generate_primes(big(typemax(Int)) + 1, 10)
        end

        @testset "Invalid `max_n`" begin
            @test_throws FRACTRAN._MDError generate_primes(5, 3)
            @test_throws _to_str(md"`max_n` must be `≥ 5`.") generate_primes(5, 3)

            @test_throws FRACTRAN._MDError generate_primes(2, big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`max_n` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) generate_primes(2, big(typemax(Int)) + 1)
        end
    end

    # Test the factorization algorithm.
    @testset "Factorization" begin
        # Test the module-level caches `FRACTRAN.factorizations` and
        # `FRACTRAN.primes` by poisoning them with wrong values and
        # circumventing the prime number generation in `factorize!`.
        # Then, reset the caches for the subsequent tests.
        @testset "Cache usage" begin
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
        end

        # Test all factorizations up to 100 by value, first without,
        # then with the module-level caches.  Assure that the caches are
        # populated by testing their values, afterwards, and reset them.
        @testset "$i without cache" for i in 1:100
            @test factorize(i) == FACTORIZATIONS[i]
        end

        @testset "$i with cache" for i in 1:100
            @test ==(
                factorize!(FRACTRAN.factorizations, FRACTRAN.primes, i),
                FACTORIZATIONS[i],
            )
        end

        @testset "Cache population`" begin
            @test FRACTRAN.factorizations == FACTORIZATIONS
            @test FRACTRAN.primes == filter(<(ceil(Int64, sqrt(100))), PRIMES)

            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test different argument types.
        @testset "Argument type `$T`" for T in TYPES
            for i in 1:100
                @test factorize(T(i)) == FACTORIZATIONS[i]
            end
        end

        # Test invalid numbers.
        @testset "Invalid `n`" begin
            @test_throws FRACTRAN._MDError factorize(-1)
            @test_throws _to_str(md"`n` must be `≥ 1`.") factorize(-1)

            @test_throws FRACTRAN._MDError factorize(0)
            @test_throws _to_str(md"`n` must be `≥ 1`.") factorize(0)

            @test_throws FRACTRAN._MDError factorize(big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`n` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) factorize(big(typemax(Int)) + 1)
        end
    end

    # Test the factorization prettyprinting.
    @testset "Prettyprinting" begin
        # Test all factorizations up to 100, first with implicit, then
        # with explicit exponent-of-one printing.
        @testset "$i, compact, implicit `¹`" for i in 1:100
            @test ==(
                prettify_factorization(factorize(i)),
                replace(first(PRETTIFIED_FACTORIZATIONS[i]), '¹' => ""),
            )
        end

        @testset "$i, compact, explicit `¹`" for i in 1:100
            @test ==(
                prettify_factorization(factorize(i), explicit_one=true),
                first(PRETTIFIED_FACTORIZATIONS[i]),
            )
        end

        # Test all factorizations up to 100, first with implicit, then
        # with explicit exponent-of-one printing, in verbose form,
        # listing all factors individually.  There should not be any
        # difference between the implicit and the explicit form, since
        # no exponent should be printed.
        @testset "$i, verbose, implicit `¹`" for i in 1:100
            @test ==(
                prettify_factorization(factorize(i), verbose=true),
                last(PRETTIFIED_FACTORIZATIONS[i]),
            )
        end

        @testset "$i, verbose, explicit `¹`" for i in 1:100
            @test ==(
                prettify_factorization(
                    factorize(i),
                    explicit_one=true,
                    verbose=true,
                ),
                last(PRETTIFIED_FACTORIZATIONS[i]),
            )
        end

        # Test the first 20 powers of two with exponents greater than
        # `6` and multiple digits.
        @testset "Power of `2`: `2^$i`" for i in 1:20
            results = [
                "2",   "2²",  "2³",  "2⁴",  "2⁵",  "2⁶",  "2⁷",  "2⁸",  "2⁹",
                "2¹⁰", "2¹¹", "2¹²", "2¹³", "2¹⁴", "2¹⁵", "2¹⁶", "2¹⁷", "2¹⁸",
                "2¹⁹", "2²⁰",
            ]
            @test prettify_factorization(factorize(2^i)) == results[i]
        end

        # Test a highly composite number with many prime factors.
        @testset "Highly composite number" begin
            n = 2^5 * 3^2 * 5 * 7 * 11 * 13  # 1,441,440
            @test prettify_factorization(factorize(n)) == "2⁵⋅3²⋅5⋅7⋅11⋅13"
        end
    end

    # Test the FRACTRAN implementation.
    @testset "FRACTRAN" begin
        # Test the implementation using a simple addition program, a
        # slightly different one than in `FRACTRAN.add`, and without the
        # destructuring of the result into the actual sum (without the
        # power).  First, test the call form using `Vararg`s, then using
        # a `Tuple`.  Only test different argument types for `n` with
        # (`a`, `b`) combinations where `n = 3^a * 5^b` fits the type
        # `T`.  Else, use the default `Int` type.
        @testset "`Vararg`, argument type `$T`" for T in TYPES
            for a in 1:10, b in 1:10
                if 3^a * 5^b < typemax(T)
                    @test fractran(T(3^a * 5^b), T(5) // T(3)) == 5^(a+b)
                else
                    @test fractran(3^a * 5^b, T(5) // T(3)) == 5^(a+b)
                end
            end
        end

        @testset "`Tuple`, argument type `$T`" for T in TYPES
            for a in 1:10, b in 1:10
                if 3^a * 5^b < typemax(T)
                    @test fractran(T(3^a * 5^b), (T(5) // T(3),)) == 5^(a+b)
                else
                    @test fractran(3^a * 5^b, (T(5) // T(3),)) == 5^(a+b)
                end
            end
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                fractran(3^4 * 5^2, 5//3),
                fractran!(
                    FRACTRAN.factorizations,
                    FRACTRAN.primes,
                    3^4 * 5^2,
                    5//3,
                ),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test the step limit when running non-terminating programs
        # using the PRIMEGAME program.
        @testset "Step limit" begin
            n = 2
            fractions = (
                17//91, 78//85, 19//51, 23//38, 29//33, 77//29, 95//23, 77//19,
                1//17, 11//13, 13//11, 15//2, 1//7, 55//1,
            )

            @test_throws ErrorException fractran(n, fractions, max_steps=1000)
            @test_throws "Exceeded maximum FRACTRAN steps (1000).  Is your \
                program non-terminating?" fractran(n, fractions, max_steps=1000)
        end

        # Test the results' difference when returning the first integer
        # instead of the last using the PRIMEGAME program.  Since this
        # program is non-terminating, also pass a step limit to
        # `fractran`.
        @testset "First returned integer" begin
            n = 2
            fractions = (
                17//91, 78//85, 19//51, 23//38, 29//33, 77//29, 95//23, 77//19,
                1//17, 11//13, 13//11, 15//2, 1//7, 55//1,
            )

            @test !=(
                fractran(n, fractions, max_steps=1000, return_first=true),

                try
                    fractran(n, fractions, max_steps=1000, return_first=false)
                catch err
                    err isa ErrorException && 0
                end,
            )
        end

        # Test invalid start numbers, fractions, and maximum step
        # counts.  Note that Julia converts `Rational`s to their lowest
        # terms, possibly with negative numerators, not denominators, so
        # the test results may contain other fractions than input.  Also
        # note that `Rational`s with ``0`` as denominator are allowed
        # and can thus be tested.
        @testset "Invalid `n`" begin
            @test_throws FRACTRAN._MDError fractran(-1, 1//2)
            @test_throws _to_str(md"`n` must be `≥ 1`.") fractran(-1, 1//2)

            @test_throws FRACTRAN._MDError fractran(0, 1//2)
            @test_throws _to_str(md"`n` must be `≥ 1`.") fractran(0, 1//2)

            @test_throws FRACTRAN._MDError fractran(big(typemax(Int)) + 1, 1//2)
            @test_throws _to_str(Markdown.parse(
                "`n` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) fractran(big(typemax(Int)) + 1, 1//2)
        end

        @testset "Invalid numerator" begin
            @test_throws FRACTRAN._MDError fractran(1, -1//2)
            @test_throws _to_str(
                md"`numerator(fractions[1]) = numerator(-1//2)` must be `≥ 1`."
            ) fractran(1, -1//2)

            @test_throws FRACTRAN._MDError fractran(1, 0//1)
            @test_throws _to_str(
                md"`numerator(fractions[1]) = numerator(0//1)` must be `≥ 1`."
            ) fractran(1, 0//1)

            @test_throws FRACTRAN._MDError fractran(1, (big(typemax(Int)) + 1) // 1)
            @test_throws _to_str(Markdown.parse(
                "`numerator(fractions[1]) = numerator($(big(typemax(Int)) + 1)//1)` \
                must be `≤ typemax(Int)` (on your machine, `$(typemax(Int))`)."
            )) fractran(1, (big(typemax(Int)) + 1) // 1)
        end

        @testset "Invalid denominator" begin
            @test_throws FRACTRAN._MDError fractran(1, 1//-2)
            @test_throws _to_str(
                md"`numerator(fractions[1]) = numerator(-1//2)` must be `≥ 1`."
            ) fractran(1, 1//-2)

            @test_throws FRACTRAN._MDError fractran(1, 1//0)
            @test_throws _to_str(
                md"`denominator(fractions[1]) = denominator(1//0)` must be `≥ 1`."
            ) fractran(1, 1//0)

            @test_throws FRACTRAN._MDError fractran(1, 1 // (big(typemax(Int)) + 1))
            @test_throws _to_str(Markdown.parse(
                "`denominator(fractions[1]) = denominator(1//$(big(typemax(Int)) + 1))` \
                must be `≤ typemax(Int)` (on your machine, `$(typemax(Int))`)."
            )) fractran(1, 1 // (big(typemax(Int)) + 1))
        end

        @testset "Invalid `max_steps`" begin
            @test_throws FRACTRAN._MDError fractran(3^4 * 5^2, 5//3, max_steps=-1)
            @test_throws _to_str(md"`max_steps` must be `≥ 1`.") fractran(3^4 * 5^2, 5//3, max_steps=-1)

            @test_throws FRACTRAN._MDError fractran(3^4 * 5^2, 5//3, max_steps=0)
            @test_throws _to_str(md"`max_steps` must be `≥ 1`.") fractran(3^4 * 5^2, 5//3, max_steps=0)

            @test_throws FRACTRAN._MDError fractran(3^4 * 5^2, 5//3, max_steps=big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`max_steps` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) fractran(3^4 * 5^2, 5//3, max_steps=big(typemax(Int)) + 1)
        end
    end

    # Test the addition program.
    @testset "Addition program" begin
        # Test all possible sums from `1 + 1` to `10 + 10` with
        # different argument types.
        @testset "Argument type `$T`" for T in TYPES
            for a in 1:10, b in 1:10
                @test FRACTRAN.add(T(a), T(b)) == a + b
            end
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                FRACTRAN.add(4, 2),
                FRACTRAN.add!(FRACTRAN.factorizations, FRACTRAN.primes, 4, 2),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test invalid augends and addends, and the resulting FRACTRAN
        # start number.
        @testset "Invalid `a`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.add(-1, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.add(-1, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.add(0, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.add(0, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.add(big(typemax(Int)) + 1, 2)
            @test_throws _to_str(Markdown.parse(
                "`a` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.add(big(typemax(Int)) + 1, 2)
        end

        @testset "Invalid `b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.add(2, -1)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.add(2, -1)

            @test_throws FRACTRAN._MDError FRACTRAN.add(2, 0)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.add(2, 0)

            @test_throws FRACTRAN._MDError FRACTRAN.add(2, big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`b` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.add(2, big(typemax(Int)) + 1)
        end

        @testset "Invalid `n = 2^a * 3^b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.add(25, 25)
            @test_throws _to_str(Markdown.parse(
                "`a` and `b` must be small enough to fit the program's start \
                number: `n = 2^a * 3^b ≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.add(25, 25)
        end
    end

    # Test the subtraction program.
    @testset "Subtraction program" begin
        # Test all possible differences from `1 - 1` to `10 - 10` with
        # different argument types.
        @testset "Argument type `$T`" for T in TYPES
            for a in 1:10, b in 1:10
                @test FRACTRAN.sub(T(a), T(b)) == a - b
            end
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                FRACTRAN.sub(4, 2),
                FRACTRAN.sub!(FRACTRAN.factorizations, FRACTRAN.primes, 4, 2),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test invalid minuends and subtrahends, and the resulting
        # FRACTRAN start number.
        @testset "Invalid `a`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.sub(-1, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.sub(-1, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.sub(0, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.sub(0, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.sub(big(typemax(Int)) + 1, 2)
            @test_throws _to_str(Markdown.parse(
                "`a` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.sub(big(typemax(Int)) + 1, 2)
        end

        @testset "Invalid `b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.sub(2, -1)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.sub(2, -1)

            @test_throws FRACTRAN._MDError FRACTRAN.sub(2, 0)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.sub(2, 0)

            @test_throws FRACTRAN._MDError FRACTRAN.sub(2, big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`b` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.sub(2, big(typemax(Int)) + 1)
        end

        @testset "Invalid `n = 2^a * 3^b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.sub(25, 25)
            @test_throws _to_str(Markdown.parse(
                "`a` and `b` must be small enough to fit the program's start \
                number: `n = 2^a * 3^b ≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.sub(25, 25)
        end
    end

    # Test the multiplication program.
    @testset "Multiplication program" begin
        # Test all possible products from `1 ⋅ 1` to `4 ⋅ 5` with
        # different argument types.  Use only these small values as
        # otherwise, the prime number generation would take too long.
        @testset "Argument type `$T`" for T in TYPES
            for a in 1:4, b in 1:5
                @test FRACTRAN.mul(T(a), T(b)) == a * b
            end
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                FRACTRAN.mul(4, 2),
                FRACTRAN.mul!(FRACTRAN.factorizations, FRACTRAN.primes, 4, 2),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test invalid multipliers and multiplicands, and the resulting
        # FRACTRAN start number.
        @testset "Invalid `a`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.mul(-1, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.mul(-1, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.mul(0, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.mul(0, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.mul(big(typemax(Int)) + 1, 2)
            @test_throws _to_str(Markdown.parse(
                "`a` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.mul(big(typemax(Int)) + 1, 2)
        end

        @testset "Invalid `b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.mul(2, -1)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.mul(2, -1)

            @test_throws FRACTRAN._MDError FRACTRAN.mul(2, 0)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.mul(2, 0)

            @test_throws FRACTRAN._MDError FRACTRAN.mul(2, big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`b` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.mul(2, big(typemax(Int)) + 1)
        end

        @testset "Invalid `n = 2^a * 3^b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.mul(25, 25)
            @test_throws _to_str(Markdown.parse(
                "`a` and `b` must be small enough to fit the program's start \
                number: `n = 2^a * 3^b ≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.mul(25, 25)
        end
    end

    # Test the division program.
    @testset "Division program" begin
        # Test all possible quotients and remainders from
        # `(1 ÷ 1, 1 % 1)` to `(10 ÷ 10, 10 % 10)` with different
        # argument types.
        @testset "Argument type `$T`" for T in TYPES
            for a in 1:10, b in 1:10
                @test FRACTRAN.divrem(T(a), T(b)) == divrem(a, b)
            end
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                FRACTRAN.divrem(4, 2),
                FRACTRAN.divrem!(
                    FRACTRAN.factorizations,
                    FRACTRAN.primes,
                    4,
                    2,
                ),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test invalid dividends and divisors, and the resulting
        # FRACTRAN start number.
        @testset "Invalid `a`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.divrem(-1, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.divrem(-1, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.divrem(0, 2)
            @test_throws _to_str(md"`a` must be `≥ 1`.") FRACTRAN.divrem(0, 2)

            @test_throws FRACTRAN._MDError FRACTRAN.divrem(big(typemax(Int)) + 1, 2)
            @test_throws _to_str(Markdown.parse(
                "`a` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.divrem(big(typemax(Int)) + 1, 2)
        end

        @testset "Invalid `b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.divrem(2, -1)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.divrem(2, -1)

            @test_throws FRACTRAN._MDError FRACTRAN.divrem(2, 0)
            @test_throws _to_str(md"`b` must be `≥ 1`.") FRACTRAN.divrem(2, 0)

            @test_throws FRACTRAN._MDError FRACTRAN.divrem(2, big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`b` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.divrem(2, big(typemax(Int)) + 1)
        end

        @testset "Invalid `2^a * 3^b`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.divrem(25, 25)
            @test_throws _to_str(Markdown.parse(
                "`a` and `b` must be small enough to fit the program's start \
                number: `n = 2^a * 3^b ≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.divrem(25, 25)
        end
    end

    # Test the PRIMEGAME program.
    @testset "PRIMEGAME program" begin
        # Test the first few prime numbers by value.  Note that due to
        # the extremely high runtime of the PRIMEGAME algorithm, testing
        # more prime numbers would not be practical.
        @testset "Values" begin
            @test FRACTRAN.primegame() == filter(<=(3), PRIMES)
            @test FRACTRAN.primegame(100) == filter(<=(3), PRIMES)
            @test FRACTRAN.primegame(1000) == filter(<=(7), PRIMES)
        end

        # Test different argument types.
        @testset "Argument type `$T`" for T in TYPES
            @test FRACTRAN.primegame(T(100)) == filter(<=(3), PRIMES)
        end

        # Test the results' identity between the non-mutating and the
        # mutating versions of the function.
        @testset "Value identity with cache" begin
            @test ==(
                FRACTRAN.primegame(1000),
                FRACTRAN.primegame!(
                    FRACTRAN.factorizations,
                    FRACTRAN.primes,
                    1000,
                ),
            )
            FRACTRAN.factorizations = Dict()
            FRACTRAN.primes = Int64[]
        end

        # Test invalid maximum iterations.
        @testset "Invalid `max_iterations`" begin
            @test_throws FRACTRAN._MDError FRACTRAN.primegame(-1)
            @test_throws _to_str(md"`max_iterations` must be `≥ 1`.") FRACTRAN.primegame(-1)

            @test_throws FRACTRAN._MDError FRACTRAN.primegame(0)
            @test_throws _to_str(md"`max_iterations` must be `≥ 1`.") FRACTRAN.primegame(0)

            @test_throws FRACTRAN._MDError FRACTRAN.primegame(big(typemax(Int)) + 1)
            @test_throws _to_str(Markdown.parse(
                "`max_iterations` must be `≤ typemax(Int)` (on your machine, \
                `$(typemax(Int))`)."
            )) FRACTRAN.primegame(big(typemax(Int)) + 1)
        end
    end

    # Run the doctests, in Julia 1 versions starting from Julia 1.13, as
    # the hash algorithm has changed, there, and some doctests' results
    # rely on the ordering of `Dict`s (the data structure underlying
    # `DataStructures.Accumulator`).
    if v"1.13" <= VERSION < v"2-"
        Documenter.doctest(
            FRACTRAN,
            testset="Doctests (Documenter.jl)",
            manual=false,
            meta = Dict(:DocTestSetup => :(using FRACTRAN)),
        )
    end
end
