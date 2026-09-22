# Tutorial

```@raw text
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
```

```@meta
CurrentModule = FRACTRAN
```

To guide you through FRACTRAN.jl's functionality, the following sections show some application examples of FRACTRAN.

!!! note
    Each section runs in its own REPL environment, implicitly with `using FRACTRAN` in the beginning.  Thus, the caches are reset between sections.

## Table of contents

```@contents
Pages = ["tutorial.md"]
Depth = 2:3
```

## Prime factorization

### Prime numbers

```@setup primes
using FRACTRAN
```

Before actually starting with programming in FRACTRAN, it may be helpful to have a look at the concept of prime numbers and prime factorization.  After all, that's what FRACTRAN is all about—it uses the factorization as registers for values.

In short, each natural number, excluding ``1``, is either a prime number or a composite number. The former means that is has no divisors but itself—and, trivially, ``1``—while the latter means to also have other divisors. As it turns out, each composite number can be seen as a product of prime numbers: ``12`` is ``2⋅2⋅3``, for example.  Moreso, this product is *unique*, and thus referred to as *prime factorization*, the decomposition of a natural number into the product of its prime factors. For prime numbers, the factorization is the prime number itself.

The most trivial method to find the factorization of a number ``n``, and actually the one implemented in FRACTRAN.jl, is to divide ``n`` by a list of prime numbers, up to ``⌈\sqrt n⌉``, and store each prime number by which ``n`` is divisible, and how often.

To this end, FRACTRAN.jl needs to know the prime numbers.  Thus, the module contains a function, [`FRACTRAN.generate_primes`](@ref), to create a list of prime numbers between a lower and an upper boundary.  To allow you to retrace FRACTRAN—or simply if you need the prime numbers for other tasks—the function is part of the `public` API.  It works by simple trial division—a number is prime if no number up to ``⌈\sqrt n⌉`` divides it without remainder.  For FRACTRAN's purposes, this is fast enough, so no specialized method of finding large prime numbers is needed.

Suppose now we'd like to know all prime numbers below ``100``.  Then, we just call [`FRACTRAN.generate_primes`](@ref) with this number as argument.  The function has two forms, one with and one without lower boundary.  In the latter case, the boundary is set to ``2``, the smallest prime number.

```@repl
using FRACTRAN

FRACTRAN.generate_primes(100)
```

Now, we can count how many prime numbers there are between ``1000`` and ``2000``:

```@repl primes
FRACTRAN.generate_primes(2000) .|> ≥(1000) |> count
```

Or, equivalently:

```@repl primes
FRACTRAN.generate_primes(2000) |> filter(≥(1000)) |> length
```

Likewise, we can find the largest prime number below ``10^6``:

```@repl primes
FRACTRAN.generate_primes(1_000_000) |> last
```

Thereby, we take advantage of the generated list being sorted.

!!! note
    While more an artifact of the implementation as trial division, this sorting is *guaranteed* for API stability.  In the very unlikely event that this will be changed, it will be a breaking change.

### Factorization

```@setup factorization
using FRACTRAN
```

More relevant for FRACTRAN than bare prime numbers is the actual prime factorization, which is implemented in [`FRACTRAN.factorize`](@ref).  This function takes a number ``n`` and returns its factorization as `DataStructures.Accumulator` object.  The `Accumulator` maps the prime factors to their counts:

```@repl factorization
FRACTRAN.factorize(60)
```

While this data structure is very handy for the FRACTRAN algorithm, it is not really legible.  Thus, if you want to visualize a factorization, you can use FRACTRAN.jl's [`FRACTRAN.prettify_factorization`](@ref) function, passing the `Accumulator` as argument:

```@repl factorization
FRACTRAN.factorize(60) |> FRACTRAN.prettify_factorization
```

[`FRACTRAN.prettify_factorization`](@ref) takes two optional Boolean keyword arguments, `explicit_one` and `verbose`.  The former prints the exponent of ``1`` explicitly, the latter expands the condensed exponent style by listing all prime factors individually:

```@repl factorization
factors = FRACTRAN.factorize(60);
FRACTRAN.prettify_factorization(factors)
FRACTRAN.prettify_factorization(factors, explicit_one=true)
FRACTRAN.prettify_factorization(factors, verbose=true)
```

Internally, FRACTRAN.jl needs to factorize quite a few numbers.  Thus, for many functions, the module contains variants which take cache variables as arguments, such that they can return previously computed results immediately.  These functions have the same name as their non-mutating versions, but end in an exclamation mark, the typical sign for mutating functions.  If you need to compute many factorizations, you can leverage the cache for a sizeable speedup: All you need to do is create the cache variables and pass them as additional arguments to [`FRACTRAN.factorize!`](@ref):

