using FRACTRAN
using Documenter

DocMeta.setdocmeta!(FRACTRAN, :DocTestSetup, :(using FRACTRAN); recursive=true)

makedocs(;
    modules=[FRACTRAN],
    authors="Simon Brandt <simon.brandt@uni-greifswald.de> and contributors",
    sitename="FRACTRAN.jl",
    format=Documenter.HTML(;
        canonical="https://Simon-Brandt.github.io/FRACTRAN.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Simon-Brandt/FRACTRAN.jl",
    devbranch="main",
)
