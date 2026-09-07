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
# Last Modification: 2026-09-07

"""
Julia implementation of the esoteric programming language FRACTRAN.

# Extended help

## Algorithm

[FRACTRAN](https://en.wikipedia.org/wiki/FRACTRAN) is an esoteric
programming language, based on fractions, that was developed by
[John Conway](https://en.wikipedia.org/wiki/John_Horton_Conway) in 1987.

The algorithm behind FRACTRAN works by taking a natural number ``n`` and
an ordered collection of fractions ``f``.  ``n`` gets multiplied by each
fraction ``fᵢ``, until the result ``n⋅fᵢ`` is an integer, i.e.,
``n⋅fᵢ ∈ ℕ``.  This integer gets multiplied again with the fractions,
starting from the first one, ``f₁``, until no product ``n⋅fᵢ`` leads an
integer, anymore.  The last obtained integer marks the result of the
FRACTRAN algorithm.

Generally, multiplying a natural number by a fraction, as required for
FRACTRAN, is equivalent to adding/subtracting exponents in the prime
factorization of the number and the fraction's numerator/denominator.
Thus, FRACTRAN can be considered an implementation of a register machine
whose registers are the prime factors, and whose stored values are the
factors' exponents.  Basically, the natural numbers, the products of
their factorizations, encode these registers' values by
[Gödel numbering](https://en.wikipedia.org/wiki/Gödel_numbering).

## Module contents

`FRACTRAN.jl` provides multiple functions to work with the FRACTRAN
algorithm: an implementation of the algorithm itself, several example
programs, and a prime number generator for factorizating the numbers for
FRACTRAN.  Thus, you might also use `FRACTRAN.jl` if you're working with
factorizations, but note that the implementation uses simple trial
division for finding prime numbers, with lesser performance than
optimized prime factorization algorithms.  This is sufficient for
FRACTRAN, since the language is slow by itself and thus only really
suitable as educational tool, but you may want to use more optimized
libraries if you're only needing a factorization algorithm.

The core of this module is formed by the [`fractran`](@ref) function,
which implements the FRACTRAN algorithm.  Since prime numbers are the
center of this algorithm, `FRACTRAN.jl` also includes a function to
generate a list of prime numbers, [`generate_primes`](@ref).  These
prime numbers are required for factorizing the numbers using the
[`factorize`](@ref) function—as needed for `fractran`.  There is also
the (internally unused) function [`prettify_factorization`](@ref) that
you might want to use to create a string representation of a
factorization for pretty-printing.

Further, `FRACTRAN.jl` provides a set of example functions implementing
some selected FRACTRAN programs: [`add`](@ref) adds two numbers,
[`sub`](@ref) subtracts them, [`mul`](@ref) multiplies them, and
[`divrem`](@ref) divides them with remainder.  Additionally, the
[`primegame`](@ref) function implements the perhaps most famous FRACTRAN
program, called "PRIMEGAME", which generates prime numbers.

Since the FRACTRAN algorithm is rather slow, especially PRIMEGAME,
`FRACTRAN.jl` also includes two module-level caches,
[`factorizations`](@ref) and [`primes`](@ref).  These caches may be used
for accelerating repeated `fractran` calls.  To this end, `factorize`,
`fractran`, and all example programs have a second form with exclamation
mark (like [`factorize!`](@ref), [`fractran!`](@ref) etc.), that take
caches as additional arguments for in-place mutation.  You may either
use the provided module-level caches or pass your own objects to them,
depending on the intended persistence of the caches.  Note that
internally, each invocation still uses cached values, even for the
function variants without exclamation marks, but these are re-computed
per call and only persistent for the internal sub-calls.

!!! note
    In order not to clutter your namespace upon `using FRACTRAN`, the
    caches and example programs are only declared as `public`, but not
    `export`ed.  You can access them by prefixing them with the module
    name, i.e., as `FRACTRAN.add` etc.

## Examples

### Manual addition program

```jldoctest
julia> using FRACTRAN

julia> n = 432;                # Start number: 2^4 * 3^3 (operands 4 and 3).

julia> fractions = (3//2,);    # FRACTRAN program for addition.

julia> fractran(n, fractions)  # FRACTRAN invocation.
2187

julia> factorize(ans)          # Get exponents, result is in register `3`.
DataStructures.Accumulator{Int64, Int64} with 1 entry:
  3 => 7
```

### `FRACTRAN.jl` example programs

```jldoctest
julia> FRACTRAN.add(4, 3)
7

julia> FRACTRAN.sub(4, 3)
1

julia> FRACTRAN.mul(4, 3)
12

julia> FRACTRAN.divrem(4, 3)
(1, 1)

julia> FRACTRAN.primegame(300)  # Number of FRACTRAN iterations.
3-element Vector{Int64}:
 2
 3
 5
```

### Prime number generation and factorization

```jldoctest
julia> generate_primes(2, 10)
4-element Vector{Int64}:
 2
 3
 5
 7

julia> factorize(120)
DataStructures.Accumulator{Int64, Int64} with 3 entries:
  5 => 1
  2 => 3
  3 => 1

julia> prettify_factorization(ans)
"2³⋅3⋅5"
```
"""
module FRACTRAN

