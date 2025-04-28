```@meta
CurrentModule = BipartiteFactorGraphs
```

# BipartiteFactorGraphs.jl

*A performant implementation of bipartite factor graphs in Julia*

## Overview

BipartiteFactorGraphs.jl provides a type-stable implementation of bipartite factor graphs built on top of [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl). The package is designed for high performance while maintaining a clean, intuitive API.

Bipartite factor graphs are a specialized type of graph where nodes are divided into two distinct sets:
- **Variable nodes**: Represent variables in a probabilistic model
- **Factor nodes**: Represent relationships or constraints between variables

This structure is particularly useful for probabilistic graphical models, Bayesian inference, message passing algorithms, factor graph algorithms, and more.

## Key Features

- Type-stable implementation with parametric types for variables, factors, and edges
- Efficient data storage and retrieval for node and edge properties
- Specialized query functions for bipartite factor graphs
- Compatible with the Graphs.jl ecosystem

## Installation

```julia
using Pkg
Pkg.add("BipartiteFactorGraphs")
```
or via the Julia REPL:

```julia
] add BipartiteFactorGraphs
```

## Quick Start

Here's a simple example demonstrating how to create and work with a bipartite factor graph:

```@example quickstart
using BipartiteFactorGraphs

# Create a graph with Float64 variable data, String factor data, and Int edge data
g = BipartiteFactorGraph(Float64, String, Int)

# Add variables
v1 = add_variable!(g, 1.0)
v2 = add_variable!(g, 2.0)
v3 = add_variable!(g, 3.0)

# Add factors
f1 = add_factor!(g, "sum")
f2 = add_factor!(g, "product")

# Connect variables and factors with edges
add_edge!(g, v1, f1, 10)
add_edge!(g, v2, f1, 20)
add_edge!(g, v2, f2, 30)
add_edge!(g, v3, f2, 40)

# Query the graph
println("Number of variables: ", num_variables(g))
println("Number of factors: ", num_factors(g))
println("Neighbors of factor f1: ", variable_neighbors(g, f1))
println("Edge data between v2 and f1: ", get_edge_data(g, v2, f1))
```

## Where to go next?

```@contents
Pages = [
    "usage.md",
    "api.md",
    "benchmarks.md"
]
Depth = 2
```

## Index

```@index
```
