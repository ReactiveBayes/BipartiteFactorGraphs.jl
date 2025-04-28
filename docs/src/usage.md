# Usage Guide

This guide demonstrates how to use BipartiteFactorGraphs.jl effectively for different applications.

## Basic Usage

### Creating a Graph

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

### Adding Nodes

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

### Connecting Nodes

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

## Querying the Graph

BipartiteFactorGraphs.jl provides several functions to query the graph structure and retrieve information about nodes and their connections:

### Getting all variable and associated data

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

### Getting all factor and associated data

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

### Checking node types

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

### Getting neighbors

See [`neighbors`](@ref), [`variable_neighbors`](@ref), and [`factor_neighbors`](@ref)

```@example usage
@test Set(variable_neighbors(g, f1)) == Set([v1, v2]) #hide
variable_neighbors(g, f1)  # Get variable neighbors of factor f1
```

```@example usage
@test Set(factor_neighbors(g, v1)) == Set([f1]) #hide
factor_neighbors(g, v1)  # Get factor neighbors of variable v1
```

### Getting the number of nodes

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

### Getting the number of edges

See [`ne`](@ref) and [`edges`](@ref)

```@example usage
@test ne(g) == 3 #hide
ne(g)
```

```@example usage
@test length(edges(g)) == 3 #hide
length(edges(g))
```

### Getting data of edges 

See [`get_edge_data`](@ref)

```@example usage
@test get_edge_data(g, v1, f1) == 10 #hide
get_edge_data(g, v1, f1)
```

## Advanced Usage

### Custom Data Types

You can use custom types for variables, factors, and edges:

```julia
struct VariableData
    name::String
    value::Float64
    domain::Vector{Float64}
end

struct FactorData
    function_type::Symbol
    parameters::Dict{Symbol, Any}
end

struct EdgeData
    weight::Float64
    metadata::Dict{Symbol, Any}
end

# Create graph with custom types
g = BipartiteFactorGraph(VariableData, FactorData, EdgeData)

# Add variable with custom data
var_data = VariableData("x1", 0.5, [-1.0, 1.0])
v1 = add_variable!(g, var_data)

# Add factor with custom data
factor_data = FactorData(:gaussian, Dict(:mean => 0.0, :variance => 1.0))
f1 = add_factor!(g, factor_data)

# Add edge with custom data
edge_data = EdgeData(1.0, Dict(:message => "hello"))
add_edge!(g, v1, f1, edge_data)
```

### Using a Different Dictionary Type

By default, BipartiteFactorGraph uses `Dict` to store node and edge data. You can specify a different dictionary type:

```julia
using Dictionaries  # Make sure to add this package to your project

# Create a graph using Dictionaries.jl
g = BipartiteFactorGraph(Float64, String, Int, Dictionary)
```

## Performance Tips

For large graphs, consider the following performance optimizations:

1. Preallocate arrays when iterating over many nodes
2. Use specific queries (like `variable_neighbors`) instead of filtering general results
3. Create separate graphs for different data domains if appropriate
4. For very large graphs, consider specialized dictionary types optimized for your use case

## Example: Simple Inference on a Factor Graph

Here's a simple example of how BipartiteFactorGraphs might be used in a belief propagation algorithm:

```julia
using BipartiteFactorGraphs
using LinearAlgebra

# Create a simple Gaussian factor graph
g = BipartiteFactorGraph(Vector{Float64}, Function, Matrix{Float64})

# Add variable nodes (mean and covariance)
v1 = add_variable!(g, [0.0, 0.0])  # Prior belief
v2 = add_variable!(g, [0.0, 0.0])  # Prior belief

# Add factor nodes (functions that compute messages)
f_prior = add_factor!(g, x -> exp(-0.5 * dot(x, x)))  # Prior factor (zero mean, unit covariance)
f_likelihood = add_factor!(g, (x, y) -> exp(-0.5 * norm(y - x)^2))  # Likelihood factor

# Add edges with covariances
add_edge!(g, v1, f_prior, Matrix(1.0I, 2, 2))
add_edge!(g, v1, f_likelihood, Matrix(1.0I, 2, 2))
add_edge!(g, v2, f_likelihood, Matrix(1.0I, 2, 2))

# Perform simple message passing (in a real implementation, this would be more complex)
function update_beliefs!(g)
    # Update variable beliefs based on connected factors
    for v in variables(g)
        factors = factor_neighbors(g, v)
        new_belief = zeros(length(get_variable_data(g, v)))
        
        for f in factors
            # In a real implementation, compute messages from factors
            # Here we just illustrate the pattern
            factor_fn = get_factor_data(g, f)
            edge_info = get_edge_data(g, v, f)
            
            # Update beliefs using the factor and edge data
            # (simplified for illustration)
            new_belief += edge_info * ones(size(edge_info, 1))
        end
        
        # In a real implementation, we would update the variable data here
        println("New belief for variable $v: $new_belief")
    end
end

# Run one iteration of belief update
update_beliefs!(g)
``` 