export factorize, factorize!, fractran, fractran!
export generate_primes, prettify_factorization

public add, add!, sub, sub!, mul, mul!, divrem, divrem!, primegame, primegame!
public factorizations, primes

using Markdown: Markdown, @md_str

using DataStructures: DataStructures, Accumulator

struct _MDError <: Exception
    msg::Markdown.MD
end

function Base.showerror(io::IO, err::_MDError)
    print(io, "ArgumentError:")
    show(io, MIME"text/plain"(), err.msg)  # Adds two spaces before `msg`.
end

function _add_docstring_note_function(function_name::AbstractString)::String
    note = """
    Unlike the non-mutating [`$(function_name)`](@ref),
    [`$(function_name)!`](@ref) takes cache arguments of pre-computed
    `factorizations` and `primes` and mutates them **in-place**, thus
    updating the cache for future usage.  When needing to call
    `$(function_name)` repeatedly, it is thus more efficient to call
    `$(function_name)!` instead and pass shared `factorizations` and
    `primes`.

    To this end, `FRACTRAN.jl` provides two module-level cache
    variables, [`FRACTRAN.factorizations`](@ref) and
    [`FRACTRAN.primes`](@ref), which you can use as storage targets.

    !!! warning
        Using the module-level cache variables is **not** thread-safe.
    """
    return note
end

function _add_docstring_note_variable()::String
    note = """
    This optional cache can be useful to accelerate repeated
    [`fractran`](@ref) calls when using `FRACTRAN.jl`'s mutating
    functions.

    These are:

    - [`factorize!`](@ref)
    - [`fractran!`](@ref)
    - [`add!`](@ref)
    - [`sub!`](@ref)
    - [`mul!`](@ref)
    - [`divrem!`](@ref)
    - [`primegame!`](@ref)
    """
    return note
end

function _isinteger(counter::Accumulator{Int, Int})::Bool
    # Return whether the `counter`'s value (exponent) is positive for
    # all keys (bases).  Then, the represented number is also positive,
    # since fractions would have negative exponents.
    return all(exponent >= 0 for exponent in values(counter))
end

"""
    generate_primes(min_n::Integer, max_n::Integer)::Vector{Int}
    generate_primes(max_n::Integer)::Vector{Int}

Compute the prime numbers from `min_n` to `max_n`, inclusive.

The second form defaults to `min_n = 2`.

# Examples

```jldoctest
julia> generate_primes(2, 20)
8-element Vector{Int64}:
  2
  3
  5
  7
 11
 13
 17
 19

julia> generate_primes(10)     # Usage of default value 2 for `min_n`.
4-element Vector{Int64}:
 2
 3
 5
 7

julia> generate_primes(-5, 1)  # There's no prime number below 2.
ERROR: ArgumentError:  min_n must be ≥ 2.
[...]
```
"""
generate_primes(max_n::Integer)::Vector{Int} = generate_primes(2, max_n)

