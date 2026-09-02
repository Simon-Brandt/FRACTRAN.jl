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
# Last Modification: 2026-09-02

module FRACTRAN

export factorize, factorize!, fractran, generate_primes, prettify_factorization

public add, sub, mul, divrem, primegame, factorizations, primes

using DataStructures

function _isinteger(c::Accumulator{Int64, Int64})::Bool
    # Return whether the counter `c`'s value (exponent) is positive for
    # all keys (bases).  Then, the represented number is also positive,
    # since fractions would have negative exponents.
    return all(exponent >= 0 for exponent in values(c))
end

"""
    generate_primes(min_n::Int64, max_n::Int64)::Vector{Int64}
    generate_primes(max_n::Int64)::Vector{Int64}

Compute the prime numbers from `min_n` to `max_n`, inclusive.  The
second form defaults to `min_n = 2`.
"""
function generate_primes(min_n::Int64, max_n::Int64)::Vector{Int64}
    # Check that `min_n` is greater than 1 and odd, or throw an error.
    min_n >= 2 || throw(ArgumentError("`min_n` must be `≥2`."))
    min_n == 2 || isodd(min_n) || throw(ArgumentError("`min_n` must be odd."))

    if min_n == 2
        min_n = 3
        primes = [2]
    else
        primes = Int64[]
    end

    # Set all odd integers as dividends to check in the trial division.
    dividends = min_n:2:max_n

    # Successively divide each dividend by all odd divisors up to, and
    # including, the next-greater integer to the dividend's square root.
    # As soon as a division is possible, i.e., the dividend is divisible
    # by the divisor, it is decided that the dividend isn't prime.  If
    # all divisors have been exhausted to no avail, the dividend must be
    # prime, so add it to the list.
    for dividend in dividends
        is_divisible = false
        divisors = range(3, ceil(Int64, sqrt(dividend)), step=2)

        for divisor in divisors
            if dividend % divisor == 0
                is_divisible = true
                break
            end
        end

        !is_divisible && push!(primes, dividend)
    end

    return primes
end

generate_primes(max_n::Int64)::Vector{Int64} = generate_primes(2, max_n)

"""
    factorize(n::Int64)::Accumulator{Int64, Int64}

Factorize `n` to prime factors.  This yields an `Accumulator` mapping
the factors' bases to their exponents (counts).  See
[`factorize!`](@ref) for performance implications.
"""
function factorize(n::Int64)::Accumulator{Int64, Int64}
    factorizations = Dict{Int64, Accumulator{Int64, Int64}}()
    primes = Int64[]
    factorize!(factorizations, primes, n)
end

"""
    factorize!(
        factorizations::Dict{Int64, Accumulator{Int64, Int64}},
        primes::Vector{Int64},
        n::Int64,
    )::Accumulator{Int64, Int64}

Factorize `n` to prime factors.  This yields an `Accumulator` mapping
the factors' bases to their exponents (counts).

Unlike the non-mutating [`factorize`](@ref), `factorize!` takes cache
arguments of pre-computed `factorizations` and `primes` and mutates them
**in-place**, thus updating the cache for future usage.  When needing to
call `factorize` repeatedly, it is thus more efficient to call
`factorize!` instead and pass shared `factorizations` and `primes`.  To
this end, `FRACTRAN.jl` provides two module-level cache variables,
`FRACTRAN.factorizations` and `FRACTRAN.primes`, which you can use as
storage targets.  Note that this is **not** thread-safe.
"""
function factorize!(
    factorizations::Dict{Int64, Accumulator{Int64, Int64}},
    primes::Vector{Int64},
    n::Int64,
)::Accumulator{Int64, Int64}
    # Check that `n` is positive, or throw an error.
    n >= 1 || throw(ArgumentError("`n` must be `≥1`."))

    # If the factorization has already been computed for `n`, return
    # this (cached) value immediately.
    n in keys(factorizations) && return factorizations[n]

    # Compute all prime numbers between the highest computed prime
    # number (plus 2, as the next integer would be even) and the square
    # root of `n`, if needed.  These form the divisors to check in the
    # trial division.
    max_divisor = ceil(Int64, sqrt(n))
    if isempty(primes)
        push!(primes, generate_primes(2, max_divisor)...)
    elseif primes[end] < max_divisor
        if primes[end] == 2
            push!(primes, generate_primes(3, max_divisor)...)
        else
            push!(primes, generate_primes(primes[end] + 2, max_divisor)...)
        end
    end

    # Successively divide the number `n` by all prime numbers, as often
    # as possible.
    new_n = n
    factors = Int64[]
    for divisor in primes
        while new_n % divisor == 0
            push!(factors, divisor)
            new_n ÷= divisor
        end
    end

    new_n > 1 && push!(factors, new_n)

    # Count the number of occurrences of each prime factor and return
    # this as mapping.
    factor_counts = counter(factors)
    factorizations[n] = factor_counts
    return factor_counts