```@repl factorization
using DataStructures: Accumulator

factorizations = Dict{Int, Accumulator{Int, Int}}()
primes = Int[]

FRACTRAN.factorize!(factorizations, primes, 60)
```

The result is the same, but when we inspect the cache variables, we can see that they were populated with the needed intermediate results:

```@repl factorization
factorizations
primes
```

To spare you from needing to memorize or look-up the precise data structures, FRACTRAN.jl comes with two `public` module-level cache variables, [`FRACTRAN.factorizations`](@ref) and [`FRACTRAN.primes`](@ref).  These are *persistent* over a Julia session, which may or may not be desirable.  When in doubt, you can copy the caches and use your copies, instead.  This is *required* for multi-threading, as writing to the caches is *not* thread-safe.

Let's investigate the performance gain by employing the caches:

```@repl factorization
n = 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19  # Large number.
@time FRACTRAN.factorize(n);  # No cache.
@time FRACTRAN.factorize!(FRACTRAN.factorizations, FRACTRAN.primes, n);  # Yet empty cache.
@time FRACTRAN.factorize!(FRACTRAN.factorizations, FRACTRAN.primes, n);  # Now populated cache.
```

Granted, though the factorization runs a lot faster, on this order of magnitude of total runtime, we don't need to care about performance.  Later in this tutorial, however, we'll see how stored prime numbers can offer a lot of runtime gain.

## FRACTRAN implementation

```@setup fractran
using FRACTRAN
```

Having discussed how factorizations work in FRACTRAN.jl, it is time to understand *why* they are useful: In FRACTRAN, a natural number ``n`` gets multiplied by a list of fractions ``f``, until the product ``n⋅fᵢ`` is again a natural number.  Multiplying by a fraction means to multiply by the numerator and divide by the denominator.  On the one hand, divisions are rather slow, and on the other, lead to fractional results, best as `Rational` type, worst as `FloatXY` type.  While this could be circumvented, the main issue is that `Integer`s can overflow, and FRACTRAN can quickly run into extremely large numbers.

FRACTRAN.jl implements the algorithm in the [`fractran`](@ref) function, which, instead of multiplying by fractions, factorizes both the start number and each fraction's numerator and denominator *once*.  Then, the numerators are added and the denominators subtracted in *factorized* form, *i.e.*, on the exponents.  This keeps the core algorithm a pure `Int` algorithm and greatly simplifies judging whether the product is a natural number: If so, all exponents are positive; if not, then at least one is negative.  Now, the algorithm just keeps looping through the fractions, until none creates a natural number, anymore, which [`fractran`](@ref) then returns.

A FRACTRAN program consists of a start number and a list of fractions, so you need to pass only them to [`fractran`](@ref).  For the sake of the first example, we'll use a very simple one-fraction program:

```@repl fractran
n = 2^3 * 3^4
fractions = (2//3,)
result = fractran(n, fractions)
```

How do we interpret the result?  The program ``\frac{2}{3}`` *increments* the register `2`'s value and *decrements* the register `3`'s value on every multiplication step (multiplication by ``2`` and division by ``3``).  Running on ``648`` yields ``128``.  Factorizing the result sheds some light on what happened:

```@repl fractran
FRACTRAN.factorize(result) |> FRACTRAN.prettify_factorization
```

``128`` is ``2⁷``.  In other words, we started with ``2³⋅3⁴`` and obtained ``2⁷``.  It is simple to conclude that the program ``\frac{2}{3}`` works as an adder by writing the sum of the exponents in register `2` and register `3` to register `2`.

When decomposing the FRACTRAN algorithm by hand, we can see that indeed, our supposition is true:

```math
\begin{alignat*}{7}
& n₁   &&≔ && 648             &&= 2³⋅3⁴                                                                         \\[0.5em]
& n₁⋅f &&= && 648⋅\frac{2}{3} &&= 2³⋅3⁴⋅\frac{2}{3} &&= 2⁴⋅3³  &&= 432              &&≕ n₂∈ℕ                    \\[1em]
& n₂⋅f &&= && 432⋅\frac{2}{3} &&= 2⁴⋅3³⋅\frac{2}{3} &&= 2⁵⋅3²  &&= 288              &&≕ n₃∈ℕ                    \\[1em]
& n₃⋅f &&= && 288⋅\frac{2}{3} &&= 2⁵⋅3²⋅\frac{2}{3} &&= 2⁶⋅3¹  &&= 192              &&≕ n₄∈ℕ                    \\[1em]
& n₄⋅f &&= && 192⋅\frac{2}{3} &&= 2⁶⋅3¹⋅\frac{2}{3} &&= 2⁷⋅3⁰  &&= 128              &&≕ n₅∈ℕ                    \\[1em]
& n₅⋅f &&= && 128⋅\frac{2}{3} &&= 2⁷⋅3⁰⋅\frac{2}{3} &&= 2⁸⋅3⁻¹ &&=  85.\overline{3} &&≕ n₆∉ℕ \quad\mathrm{stop}
\end{alignat*}
```

