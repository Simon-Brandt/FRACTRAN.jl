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

## Prime numbers

Before actually starting with programming in FRACTRAN, it may be helpful to have a look at the concept of prime numbers and prime factorization.  After all, that's what FRACTRAN is all about—it uses the factorization as registers for values.

In short, each natural number, excluding ``1``, is either a prime number or a composite number. The former means that is has no divisors but itself—and, trivially, ``1``—while the latter means to also have other divisors. As it turns out, each composite number can be seen as a product of prime numbers: ``12`` is ``2⋅2⋅3``, for example.  Moreso, this product is *unique*, and thus referred to as *prime factorization*, the decomposition of a natural number into the product of its prime factors. For prime numbers, the factorization is the prime number itself.

The most trivial method to find the factorization of a number ``n``, and actually the one implemented in FRACTRAN.jl, is to divide ``n`` by a list of prime numbers, up to ``⌈\sqrt n⌉``, and store each prime number by which ``n`` is divisible, and how often.

To this end, FRACTRAN.jl needs to know the prime numbers.  Thus, the module contains a function, [`generate_primes`](@ref), to create a list of prime numbers between a lower and an upper boundary.  To allow you to retrace FRACTRAN—or simply if you need the prime numbers for other tasks—the function is `export`ed as part of the public API.  It works by simple trial division—a number is prime if no number up to ``⌈\sqrt n⌉`` divides it without remainder.  For FRACTRAN's purposes, this is fast enough, so no specialized method of finding large prime numbers is needed.

Suppose now we'd like to know all prime numbers below ``100``.  Then, we just call `generate_primes` with this number as argument.  The function has two forms, one with and one without lower boundary.  In the latter case, the boundary is set to ``2``, the smallest prime number.

```@repl
using FRACTRAN

generate_primes(100)
```

Now, we can count how many prime numbers there are between ``1000`` and ``2000``:

```@setup primes
using FRACTRAN
```

```@repl primes
generate_primes(2000) .|> ≥(1000) |> count
```

Or, equivalently:

```@repl primes
generate_primes(2000) |> filter(≥(1000)) |> length
```

Likewise, we can find the largest prime number below ``10^6``:

```@repl primes
generate_primes(1_000_000) |> last
```

Thereby, we take advantage of the generated list being sorted.

## Prime factorization

More relevant for FRACTRAN than bare prime numbers is the actual prime factorization, which is implemented in [`factorize`](@ref).  This function takes a number ``n`` and returns its factorization as `DataStructures.Accumulator` object.  The `Accumulator` maps the prime factors to their counts:

```@setup factorization
using FRACTRAN
```

```@repl factorization
factorize(60)
```

While this data structure is very handy for the FRACTRAN algorithm, it is not really legible.  Thus, if you want to visualize a factorization, you can use FRACTRAN.jl's [`prettify_factorization`](@ref) function, passing the `Accumulator` as argument:

```@repl factorization
factorize(60) |> prettify_factorization
```

`prettify_factorization` takes two optional Boolean keyword arguments, `explicit_one` and `verbose`.  The former prints the exponent of ``1`` explicitly, the latter expands the condensed exponent style by listing all prime factors individually:

```@repl factorization
factors = factorize(60);
prettify_factorization(factors)
prettify_factorization(factors, explicit_one=true)
prettify_factorization(factors, verbose=true)
```

Internally, FRACTRAN.jl needs to factorize quite a few numbers.  Thus, for many functions, the module contains variants which take cache variables as arguments, such that they can return previously computed results immediately.  These functions have the same name as their non-mutating versions, but end in an exclamation mark, the typical sign for mutating functions.  If you need to compute many factorizations, you can leverage the cache for a sizeable speedup: All you need to do is create the cache variables and pass them as additional arguments to [`factorize!`](@ref):

```@repl factorization
using DataStructures: Accumulator

factorizations = Dict{Int, Accumulator{Int, Int}}()
primes = Int[]

factorize!(factorizations, primes, 60)
```

