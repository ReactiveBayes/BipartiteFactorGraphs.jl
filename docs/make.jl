using BipartiteFactorGraphs
using Documenter

DocMeta.setdocmeta!(BipartiteFactorGraphs, :DocTestSetup, :(using BipartiteFactorGraphs); recursive = true)

makedocs(;
    modules = [BipartiteFactorGraphs],
    authors = "ReactiveBayes and contributors",
    sitename = "BipartiteFactorGraphs.jl",
    format = Documenter.HTML(;
        canonical = "https://ReactiveBayes.github.io/BipartiteFactorGraphs.jl", edit_link = "main", assets = String[]
    ),
    pages = ["Home" => "index.md"]
)

deploydocs(; repo = "github.com/ReactiveBayes/BipartiteFactorGraphs.jl", devbranch = "main")
