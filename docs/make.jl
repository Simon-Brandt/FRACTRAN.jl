#!/usr/bin/env julia

# Author: Simon Brandt
# E-Mail: simon.brandt@uni-greifswald.de
# Last Modification: 2026-09-09
# License: Public Domain

using Documenter

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
        "API reference" => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/Simon-Brandt/FRACTRAN.jl",
    devbranch="main",
)