end

"""
    prettify_factorization(
        factors::Accumulator{Int64, Int64};
        explicit_one::Bool = false,
        verbose::Bool = false,
    )::String

Stringify the `factors`' factorization in the canonical, condensed way.

If `explicit_one` is `true` (default: `false`), also print exponents of
one (`1`), as `¹`.  If `verbose` is `true` (default: `false`), expand
the exponents to individual factors.  In this case, `explicit_one` has
no effect.
"""
function prettify_factorization(
    factors::Accumulator{Int64, Int64};
    explicit_one::Bool = false,
    verbose::Bool = false,
)::String
    prettified_factors = String[]
    for (base, exponent) in sort(collect(factors))
        formatted_base = string(base)

        if verbose
            for _ in 1:exponent
                push!(prettified_factors, formatted_base)
            end
        elseif exponent == 1 && !explicit_one
            push!(prettified_factors, formatted_base)
        else
            formatted_exponent = replace(
                string(exponent),
                '0' => '⁰',
                '1' => '¹',
                '2' => '²',
                '3' => '³',
                '4' => '⁴',
                '5' => '⁵',
                '6' => '⁶',
                '7' => '⁷',
                '8' => '⁸',
                '9' => '⁹',
            )
            push!(prettified_factors, formatted_base * formatted_exponent)
        end
    end

    return join(prettified_factors, "⋅")
end

"""
    fractran(
        n::Int64,
        fractions::Rational{Int64}...;
        return_first::Bool = false,
    )::Int64

    fractran(
        n::Int64,
        fractions::Tuple{Vararg{Rational{Int64}}};
        return_first::Bool = false,
    )::Int64

Run the FRACTRAN algorithm on the start value `n` using the `fractions`.
*Iff* `return_first` is `true`, return the first obtained integer.
Else, run the algorithm until no fraction yields an integer and return
the last integer.  This is the FRACTRAN algorithm's actual
result—`return_first` is needed by some specific programs like PRIMEGAME
that filter the FRACTRAN integers.
"""
function fractran(
    n::Int64,
    fractions::Rational{Int64}...;
    return_first::Bool = false,
)::Int64
    # Factorize `n` and each `fraction` for more efficient operation on
    # the implicitly represented powers with a much lower risk of
    # integer overflow.
    factors = factorize(n)
    fraction_powers = [
        (factorize(numerator(fraction)), factorize(denominator(fraction)))
        for fraction in fractions
    ]

    # For each `fraction`, multiply `n` by it until the product is an
    # integer, then continue with this product and start anew, until no
    # product with any fraction yields an integer.  The last integer
    # product is the result of the FRACTRAN algorithm.
    i = 1
    result = copy(factors)
    while i <= length(fraction_powers)
        # Perform an operation equivalent to `result = n * fractions[i]`
        # for non-factorized numbers, i.e., add each exponent of the
        # numerator to the respective base of the result, and subtract
        # each exponent of the denominator from the respective base,
        # effectively multiplying `n` with the numerator and dividing it
        # by the denominator.
        result = copy(factors)
        for (base, exponent) in fraction_powers[i][1]  # Numerator.
            result[base] += exponent
        end
        for (base, exponent) in fraction_powers[i][2]  # Denominator.
            result[base] -= exponent
        end

        i += 1

        if _isinteger(result)
            i = 1
            factors = result
            return_first && break
        end
    end

    # Undo the factorization to yield an integer as result.
    return prod(base ^ exponent for (base, exponent) in factors)
end

function fractran(
    n::Int64,
    fractions::Tuple{Rational{Int64}, Vararg{Rational{Int64}}};
    return_first::Bool = false,
)::Int64
    fractran(n, fractions...; return_first)
end

