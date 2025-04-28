# Basic Usage

This guide demonstrates how to use BipartiteFactorGraphs.jl effectively for different applications.

## Creating a Graph

First, create a [bipartite factor graph](@ref BipartiteFactorGraph) with the desired data types:

```@example usage
using BipartiteFactorGraphs
using Test #hide

# Create a graph with Float64 for variable data, String for factor data, 
# and Int for edge data
g = BipartiteFactorGraph(Float64, String, Int)
@test g isa BipartiteFactorGraph{Float64, String, Int} #hide

show(g)
```

The type parameters specify:
1. The type for variable node data
2. The type for factor node data
3. The type for edge data

You can use any Julia type for these parameters, including custom types.

## Adding Nodes

Add variable and factor nodes with their associated data using the [`add_variable!`](@ref) and [`add_factor!`](@ref) functions:

```@example usage
# Add variables
v1 = add_variable!(g, 1.0)  # returns vertex ID 1
v2 = add_variable!(g, 2.0)  # returns vertex ID 2

# Add factors
f1 = add_factor!(g, "sum")  # returns vertex ID 3
f2 = add_factor!(g, "product")  # returns vertex ID 4

@test length(variables(g)) == 2 #hide
@test length(factors(g)) == 2 #hide
@test nv(g) == 4 #hide

show(g)
```

## Connecting Nodes

Connect variable and factor nodes with edges containing data with the [`add_edge!`](@ref) function:

```@example usage
# Connect variables and factors
add_edge!(g, v1, f1, 10)  # Add edge between variable v1 and factor f1 with data 10
add_edge!(g, v2, f1, 20)
add_edge!(g, v2, f2, 30)

@test has_edge(g, v1, f1) #hide
@test has_edge(g, v2, f1) #hide
@test has_edge(g, v2, f2) #hide
@test ne(g) == 3 #hide
@test length(edges(g)) == 3 #hide

show(g)
```

!!! warning 
    You are responsible for maintaining the bipartite structure of the graph. The package does not prevent you from adding edges between two variables or two factors, but doing so violates the bipartite property. Always ensure that edges only connect variable nodes to factor nodes. You can use the `Graphs.is_bipartite` function to check if the graph is bipartite.
    ```@example usage
    BipartiteFactorGraphs.is_bipartite(g)
    ```
    Failing to ensure the bipartite property will most likely lead to wrong results or undefined behavior.

```@example usage
has_edge(g, v1, f1)
```

```@example usage
has_edge(g, v1, f2)
```

## Querying the Graph

BipartiteFactorGraphs.jl provides several functions to query the graph structure and retrieve information about nodes and their connections:

## Getting all variable and associated data

See [`variables`](@ref) and [`get_variable_data`](@ref)

```@example usage
@test Set(variables(g)) == Set([v1, v2]) #hide
# Get all variables
variables(g)
```

```@example usage 
@test Set(get_variable_data.(g, variables(g))) == Set([1.0, 2.0]) #hide
get_variable_data.(g, variables(g))
```

```@example usage
@test get_variable_data(g, v1) == 1.0 #hide
get_variable_data(g, v1)
```

## Getting all factor and associated data

See [`factors`](@ref) and [`get_factor_data`](@ref)

```@example usage
@test Set(factors(g)) == Set([f1, f2]) #hide
# Get all factors
factors(g)
```

```@example usage
@test Set(get_factor_data.(g, factors(g))) == Set(["sum", "product"]) #hide
get_factor_data.(g, factors(g))
```

```@example usage
@test get_factor_data(g, f1) == "sum" #hide
get_factor_data(g, f1)
```

## Checking node types

See [`is_variable`](@ref) and [`is_factor`](@ref)

```@example usage
@test is_variable(g, v1) #hide
@test !is_factor(g, v1) #hide
is_variable(g, v1), is_factor(g, v1)
```

```@example usage
@test is_factor(g, f1) #hide
@test !is_variable(g, f1) #hide
is_factor(g, f1), is_variable(g, f1)
```

## Getting neighbors

See [`neighbors`](@ref), [`variable_neighbors`](@ref), and [`factor_neighbors`](@ref)

```@example usage
@test Set(variable_neighbors(g, f1)) == Set([v1, v2]) #hide
variable_neighbors(g, f1)  # Get variable neighbors of factor f1
```

```@example usage
@test Set(factor_neighbors(g, v1)) == Set([f1]) #hide
factor_neighbors(g, v1)  # Get factor neighbors of variable v1
```

## Getting the number of nodes

See [`nv`](@ref), [`num_variables`](@ref), and [`num_factors`](@ref)

```@example usage
@test nv(g) == 4 #hide
nv(g)
```

```@example usage
@test num_variables(g) == 2 #hide
num_variables(g)
```

```@example usage
@test num_factors(g) == 2 #hide
num_factors(g)
```

## Getting the number of edges

See [`ne`](@ref) and [`edges`](@ref)

```@example usage
@test ne(g) == 3 #hide
ne(g)
```

```@example usage
@test length(edges(g)) == 3 #hide
length(edges(g))
```

## Getting data of edges 

See [`get_edge_data`](@ref)

```@example usage
@test get_edge_data(g, v1, f1) == 10 #hide
get_edge_data(g, v1, f1)
```