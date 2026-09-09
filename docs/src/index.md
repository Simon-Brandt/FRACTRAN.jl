# FRACTRAN.jl

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

Julia implementation of the esoteric programming language [FRACTRAN](https://en.wikipedia.org/wiki/FRACTRAN).

## Table of contents

```@contents
Pages = ["index.md"]
Depth = 2:3
```

## Overview

[FRACTRAN](https://en.wikipedia.org/wiki/FRACTRAN) is an esoteric programming language, based on fractions, that was developed by [John Conway](https://en.wikipedia.org/wiki/John_Horton_Conway) in 1987[^Conway1987].  FRACTRAN.jl implements this algorithm and provides some example programs.

[^Conway1987]: Conway, J.H. FRACTRAN: A Simple Universal Programming Language for Arithmetic. In: Cover, T.M., Gopinath, B. (eds) Open Problems in Communication and Computation. Springer 1987, [10.1007/978-1-4612-4808-8_2](https://doi.org/10.1007/978-1-4612-4808-8_2).

## Algorithm

The algorithm behind FRACTRAN works by taking a natural number ``n`` and an ordered collection of fractions ``f``.  ``n`` gets multiplied by each fraction ``fᵢ``, until the result ``n⋅fᵢ`` is an integer, i.e., ``n⋅fᵢ ∈ ℕ``.  This integer gets multiplied again with the fractions, starting from the first one, ``f₁``, until no product ``n⋅fᵢ`` leads an integer, anymore.  The last obtained integer marks the result of the FRACTRAN algorithm.

Generally, multiplying a natural number by a fraction, as required for FRACTRAN, is equivalent to adding/subtracting exponents in the prime factorization of the number and the fraction's numerator/denominator.  Thus, FRACTRAN can be considered an implementation of a register machine whose registers are the prime factors, and whose stored values are the factors' exponents.  Basically, the natural numbers, the products of their factorizations, encode these registers' values by [Gödel numbering](https://en.wikipedia.org/wiki/Gödel_numbering).

## Module contents

FRACTRAN.jl provides multiple functions to work with the FRACTRAN algorithm: an implementation of the algorithm itself, several example programs, and a prime number generator for factorizating the numbers for FRACTRAN.  Thus, you might also use FRACTRAN.jl if you're working with factorizations, but note that the implementation uses simple trial division for finding prime numbers, with lesser performance than optimized prime factorization algorithms.  This is sufficient for FRACTRAN, since the language is slow by itself and thus only really suitable as educational tool, but you may want to use more optimized libraries if you're only needing a factorization algorithm.

The core of this module is formed by the [`fractran`](@ref) function, which implements the FRACTRAN algorithm.  Since prime numbers are the center of this algorithm, FRACTRAN.jl also includes a function to generate a list of prime numbers, [`generate_primes`](@ref).  These prime numbers are required for factorizing the numbers using the [`factorize`](@ref) function—as needed for `fractran`.  There is also the (internally unused) function [`prettify_factorization`](@ref) that you might want to use to create a string representation of a factorization for pretty-printing.

Further, FRACTRAN.jl provides a set of example functions implementing some selected FRACTRAN programs: [`add`](@ref) adds two numbers, [`sub`](@ref) subtracts them, [`mul`](@ref) multiplies them, and [`divrem`](@ref) divides them with remainder.  Additionally, the [`primegame`](@ref) function implements the perhaps most famous FRACTRAN program, called "PRIMEGAME", which generates prime numbers.

Since the FRACTRAN algorithm is rather slow, especially PRIMEGAME, FRACTRAN.jl also includes two module-level caches, [`factorizations`](@ref) and [`primes`](@ref).  These caches may be used for accelerating repeated `fractran` calls.  To this end, `factorize`, `fractran`, and all example programs have a second form with exclamation mark (like [`factorize!`](@ref), [`fractran!`](@ref) etc.), that take caches as additional arguments for in-place mutation.  You may either use the provided module-level caches or pass your own objects to them, depending on the intended persistence of the caches.

!!! note
    Internally, each invocation still uses cached values, even for the function variants without exclamation marks, but these are re-computed per call and only persistent for the internal sub-calls.

!!! note
    In order not to clutter your namespace upon `using FRACTRAN`, the caches and example programs are only declared as `public`, but not `export`ed.  You can access them by prefixing them with the module name, i.e., as `FRACTRAN.add` etc.
