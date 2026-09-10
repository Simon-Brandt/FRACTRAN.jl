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
