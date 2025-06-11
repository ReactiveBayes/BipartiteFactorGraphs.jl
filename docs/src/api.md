# API Reference

```@meta
CurrentModule = BipartiteFactorGraphs
```

## Core Types

```@docs
BipartiteFactorGraph
```

## Graph Construction

Functions for creating and modifying graphs:

```@docs
add_variable!
add_factor!
add_edge!
```

## Data Access

Retrieve data associated with nodes and edges:

```@docs
get_variable_data
get_factor_data
get_edge_data
```

## Graph Query Functions

Functions that query the structure of the bipartite factor graph:

```@docs
is_variable
is_factor
variables
factors
variable_neighbors
factor_neighbors
num_variables
num_factors
```

## Graph Properties

Functions that compute properties of the graph:

```@docs
nv
ne
vertices
has_vertex
has_edge
edges
neighbors
all_neighbors
inneighbors
outneighbors
degree
indegree
outdegree
density
is_bipartite
is_directed
``` 