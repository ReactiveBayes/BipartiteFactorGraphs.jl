# BipartiteFactorGraphs.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://reactiveBayes.github.io/BipartiteFactorGraphs.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://reactiveBayes.github.io/BipartiteFactorGraphs.jl/dev/)
[![Build Status](https://github.com/ReactiveBayes/BipartiteFactorGraphs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ReactiveBayes/BipartiteFactorGraphs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ReactiveBayes/BipartiteFactorGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ReactiveBayes/BipartiteFactorGraphs.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A Julia package for working with bipartite factor graphs, providing efficient data structures and algorithms for graph-based probabilistic inference.

## Installation

```julia
using Pkg
Pkg.add("BipartiteFactorGraphs")
```

Or in Julia REPL press `]` to enter Pkg mode:

```julia
] add BipartiteFactorGraphs
```

## Features

- Flexible representation of bipartite factor graphs
- Efficient manipulation of graph structure
- Support for common graph operations
- Type-stable implementation for performance

## Basic Usage

```julia
using BipartiteFactorGraphs

# Create a new factor graph
g = BipartiteFactorGraph()

# Add variable and factor nodes
v1 = add_variable!(g)
v2 = add_variable!(g)
f1 = add_factor!(g, [v1, v2])

# Check connectivity
@assert is_connected(v1, f1)
@assert is_connected(v2, f1)

# Access node neighbors
neighbors_of_v1 = neighbors(g, v1)
neighbors_of_f1 = neighbors(g, f1)

# Get graph properties
@assert num_variables(g) == 2
@assert num_factors(g) == 1
```

## Documentation

For more detailed information about the package functionality, please refer to the [documentation](https://reactiveBayes.github.io/BipartiteFactorGraphs.jl/stable/).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This package is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.