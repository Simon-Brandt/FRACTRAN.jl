#!/usr/bin/env julia

# Author: Simon Brandt
# E-Mail: simon.brandt@uni-greifswald.de
# Last Modification: 2026-08-18

using DataStructures

function _isinteger(c::Accumulator{Int64, Int64})::Bool
    # Return whether the counter c's value (exponent) is positive for
    # all keys (bases).  Then, the represented number is also positive,
    # since fractions have negative exponents.
    return all(exponent >= 0 for exponent in values(c))
end

function generate_primes(max_n::Int64)::Vector{Int64}
    generate_primes(Int64(2), max_n)
end

function generate_primes(min_n::Int64, max_n::Int64)::Vector{Int64}
    # Compute the prime numbers from min_n to max_n, inclusive.

    # Check that min_n is greater than 1 and odd, or convert it to
    # fulfill this.
    primes = Int64[]
    if min_n <= 2
        min_n = 3
        primes = [2, 3]
    elseif min_n == 3
        primes = [3]
    elseif iseven(min_n)
        min_n = min_n + 1
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
        is_divisible = dividend % 2 == 0
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

function factorize(n::Int64)::Accumulator{Int64, Int64}
    # If the factorization has already been computed for n, return this
    # immediately.
    global factorizations
    n in keys(factorizations) && return factorizations[n]

    # Get all prime numbers yet computed and possibly compute all
    # following ones between the highest computed prime number (plus 2,
    # as the next integer would be even) and the square root of n.
    # These form the divisors to check in the trial division.
    global primes
    if primes[end] < ceil(Int64, sqrt(n))
        push!(
            primes,
            generate_primes(primes[end] + 2, ceil(Int64, sqrt(n)))...,
        )
    end

    # Successively divide the number n by all prime numbers, as often as
    # possible.
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
    factors = counter(factors)
    factorizations[n] = factors
    return factors
end

function prettyprint_factorization(factors::Accumulator{Int64, Int64})
    # Print the factorization in the canonical, condensed way.
    prettified_factors = String[]
    for (base, exponent) in sort(collect(factors))
        if exponent == 1
            exponent = ""
        else
            exponent = string(exponent)
            exponent = replace(
                exponent,
                "0" => "⁰",
                "1" => "¹",
                "2" => "²",
                "3" => "³",
                "4" => "⁴",
                "5" => "⁵",
                "6" => "⁶",
                "7" => "⁷",
                "8" => "⁸",
                "9" => "⁹",
            )
        end
        push!(prettified_factors, "$base$exponent")
    end
    println(join(prettified_factors, "⋅"))
end

function fractran(
    n::Int64,
    fractions::Rational{Int64}...;
    return_first::Bool = false,
)::Int64
    # Factorize n and each fraction for more efficient operation on the
    # implicitly represented powers with a much lower risk ov integer
    # overflow.
    n = factorize(n)
    fraction_powers = NTuple{2, Accumulator{Int64, Int64}}[]
    for fractions in fractions
        push!(
            fraction_powers,
            (
                factorize(numerator(fractions)),
                factorize(denominator(fractions)),
            ),
        )
    end

    # For each fraction, multiply n by it until the product is an
    # integer, then continue with this product and start anew, until no
    # product with any fraction yields an integer.  The last integer
    # product is the result of the FRACTRAN algorithm.
    i = 1
    while i <= length(fraction_powers)
        # Perform the equivalent operation to
        # "result = n * fractions[i]" for non-factorized numbers, i.e.,
        # add each exponent of the numerator to the respective base of
        # the result, and subtract each exponent of the denominator from
        # the respective base, effectively multiplying n with the
        # numerator and dividing it by the denominator.
        result = copy(n)
        for (base, exponent) in fraction_powers[i][begin]  # Numerator.
            result[base] += exponent
        end
        for (base, exponent) in fraction_powers[i][end]  # Denominator.
            result[base] -= exponent
        end

        i += 1

        if _isinteger(result)
            i = 1
            n = result

            if return_first
                # Invert the factorization to yield an integer as
                # result.
                n = prod(base ^ exponent for (base, exponent) in n)
                return n
            end
        end
    end

    # Invert the factorization to yield an integer as result.
    n = prod(base ^ exponent for (base, exponent) in n)
    return n
