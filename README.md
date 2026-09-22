<!--
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
-->

# FRACTRAN.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Simon-Brandt.github.io/FRACTRAN.jl/dev/)
[![Build Status](https://github.com/Simon-Brandt/FRACTRAN.jl/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Simon-Brandt/FRACTRAN.jl/actions/workflows/ci.yaml?query=branch%3Amain)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

FRACTRAN.jl is a Julia implementation of [John Conway](https://en.wikipedia.org/wiki/John_Horton_Conway)'s 1986/1987[^Conway1987] esoteric programming language [FRACTRAN](https://en.wikipedia.org/wiki/FRACTRAN).  Take a (positive) start integer and a bunch of carefully chosen fractions and get an integer returned as the algorithm's result—that's FRACTRAN!

[^Conway1987]: Conway, J.H. FRACTRAN: A Simple Universal Programming Language for Arithmetic. In: Cover, T.M., Gopinath, B. (eds) Open Problems in Communication and Computation. Springer 1987, [10.1007/978-1-4612-4808-8_2](https://doi.org/10.1007/978-1-4612-4808-8_2).

## Usage

Install FRACTRAN.jl from the [General](https://github.com/JuliaRegistries/General) registry using [Pkg](https://github.com/JuliaLang/Pkg.jl):

```julia-repl
pkg> add FRACTRAN
...
```

Then, `using` and `import`ing FRACTRAN.jl is simply:

```julia-repl
julia> using FRACTRAN
...

# Or:
julia> import FRACTRAN
...
```

Now, you can define a start number and a `Tuple` of fractions, and pass them to `fractran`.  You can pipe the result to `FRACTRAN.factorize` to obtain the factorization to read out the FRACTRAN registers, and pipe the latter to `FRACTRAN.prettify_factorization` to get a prettified string representation:

```julia-repl
julia> n = 2^3 * 3^4
648

julia> fractions = (2//3,)
(2//3,)

julia> result = fractran(n, fractions)
128

julia> factors = FRACTRAN.factorize(result)
DataStructures.Accumulator{Int64, Int64} with 1 entry:
  2 => 7

julia> FRACTRAN.prettify_factorization(factors)
"2⁷"

# Alternatively, shorter:
julia> fractran(n, fractions) |> FRACTRAN.factorize |> FRACTRAN.prettify_factorization
"2⁷"
```

What does the result mean? We passed $2^3 \cdot 3^4$ to the FRACTRAN program $\frac{2}{3}$ and obtained $2^7$—suggesting the program works as an adder of the exponents.  The [tutorial](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/tutorial/#FRACTRAN-implementation) contains the explanation for this.

For any "serious" FRACTRAN.jl applications, you should read the extensive docstrings or consult the [documentation](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/), which contains more examples of all functions.  But note that FRACTRAN is slow, and thus not suitable for production environments.

## Documentation

The [documentation](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/) contains a [tutorial](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/tutorial/) on how to use FRACTRAN.jl, as well as the [API reference](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/reference/).

## License

FRACTRAN.jl is licensed under the terms and conditions of the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).  This applies to all files except the mainly [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl)-generated documentation's [`make.jl`](docs/make.jl), which is placed in the Public Domain.

The Apache License v2.0 allows running, modifying, and distributing FRACTRAN.jl, even in commercial settings, provided that the license is distributed along the source code or compiled objects.  *(This is not legal advice.  Read the [license](LICENSE) for the exact terms.)*

## Contributions

Please open an [issue](https://github.com/Simon-Brandt/FRACTRAN.jl/issues/new) if you:

- found a bug in FRACTRAN.jl
- discovered an error in the [documentation](https://Simon-Brandt.github.io/FRACTRAN.jl/stable/) (even a spelling or grammar mistake!)
- want to propose a new feature
- want to contribute code (please don't start a pull request prior opening an issue)
- need help with running FRACTRAN.jl, after having consulted the docs to no avail
- want to enhance the documentation

You're invited to fix issues yourself, especially trivial mistakes in the docs.  To this end, [fork](https://github.com/Simon-Brandt/FRACTRAN.jl/fork) the repository, make the necessary changes, and open a [pull request (PR)](https://github.com/Simon-Brandt/FRACTRAN.jl/compare) to merge your changes.

Prior committing non-trivial edits, especially for code, please make sure to have read and followed the [contribution guidelines](CONTRIBUTING.md).  This makes it easier to merge the modifications.
