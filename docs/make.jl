#!/usr/bin/env julia

# Author: Simon Brandt
# E-Mail: simon.brandt@uni-greifswald.de
# Last Modification: 2026-09-15
# License: Public Domain

using Documenter
using DocumenterCodeBlocks

using FRACTRAN

DocMeta.setdocmeta!(FRACTRAN, :DocTestSetup, :(using FRACTRAN); recursive=true)

makedocs(;
    modules=[FRACTRAN],
    authors="Simon Brandt <simon.brandt@uni-greifswald.de> and contributors",
    sitename="FRACTRAN.jl",
    format=Documenter.HTML(;
        canonical="https://Simon-Brandt.github.io/FRACTRAN.jl",
        edit_link="main",
        assets=String[],
        prettyurls=false,  # TODO: Remove.
    ),
    pages=[
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API reference" => "reference.md",
    ],
    plugins=[CodeBlocks()],
)

deploydocs(;
    repo="github.com/Simon-Brandt/FRACTRAN.jl",
    devbranch="main",
)