end

function add(a::Int64, b::Int64)::Int64
    # Add a and b using the following FRACTRAN program:
    # Start value:  n = 2^a * 3^b
    # Fractions:    3//2
    # Result:       3^(a+b)
    n = 2^a * 3^b
    fractions = (3//2,)
    result = factorize(fractran(n, fractions...))
    result = Tuple(values(result))[begin]
    return result
end

function sub(a::Int64, b::Int64)::Int64
    # Subtract a and b using the following FRACTRAN program:
    # Start value:  n = 2^a * 3^b
    # Fractions:    1//6
    # Result:       2 ^ (a-b)
    n = 2^a * 3^b
    fractions = (1//6,)
    result = factorize(fractran(n, fractions...))
    result = Tuple(values(result))[begin]
    return result
end

function mul(a::Int64, b::Int64)::Int64
    # Multiply a and b using the following FRACTRAN program:
    # Start value:  n = 2^a * 3^b
    # Fractions:    455//33, 11//13, 1//11, 3//7, 11//2, 1//3
    # Result:       5 ^ (a*b)
    n = 2^a * 3^b
    fractions = (455//33, 11//13, 1//11, 3//7, 11//2, 1//3)
    result = factorize(fractran(n, fractions...))
    result = Tuple(values(result))[begin]
    return result
end

function div(n::Int64, d::Int64)
    # Divide n (numerator) by d (denominator) using the following
    # FRACTRAN program:
    # Start value:  n = 2^n * 3^d * 11
    # Fractions:    91//66, 11//13, 1//33, 85//11, 57//119, 17//19,
    #               11//17, 1//3
    # Result:       5^q * 7^r
    n = 2^n * 3^d * 11
    fractions = (91//66, 11//13, 1//33, 85//11, 57//119, 17//19, 11//17, 1//3)
    result = factorize(fractran(n, fractions...))
    result = Tuple(values(result))
    if length(result) == 1
        result = result[1]
    else
        # result = "$(result[1]) + $(result[2])//$d"
        result = result[1] + result[2] // d
    end
    return result
end

function primegame(max_iterations::Int64 = 100)::Vector{Int64}
    # Find prime numbers using the following FRACTRAN program:
    # Start value:  n = 2^n * 7^m, here n = 2
    # Fractions:    17//91, 78//85, 19//51, 23//38, 29//33, 77//29,
    #               95//23, 77//19, 1//17, 11//13, 13//11, 15//2, 1//7,
    #               55//1
    # Result:       2^a * 7^b, a prime number if b == 0
    n = 2
    fractions = (
        17//91, 78//85, 19//51, 23//38, 29//33, 77//29, 95//23, 77//19, 1//17,
        11//13, 13//11, 15//2, 1//7, 55//1
    )
    results = [n]
    for i in 1:max_iterations
        print("\r", "Performing PRIMEGAME iteration #$i... ")
        result = fractran(n, fractions..., return_first=true)
        push!(results, result)
        n = result
    end
    println()

    primes = Int64[]
    for result in results
        result = factorize(result)
        if (
            result[2] > 1
            && all(result[i] == 0 for i in keys(result) if i != 2)
        )
            push!(primes, result[2])
        end
    end
    return primes
end

primes = generate_primes(10)
factorizations = Dict{Int64, Accumulator{Int64, Int64}}()
prettyprint_factorization(factorize(26520))

# add(4, 3)
# sub(7, 2)
# mul(2, 4)
# div(9, 3)
# primegame()