function generate_primes(min_n::Integer, max_n::Integer)::Vector{Int}
    # Check that `min_n` is greater than 1 and odd, or throw an error.
    min_n >= 2 || throw(_MDError(md"`min_n` must be `≥ 2`."))
    min_n == 2 || isodd(min_n) || throw(_MDError(md"`min_n` must be odd."))
    max_n >= min_n || throw(_MDError(md"`max_n` must be `≥ min_n`."))

    _min_n = Int(min_n)
    _max_n = Int(max_n)

    if _min_n == 2
        _min_n = 3
        primes = [2]
    else
        primes = Int[]
    end

    # Set all odd integers as dividends to check in the trial division.
    dividends = _min_n:2:_max_n

    # Successively divide each dividend by all odd divisors up to, and
    # including, the next-greater integer to the dividend's square root.
    # As soon as a division is possible, i.e., the dividend is divisible
    # by the divisor, it is decided that the dividend isn't prime.  If
    # all divisors have been exhausted to no avail, the dividend must be
    # prime, so add it to the list.
    for dividend in dividends
        is_divisible = false
        divisors = range(3, ceil(Int, sqrt(dividend)), step=2)

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

"""
    factorize(n::Integer)::Accumulator{Int, Int}

    factorize!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        n::Integer,
    )::Accumulator{Int, Int}

Factorize `n` to prime factors.

The factorization yields an `Accumulator` mapping the factors' bases to
their exponents (counts).  The second form takes cache arguments for
accelerated computations, see the [Extended help](@ref).

# Examples

```jldoctest
julia> factorize(120)  # Composite number.
DataStructures.Accumulator{Int64, Int64} with 3 entries:
  5 => 1
  2 => 3
  3 => 1

julia> factorize(7)    # Prime number.
DataStructures.Accumulator{Int64, Int64} with 1 entry:
  7 => 1

julia> factorize(1)    # Empty product.
Accumulator{Int64,Int64}()
```

# Extended help

$(_add_docstring_note_function("factorize"))
"""
factorize, factorize!

function factorize(n::Integer)::Accumulator{Int, Int}
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return factorize!(factorizations, primes, n)
end

function factorize!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    n::Integer,
)::Accumulator{Int, Int}
    # Check that `n` is positive, or throw an error.
    n >= 1 || throw(_MDError(md"`n` must be `≥ 1`."))
    _n = Int(n)

    # If the factorization has already been computed for `_n`, return
    # this (cached) value immediately.
    haskey(factorizations, n) && return factorizations[n]

    # Compute all prime numbers between the highest computed prime
    # number (plus 2, as the next integer would be even) and the square
    # root of `_n`, if needed.  These form the divisors to check in the
    # trial division.
    max_divisor = ceil(Int, sqrt(_n))
    if isempty(primes)
        min_divisor = 2
        if min_divisor <= max_divisor
            append!(primes, generate_primes(min_divisor, max_divisor))
        end
    elseif primes[end] < max_divisor
        min_divisor = primes[end] == 2 ? 3 : primes[end] + 2
        if min_divisor <= max_divisor
            append!(primes, generate_primes(min_divisor, max_divisor))
        end
    end

    # Successively divide the number `n` by all prime numbers, as often
    # as possible.
    new_n = _n
    factors = Int[]
    for divisor in primes
        while new_n % divisor == 0
            push!(factors, divisor)
            new_n ÷= divisor
        end
    end

    new_n > 1 && push!(factors, new_n)

    # Count the number of occurrences of each prime factor and return
    # this as mapping.
    factor_counts = DataStructures.counter(factors)
    factorizations[n] = factor_counts
    return factor_counts
end