We can futher corroborate the assumption that the FRACTRAN program performs addition by testing a matrix of numbers:

```@repl fractran
all(fractran(2^a * 3^b, 2//3) == 2^(a+b) for a in 1:10, b in 1:10)
```

Without explicitly mentioning it, we already switched to the second form of [`fractran`](@ref) here: You can pass the fractions either as `Tuple` or as `Vararg`s, depending on what fits your current code.

As stated above, many FRACTRAN.jl functions have versions taking cache variables, here embodied by [`fractran!`](@ref).  Apart from the start number and fractions, you need to pass the caches to it:

```@repl fractran
using BenchmarkTools

@btime fractran(2^5 * 3^3, 2//3);  # Without cache.
@btime fractran!($FRACTRAN.factorizations, $FRACTRAN.primes, 2^5 * 3^3, 2//3);  # With cache.
```

As you can see, you can pass the module-level caches [`FRACTRAN.factorizations`](@ref) and [`FRACTRAN.primes`](@ref) to [`fractran!`](@ref), and obtain some speedups.

Finally, both [`fractran`](@ref) and [`fractran!`](@ref) take two optional keyword arguments, `max_steps` and `return_first`.  Both are designed to be used for non-terminating programs.  `max_steps` acts as "safeguard" to abort the FRACTRAN algorithm when `max_steps` steps have been run without finding an integer (like when having an inadvertent infinite loop).  In this case, an error is thrown.  With `return_first`, the FRACTRAN algorithm does not run to completion, but instead returns the *first* product that is a natural number, instead of the usual *last*.  This argument is (currently) required for infinitely running programs, like PRIMEGAME (see below), to be able to filter the result.

!!! note
    `return_first` may be changed/removed in the future (as breaking change).

## Example programs

### FRACTRAN.jl example programs

```@setup example-programs
using FRACTRAN
```

To simplify working with FRACTRAN, FRACTRAN.jl ships several `public` example programs, which you can inspect to see how the algorithm can be employed.  Basically, all these programs just call [`fractran`](@ref) on different sets of fractions, and compute the start integer from user-defined arguments.  *I.e.*, if you want to add ``4`` and ``3``, you just call `add(4, 3)`.  In other words, the fact that the addition is not just a `4 + 3`, but a whole FRACTRAN program, is completely hidden.

There are four programs for simple arithmetics: [`FRACTRAN.add`](@ref), [`FRACTRAN.sub`](@ref), [`FRACTRAN.mul`](@ref), and [`FRACTRAN.divrem`](@ref).  They take two `Integer` arguments and return their sum, difference, product, or quotient and remainder.

```@repl example-programs
FRACTRAN.add(4, 3)
FRACTRAN.sub(4, 3)
FRACTRAN.mul(4, 3)
FRACTRAN.divrem(4, 3)
```

We can make sure that the programs work correctly by comparing their results to the built-in operators:

```@repl example-programs
FRACTRAN.add(4, 3) == 4 + 3
FRACTRAN.sub(4, 3) == 4 - 3
FRACTRAN.mul(4, 3) == 4 * 3
FRACTRAN.divrem(4, 3) == Base.divrem(4, 3) == (4 ÷ 3, 4 % 3)
```

The fifth example program, called "PRIMEGAME", is also the most interesting: It (very slowly) creates prime numbers, as you can see in its [`FRACTRAN.primegame`](@ref) implementation:

```@repl example-programs
FRACTRAN.primegame()
```

PRIMEGAME is an example of an infinite FRACTRAN program.  Thus, FRACTRAN.jl implements it using the `return_first` argument to [`fractran`](@ref), and applies a filter on the results.  Additionally, [`FRACTRAN.primegame`](@ref) takes an optional argument, `max_iterations`, to specify the number of times [`fractran`](@ref) is run.

