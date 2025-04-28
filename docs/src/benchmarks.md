# Performance Benchmarks

BipartiteFactorGraphs.jl is designed for high performance. This page summarizes benchmark results and performance characteristics.

## Benchmark Overview

The benchmarks measure the performance of BipartiteFactorGraphs.jl for various operations across different graph sizes and densities. The benchmark suite evaluates:

1. **Graph creation**: Creating empty graphs and building graphs of different sizes
2. **Bulk operations**: Adding many nodes and edges at once
3. **Iteration**: Traversing variables, factors, and their neighbors
4. **Random access**: Accessing node and edge data randomly
5. **Queries**: Performance of different graph queries

## Running Benchmarks

You can run the benchmarks yourself using:

```julia
make benchmark
```

To compare benchmark results against a specific branch:

```julia
make benchmark-compare branch=main
```

## Benchmark Configuration

Benchmarks are run with the following configurations:

### Graph Sizes
- **Small**: 100 variables, 50 factors
- **Medium**: 1,000 variables, 500 factors
- **Large**: 10,000 variables, 5,000 factors

### Edge Densities
- **Sparse**: Average of 2 connections per node
- **Medium**: Average of 5 connections per node
- **Dense**: Average of 10 connections per node

## Scaling Behavior

BipartiteFactorGraphs.jl is designed to scale well with graph size and density:

- **Graph creation**: Scales linearly with the number of nodes and edges
- **Node access**: Constant time regardless of graph size
- **Edge access**: Constant time regardless of graph size
- **Neighbor iteration**: Scales linearly with the number of neighbors

## Performance Tips

For optimal performance with BipartiteFactorGraphs.jl:

1. **Type stability**: Always provide concrete types when creating a BipartiteFactorGraph
2. **Dictionary choice**: For very large graphs, consider using specialized dictionary types
3. **Specialized queries**: Use the specialized neighbor functions (`variable_neighbors`, `factor_neighbors`) rather than general neighbors and filtering
4. **Preallocation**: Preallocate arrays when performing operations on many nodes

## Comparison to Alternative Implementations

BipartiteFactorGraphs.jl offers superior performance compared to generic graph implementations when working with bipartite factor graphs:

- More efficient storage of factor and variable data
- Specialized functions optimized for bipartite operations
- Type stability for better compiler optimization
- Minimal memory overhead

## Benchmark Details

For more details on the benchmarking methodology, see the benchmark code in the `benchmark/` directory of the repository. 