"""
    prettify_factorization(
        factors::Accumulator{Int, Int};
        explicit_one::Bool = false,
        verbose::Bool = false,
    )::String

Stringify the `factors`' factorization in the canonical, condensed way.

If `explicit_one` is `true` (default: `false`), also print exponents of
one (`1`), as `¹`.  If `verbose` is `true` (default: `false`), expand
the exponents to individual factors.  In this case, `explicit_one` has
no effect.

# Examples

```jldoctest
julia> factors = factorize(120)
DataStructures.Accumulator{Int64, Int64} with 3 entries:
  5 => 1
  2 => 3
  3 => 1

julia> prettify_factorization(factors)
"2³⋅3⋅5"

julia> prettify_factorization(factorize(120))  # Same as above.
"2³⋅3⋅5"

julia> prettify_factorization(factorize(120), explicit_one=true)
"2³⋅3¹⋅5¹"

julia> prettify_factorization(factorize(120), verbose=true)
"2⋅2⋅2⋅3⋅5"
```
"""
function prettify_factorization(
    factors::Accumulator{Int, Int};
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
        n::Integer,
        fractions::Rational{<:Integer}...;
        return_first::Bool = false,
    )::Int

    fractran(
        n::Integer,
        fractions::Tuple{Rational{<:Integer}, Vararg{Rational{<:Integer}}};
        return_first::Bool = false,
    )::Int

    fractran!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        n::Integer,
        fractions::Rational{<:Integer}...;
        return_first::Bool = false,
    )::Int

    fractran!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        n::Integer,
        fractions::Tuple{Rational{<:Integer}, Vararg{Rational{<:Integer}}};
        return_first::Bool = false,
    )::Int

Run the FRACTRAN algorithm on the start value `n` using the `fractions`.

*Iff* `return_first` is `true` (default: `false`), return the first
obtained integer.  Else, run the algorithm until no fraction yields an
integer and return the last integer.  This is the FRACTRAN algorithm's
actual result—`return_first` is needed by some specific programs like
PRIMEGAME that filter the FRACTRAN integers.

The third and fourth forms take cache arguments for accelerated
computations, see the [Extended help](@ref).

# Examples

## Simple addition program

```jldoctest
julia> using FRACTRAN

julia> n = 432;                # Start number: 2^4 * 3^3 (operands 4 and 3).

julia> fractions = (3//2,);    # FRACTRAN program for addition.

julia> fractran(n, fractions)  # FRACTRAN invocation.
2187

julia> factorize(ans)          # Get exponents, result is in register `3`.
DataStructures.Accumulator{Int64, Int64} with 1 entry:
  3 => 7
```

## Subtraction program with cache

```jldoctest
julia> using DataStructures: DataStructures

julia> factorizations = Dict{Int, DataStructures.Accumulator{Int, Int}}();

julia> primes = Int[];

julia> n = 432;                # Start number: 2^4 * 3^3 (operands 4 and 3).

julia> fractions = (1//6,);    # FRACTRAN program for subtraction.

julia> fractran(n, fractions)  # FRACTRAN invocation.
2

julia> factorize(ans)          # Get exponents, result is in register `2`.
DataStructures.Accumulator{Int64, Int64} with 1 entry:
  2 => 1
```

# Extended help

$(_add_docstring_note_function("fractran"))
"""
fractran, fractran!

function fractran(
    n::Integer,
    fractions::Tuple{Rational{<:Integer}, Vararg{Rational{<:Integer}}};
    return_first::Bool = false,
)::Int
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return fractran!(factorizations, primes, n, fractions...; return_first)
end

function fractran(
    n::Integer,
    fractions::Rational{<:Integer}...;
    return_first::Bool = false,
)::Int
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return fractran!(factorizations, primes, n, fractions; return_first)
end

function fractran!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    n::Integer,
    fractions::Tuple{Rational{<:Integer}, Vararg{Rational{<:Integer}}};
    return_first::Bool = false,
)::Int
    return fractran!(factorizations, primes, n, fractions...; return_first)
end

function fractran!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    n::Integer,
    fractions::Rational{<:Integer}...;
    return_first::Bool = false,
)::Int
    # Factorize `n` and each `fraction` for more efficient operation on
    # the implicitly represented powers with a much lower risk of
    # integer overflow.
    factors = factorize!(factorizations, primes, n)
    fraction_powers = [
        (
            factorize!(factorizations, primes, numerator(fraction)),
            factorize!(factorizations, primes, denominator(fraction)),
        )
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

"""
    add(a::Integer, b::Integer)::Int

    add!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        a::Integer,
        b::Integer,
    )::Int

Add `b` to `a` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `3//2`
- Result:       `3^(a+b)`

The second form takes cache arguments for accelerated computations, see
the [Extended help](@ref).

!!! note
    `add(a, b)` directly returns `a + b`, not `3^(a+b)`.