!!! note
    The argument does *not* mean to generate the first ``n`` prime numbers, or all prime numbers smaller than, and including, ``n``.  Since the algorithm is extremely slow, even a very small ``n`` would take an extremely long time.  The default value for `max_iterations`, ``100``, creates the first *two* numbers (``n = 2``); ``1000`` just *four* (``n = 4``).  You can look up the needed iterations for the ``n``ᵗʰ prime number in the [OEIS](https://en.wikipedia.org/wiki/On-Line_Encyclopedia_of_Integer_Sequences), as sequence [A007547](https://oeis.org/A007547).

Like [`fractran`](@ref), all five example programs have alternate forms to take cache arguments, *viz.*, [`FRACTRAN.add!`](@ref), [`FRACTRAN.sub!`](@ref), [`FRACTRAN.mul!`](@ref), [`FRACTRAN.divrem!`](@ref), and [`FRACTRAN.primegame!`](@ref).  These can be used to considerably speed up multi-fraction and repeatedly executed programs, as we can see with PRIMEGAME:

```@repl example-programs
using BenchmarkTools

@btime FRACTRAN.primegame(1000);  # Without cache.
@btime FRACTRAN.primegame!($FRACTRAN.factorizations, $FRACTRAN.primes, 1000);  # With cache.
```

Of course, you could also pass your own instances to the functions, instead of [`FRACTRAN.factorizations`](@ref) and [`FRACTRAN.primes`](@ref).

### Your own program

```@setup example
using FRACTRAN
```

As last step, we will look at how you can use FRACTRAN.jl to implement your own FRACTRAN program using a slightly simplified, cache-less version of [`FRACTRAN.add`](@ref).

Recall that a FRACTRAN program consists of nothing but a start number and a set of fractions.  The start number should have a prime factorization with the same registers as some fractions use (though they often employ more registers).  For addition, we need two numbers, which we pass as arguments to our addition function.  So our initial prototype may look like this:

```@repl example
function add(a, b)
    n = 2^a * 3^b
    fractions = (3//2,)
end
```

We now need to pass the start number and fractions to the FRACTRAN implementation, *i.e.*, to [`fractran`](@ref).

```@repl example
function add(a, b)
    n = 2^a * 3^b
    fractions = (3//2,)
    fractran(n, fractions)
end

add(4, 3)
```

This is already the correct result!  It's just not very user-friendly—we passed ``4`` and ``3`` and got ``2187`` as result, clearly not what a user likely expected of an addition program.

Thus, we can [`FRACTRAN.factorize`](@ref) the result to decompose it into the individual registers:

```@repl example
function add(a, b)
    n = 2^a * 3^b
    fractions = (3//2,)
    result = fractran(n, fractions)
    FRACTRAN.factorize(result)
end

add(4, 3)
```

Obviously, the resulting `Accumulator` is even less readable (let alone usable in subsequent computations, where an `Integer` was expected).  So we take the `values` to read out the registers' exponents, and assert that the returned register is the `only` one (we could also directly address the correct register *via* `factors[3]`):

```@repl example
function add(a, b)
    n = 2^a * 3^b
    fractions = (3//2,)
    result = fractran(n, fractions)
    factors = FRACTRAN.factorize(result)
    only(values(factors))
end

add(4, 3)
```

This yields ``7``, as the user will have expected.  We can now add type assertions to `a` and `b` to make sure that only integral numbers are passed, maybe add a return type conversion (which is a no-op as already [`fractran`](@ref) defined it), and slightly reformat the computation into a pipeline:

```@repl example
function add(a::Integer, b::Integer)::Int
    n = 2^a * 3^b
    fractions = (3//2,)
    return (
        fractran(n, fractions)
        |> FRACTRAN.factorize
        |> values
        |> only
    )
end

add(4, 3)
```

This is now pretty much the exact implementation in FRACTRAN.jl.  The only difference is that in FRACTRAN.jl, the [`FRACTRAN.add`](@ref) function calls [`FRACTRAN.add!`](@ref) with newly created cache arguments, and the actual implementation logic resides in `FRACTRAN.add!`.

For completeness, here's the entire implementation:

```julia
using DataStructures: Accumulator

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
        |> (x -> FRACTRAN.factorize!(factorizations, primes, x))
        |> values
        |> only
    )
end
```

In fact, the only thing that changed is that we now use the in-place mutating versions of FRACTRAN.jl's functions, and accordingly pass the caches.

!!! note
    Even though simple FRACTRAN programs are this easy to implement, handling peculiarities like negative results (as in [`FRACTRAN.sub`](@ref)) can be slightly more difficult, as you have to remember which registers the results may live in.  For the start, you may be better off disallowing certain types of input, like `a ≤ b` for subtractions.

As an exercise, you may now try to implement [`FRACTRAN.sub`](@ref)!  After you're done, you can uncover the following section to see FRACTRAN.jl's solution.

!!! details "FRACTRAN.jl implementation"
    ```julia
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
        factors = FRACTRAN.factorize!(factorizations, primes, result)

        return if a == b
            0            # Empty product, as 2^(a-b) = 2^0 = 1 ⟹ factorize(1) = ∅.
        elseif a < b
            -factors[3]  # Incomplete subtraction of `b`'s exponent from `a`'s.
        else
            factors[2]   # Complete subtraction.
        end
    end
    ```

You found a simpler solution that still passes the FRACTRAN.jl test suite?  Then feel free to share it in an [issue](https://github.com/Simon-Brandt/FRACTRAN.jl/issues/new)!  Likewise, if you have implemented other FRACTRAN programs, you can also open an issue and probably get it added to FRACTRAN.jl.