The result is the same, but when we inspect the cache variables, we can see that they were populated with the needed intermediate results:

```@repl factorization
factorizations
primes
```

To spare you from needing to memorize or look-up the precise data structures, FRACTRAN.jl comes with two `public` module-level cache variables, [`factorizations`](@ref) and [`primes`](@ref).  These are **persistent** over a Julia session, which may or may not be desirable.  When in doubt, you can copy the caches and use your copies, instead.  This is **required** for multi-threading, as writing to the caches is **not** thread-safe.

Let's investigate the performance gain by employing the caches:

```@repl factorization
n = 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19  # Large number.
@time factorize(n);  # No cache.
@time factorize!(FRACTRAN.factorizations, FRACTRAN.primes, n);  # Yet empty cache.
@time factorize!(FRACTRAN.factorizations, FRACTRAN.primes, n);  # Now populated cache.
```

Granted, though the factorization runs a lot faster, on this order of magnitude of total runtime, we don't need to care about performance.  Later in this tutorial, however, we'll see how stored prime numbers can offer a lot of runtime gain.

## FRACTRAN implementation

Having discussed how factorizations work in FRACTRAN.jl, it is time to understand *why* they are useful: In FRACTRAN, a natural number ``n`` gets multiplied by a list of fractions ``f``, until the product ``n⋅fᵢ`` is again a natural number.  Multiplying by a fraction means to multiply by the numerator and divide by the denominator.  On the one hand, divisions are rather slow, and on the other, lead to fractional results, best as `Rational` type, worst as `FloatXY` type.  FRACTRAN.jl implements the algorithm in the [`fractran`](@ref) function, which, instead of multiplying by fractions, factorizes both the start number and each fraction's numerator and denominator *once*.  Then, the numerators are added and the denominators subtracted in *factorized* form, *i.e.*, on the exponents.  This keeps the core algorithm a pure `Int` algorithm and greatly simplifies judging whether the product is a natural number: If so, all exponents are positive; if not, then at least one is negative.  Now, the algorithm just keeps looping through the fractions, until none creates a natural number, anymore, which `fractran` then returns.

A FRACTRAN program consists of a start number and a list of fractions, so you need to pass only them to `fractran`.  For the sake of the first example, we'll use a very simple one-fraction program:

```@setup fractran
using FRACTRAN
```

```@repl fractran
n = 2^3 * 3^4
fractions = (2//3,)
result = fractran(n, fractions)
```

How do we interpret the result?  The program ``\frac{2}{3}`` *increments* the register `2`'s value and *decrements* the register `3`'s value on every multiplication step (multiplication by ``2`` and division by ``3``).  Running on ``648`` yields ``128``.  Factorizing the result sheds some light on what happened:

```@repl fractran
factorize(result) |> prettify_factorization
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

Without explicitly mentioning it, we already switched to the second form of `fractran` here: You can pass the fractions either as `Tuple` or as `Vararg`s, depending on what fits your current code.

As stated above, many FRACTRAN.jl functions have versions taking cache variables, here embodied by [`fractran!`](@ref).  Apart from the start number and fractions, you need to pass the caches to it:

```@repl fractran
using BenchmarkTools

@btime fractran(2^5 * 3^3, 2//3);  # Without cache.
@btime fractran!($FRACTRAN.factorizations, $FRACTRAN.primes, 2^5 * 3^3, 2//3);  # With cache.
```

As you can see, you can pass the module-level caches [`factorizations`](@ref) and [`primes`](@ref) to `fractran!`, and obtain some speedups.

Finally, both `fractran` and `fractran!` take an optional keyword argument, `return_first`, which does not run the FRACTRAN algorithm to completion, but instead returns the *first* product that is a natural number, instead of the usual *last*.  This is (currently) required for infinitely running programs, like PRIMEGAME (see below), to be able to filter the result.

!!! note
    `return_first` may be changed/removed in the future (as breaking change).