# Examples

```jldoctest
julia> using FRACTRAN

julia> FRACTRAN.add(4, 3)
7

julia> FRACTRAN.add(1, 2)
3
```

# Extended help

$(_add_docstring_note_function("add"))
"""
add, add!

function add(a::Integer, b::Integer)::Int
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return add!(factorizations, primes, a, b)
end

function add!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    a::Integer,
    b::Integer,
)::Int
    n = 2^a * 3^b
    fractions = (3//2,)
    return (
        fractran!(factorizations, primes, n, fractions)
        |> (x -> factorize!(factorizations, primes, x))
        |> values
        |> only
    )
end

"""
    sub(a::Integer, b::Integer)::Int

    sub!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        a::Integer,
        b::Integer,
    )::Int

Subtract `b` from `a` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `1//6`
- Result:       `2^(a-b)`

The second form takes cache arguments for accelerated computations, see
the [Extended help](@ref).

!!! note
    `sub(a, b)` directly returns `a - b`, not `2^(a-b)`.

# Examples

```jldoctest
julia> using FRACTRAN

julia> FRACTRAN.sub(4, 3)
1

julia> FRACTRAN.sub(1, 2)
-1
```

# Extended help

$(_add_docstring_note_function("sub"))
"""
sub, sub!

function sub(a::Integer, b::Integer)::Int
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return sub!(factorizations, primes, a, b)
end

function sub!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    a::Integer,
    b::Integer,
)::Int
    n = 2^a * 3^b
    fractions = (1//6,)
    result = fractran!(factorizations, primes, n, fractions)
    factors = factorize!(factorizations, primes, result)

    return if a == b
        0            # Empty product, as 2^(a-b) = 2^0 = 1 ⟹ factorize(1) = ∅.
    elseif a < b
        -factors[3]  # Incomplete subtraction of `b`'s exponent from `a`'s.
    else
        factors[2]   # Complete subtraction.
    end
end

"""
    mul(a::Integer, b::Integer)::Int

    mul!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        a::Integer,
        b::Integer,
    )::Int

Multiply `a` by `b` using the following FRACTRAN program:

- Start value:  `n = 2^a * 3^b`
- Fractions:    `455//33`, `11//13`, `1//11`, `3//7`, `11//2`, `1//3`
- Result:       `5^(a*b)`

The second form takes cache arguments for accelerated computations, see
the [Extended help](@ref).

!!! note
    `mul(a, b)` directly returns `a * b`, not `5^(a*b)`.

# Examples

```jldoctest
julia> using FRACTRAN

julia> FRACTRAN.mul(4, 3)
12

julia> FRACTRAN.mul(1, 2)
2
```

# Extended help

$(_add_docstring_note_function("mul"))
"""
mul, mul!

function mul(a::Integer, b::Integer)::Int
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return mul!(factorizations, primes, a, b)
end

function mul!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    a::Integer,
    b::Integer,
)::Int
    n = 2^a * 3^b
    fractions = (455//33, 11//13, 1//11, 3//7, 11//2, 1//3)
    return (
        fractran!(factorizations, primes, n, fractions)
        |> (x -> factorize!(factorizations, primes, x))
        |> values
        |> only
    )
end

"""
    divrem(a::Integer, b::Integer)::Tuple{Int, Int}

    divrem!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        a::Integer,
        b::Integer,
    )::Tuple{Int, Int}

Divide `a` by `b` (as Euclidian division) using the following FRACTRAN
program:

- Start value:  `2^a * 3^b * 11`
- Fractions:    `91//66`, `11//13`, `1//33`, `85//11`, `57//119`,
                `17//19`, `11//17`, `1//3`
- Result:       `5^q * 7^r` (`q ≔ a ÷ b`: quotient, `r ≔ a % b`:
                remainder)

The second form takes cache arguments for accelerated computations, see
the [Extended help](@ref).

!!! note
    `divrem(a, b)` directly returns `(q, r)`, i.e., `(a ÷ b, a % b)`,
    not `5^q * 7^r`.

# Examples

```jldoctest
julia> using FRACTRAN

julia> FRACTRAN.divrem(4, 3)
(1, 1)

julia> FRACTRAN.divrem(1, 2)
(0, 1)

julia> FRACTRAN.divrem(2, 1)
(2, 0)
```