"""
    add(a::Int64, b::Int64)::Int64

Add `b` to `a` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `3//2`
- Result:       `3^(a+b)`

Note: `add(a, b)` directly returns `a + b`, not `3^(a+b)`.
"""
function add(a::Int64, b::Int64)::Int64
    n = 2^a * 3^b
    fractions = (3//2,)
    return (
        fractran(n, fractions)
        |> factorize
        |> values
        |> only
    )
end

"""
    sub(a::Int64, b::Int64)::Int64

Subtract `b` from `a` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `1//6`
- Result:       `2^(a-b)`

Note: `sub(a, b)` directly returns `a - b`, not `2^(a-b)`.
"""
function sub(a::Int64, b::Int64)::Int64
    n = 2^a * 3^b
    fractions = (1//6,)
    factors = factorize(fractran(n, fractions))
    return if a == b
        0            # Empty product, as 2^(a-b) = 2^0 = 1 ⟹ factorize(1) = ∅.
    elseif a < b
        -factors[3]  # Incomplete subtraction of `b`'s exponent from `a`'s.
    else
        factors[2]   # Complete subtraction.
    end
end

"""
    mul(a::Int64, b::Int64)::Int64

Multiply `a` by `b` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `455//33`, `11//13`, `1//11`, `3//7`, `11//2`, `1//3`
- Result:       `5^(a*b)`

Note: `mul(a, b)` directly returns `a * b`, not `5^(a*b)`.
"""
function mul(a::Int64, b::Int64)::Int64
    n = 2^a * 3^b
    fractions = (455//33, 11//13, 1//11, 3//7, 11//2, 1//3)
    return (
        fractran(n, fractions)
        |> factorize
        |> values
        |> only
    )
end

"""
    divrem(a::Int64, b::Int64)::Tuple{Int64, Int64}

Divide `a` by `b` (as Euclidian division) using the following FRACTRAN
program:

- Start value:  `2^a * 3^b * 11`
- Fractions:    `91//66`, `11//13`, `1//33`, `85//11`, `57//119`,
                `17//19`, `11//17`, `1//3`
- Result:       `5^q * 7^r` (`q ≔ a ÷ b`: quotient, `r ≔ a % b`:
                remainder)

Note: `divrem(a, b)` directly returns `(q, r)`, i.e., `(a ÷ b, a % b)`,
not `5^q * 7^r`.
"""
function divrem(a::Int64, b::Int64)::Tuple{Int64, Int64}
    n = 2^a * 3^b * 11
    fractions = (91//66, 11//13, 1//33, 85//11, 57//119, 17//19, 11//17, 1//3)
    factors = factorize(fractran(n, fractions))
    return if 5 in keys(factors) && 7 in keys(factors)
        (factors[5], factors[7])  # Incomplete division with `q` and `r`.
    elseif 7 in keys(factors)
        (0, factors[7])           # Incomplete division with only `r`.
    else
        (factors[5], 0)           # Complete division with only `q`.
    end
end

"""
    primegame(max_iterations::Int64 = 100)::Vector{Int64}

Find all prime numbers that are reachable by running `max_iterations`
iterations of the algorithm using the following FRACTRAN program, called
"PRIMEGAME":

- Start value:  `n = 2` (in PRIMEGAME, more generally, `n = 2^a * 7^b`)
- Fractions:    `17//91`, `78//85`, `19//51`, `23//38`, `29//33`,
                `77//29`, `95//23`, `77//19`, `1//17`, `11//13`,
                `13//11`, `15//2`, `1//7`, `55//1`
- Result:       `2^c * 7^d`, with `c ≤ a` and `d ≤ b`, a prime number
                *iff* `d == 0`

Note: `primegame(n)` directly returns all prime numbers up to, and
including, `c`, not `2^c * 7^d`.  Also note that the PRIMEGAME algorithm
is very inefficient and may take a very long time even for small prime
numbers.
"""
function primegame(max_iterations::Int64 = 100)::Vector{Int64}
    n = 2
    fractions = (
        17//91, 78//85, 19//51, 23//38, 29//33, 77//29, 95//23, 77//19, 1//17,
        11//13, 13//11, 15//2, 1//7, 55//1
    )
    results = [n]

    for i in 1:max_iterations
        print("\r", "Performing PRIMEGAME iteration #$i...")
        result = fractran(n, fractions, return_first=true)
        push!(results, result)
        n = result
    end
    println()

    primes = Int64[]
    for result in results
        factors = factorize(result)
        if (
            factors[2] > 1
            && all(factors[i] == 0 for i in keys(factors) if i != 2)
        )
            push!(primes, factors[2])
        end
    end

    return primes
end

"""
Module-level cache for yet computed factorizations, for optional usage
in [`factorize!`](@ref).
"""
factorizations::Dict{Int64, Accumulator{Int64, Int64}} =
    Dict{Int64, Accumulator{Int64, Int64}}()

"""
Module-level cache for yet computed prime numbers, for optional usage in
[`factorize!`](@ref).
"""
primes::Vector{Int64} = Int64[]

end  # module
