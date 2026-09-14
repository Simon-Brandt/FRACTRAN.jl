# API reference

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

FRACTRAN.jl offers the below functions and cache variables within the `FRACTRAN` module namespace as public interface. All undocumented symbols are considered private implementation details and may change at any time.  Currently, there are very few of which, but should there be one that you'd like to become public, please [open an issue](https://github.com/Simon-Brandt/FRACTRAN.jl/issues/new) asking for it.

## Table of contents

```@contents
Pages = ["reference.md"]
Depth = 2:3
```

## Index

The following symbols in FRACTRAN.jl are `export`ed or `public`:

```@index
Order = [:module, :function, :constant]
```

## Module

```@docs
FRACTRAN
```

## Prime factorization

To simplify the underlying computations, FRACTRAN.jl implements FRACTRAN using prime factorization by [`factorize`](@ref) (non-cache-mutating) and [`factorize!`](@ref) (cache-mutating).  Thereby, [`generate_primes`](@ref) generates the needed list of prime numbers.  Additionally, [`prettify_factorization`](@ref) can create a prettified string representation of a factorization for prettyprinting.  All functions are `export`ed for external usage by you.

```@docs
generate_primes
factorize
factorize!
prettify_factorization
```

## FRACTRAN algorithm

The FRACTRAN algorithm is implemented in [`fractran`](@ref) and its in-place cache-mutating version [`fractran!`](@ref).  Both functions are `export`ed.

```@docs
fractran
fractran!
```

## Example programs

FRACTRAN.jl bundles several example programs to showcase FRACTRAN.  All of them are `public` to prevent cluttering your namespace when `using FRACTRAN`.  All functions have a second form with exclamation mark that operate in-place on provided cache arguments.

### Addition program

```@docs
FRACTRAN.add
FRACTRAN.add!
```

### Subtraction program

```@docs
FRACTRAN.sub
FRACTRAN.sub!
```

### Multiplication program

```@docs
FRACTRAN.mul
FRACTRAN.mul!
```

### Division program

```@docs
FRACTRAN.divrem
FRACTRAN.divrem!
```

### PRIMEGAME program

```@docs
FRACTRAN.primegame
FRACTRAN.primegame!
```

## Cache variables

The two variables [`factorizations`](@ref) and [`primes`](@ref) serve as module-level caches for repeated calls to [`fractran`](@ref) and are declared `public`.

```@docs
factorizations
primes
```