# Extended help

$(_add_docstring_note_function("divrem"))
"""
divrem, divrem!

function divrem(a::Integer, b::Integer)::Tuple{Int, Int}
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return divrem!(factorizations, primes, a, b)
end

function divrem!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    a::Integer,
    b::Integer,
)::Tuple{Int, Int}
    n = 2^a * 3^b * 11
    fractions = (91//66, 11//13, 1//33, 85//11, 57//119, 17//19, 11//17, 1//3)
    result = fractran!(factorizations, primes, n, fractions)
    factors = factorize!(factorizations, primes, result)

    return if haskey(factors, 5) && haskey(factors, 7)
        (factors[5], factors[7])  # Incomplete division with `q` and `r`.
    elseif haskey(factors, 7)
        (0, factors[7])           # Incomplete division with only `r`.
    else
        (factors[5], 0)           # Complete division with only `q`.
    end
end

"""
    primegame(max_iterations::Integer = 100)::Vector{Int}

    primegame!(
        factorizations::Dict{Int, Accumulator{Int, Int}},
        primes::Vector{Int},
        max_iterations::Integer = 100,
    )::Vector{Int}

Find all prime numbers that are reachable by running `max_iterations`
(default: `100`) iterations of the algorithm using the following
FRACTRAN program, called "PRIMEGAME":

- Start value:  `n = 2` (in PRIMEGAME, more generally, `n = 2^a * 7^b`)
- Fractions:    `17//91`, `78//85`, `19//51`, `23//38`, `29//33`,
                `77//29`, `95//23`, `77//19`, `1//17`, `11//13`,
                `13//11`, `15//2`, `1//7`, `55//1`
- Result:       `2^c * 7^d`, with `c ≤ a` and `d ≤ b`, a prime number
                *iff* `d == 0`

The second form takes cache arguments for accelerated computations, see
the [Extended help](@ref).

!!! note
    `primegame(n)` directly returns all prime numbers up to, and
    including, `c`, not `2^c * 7^d`.  Also note that the PRIMEGAME
    algorithm is very inefficient and may take a very long time even for
    small prime numbers.

# Examples

```jldoctest
julia> using FRACTRAN

julia> FRACTRAN.primegame(300)  # Number of FRACTRAN iterations.
3-element Vector{Int64}:
 2
 3
 5

julia> FRACTRAN.primegame()     # Usage of default value 100.
2-element Vector{Int64}:
 2
 3
```

# Extended help

$(_add_docstring_note_function("primegame"))
"""
primegame, primegame!

function primegame(max_iterations::Integer = 100)::Vector{Int}
    factorizations = Dict{Int, Accumulator{Int, Int}}()
    primes = Int[]
    return primegame!(factorizations, primes, max_iterations)
end

function primegame!(
    factorizations::Dict{Int, Accumulator{Int, Int}},
    primes::Vector{Int},
    max_iterations::Integer = 100,
)::Vector{Int}
    n = 2
    fractions = (
        17//91, 78//85, 19//51, 23//38, 29//33, 77//29, 95//23, 77//19, 1//17,
        11//13, 13//11, 15//2, 1//7, 55//1,
    )
    results = Int[]

    for _ in 1:max_iterations
        result = fractran!(
            factorizations,
            primes,
            n,
            fractions,
            return_first=true,
        )

        push!(results, result)
        n = result
    end

    found_primes = Int[]
    for result in results
        factors = factorize!(factorizations, primes, result)
        if (
            factors[2] >= 1
            && all(exponent == 0 for (base, exponent) in factors if base != 2)
        )
            push!(found_primes, factors[2])
        end
    end

    return found_primes
end

"""
Module-level cache for yet computed factorizations.

# Extended help

$(_add_docstring_note_variable())
"""
factorizations::Dict{Int, Accumulator{Int, Int}} =
    Dict{Int, Accumulator{Int, Int}}()

"""
Module-level cache for yet computed prime numbers.

# Extended help

$(_add_docstring_note_variable())
"""
primes::Vector{Int} = Int[]

end  # module
