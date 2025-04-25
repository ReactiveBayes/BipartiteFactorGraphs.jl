# Usage Guide

This guide demonstrates how to use BipartiteFactorGraphs.jl effectively for different applications.

## Basic Usage

### Creating a Graph

First, create a bipartite factor graph with the desired data types:

```julia
using BipartiteFactorGraphs

# Create a graph with Float64 for variable data, String for factor data, 
# and Int for edge data
g = BipartiteFactorGraph{Float64, String, Int}()
```

The type parameters specify:
1. The type for variable node data
2. The type for factor node data
3. The type for edge data

You can use any Julia type for these parameters, including custom types.

### Adding Nodes

Add variable and factor nodes with their associated data:

```julia
# Add variables
v1 = add_variable!(g, 1.0)  # returns vertex ID 1
v2 = add_variable!(g, 2.0)  # returns vertex ID 2

# Add factors
f1 = add_factor!(g, "sum")  # returns vertex ID 3
f2 = add_factor!(g, "product")  # returns vertex ID 4
```

### Connecting Nodes

Connect variable and factor nodes with edges containing data:

```julia
# Connect variables and factors
add_edge!(g, v1, f1, 10)  # Add edge between variable v1 and factor f1 with data 10
add_edge!(g, v2, f1, 20)
add_edge!(g, v2, f2, 30)
```

### Querying the Graph

```julia
# Get all variables and factors
all_vars = collect(variables(g))
all_factors = collect(factors(g))

# Check node types
println(is_variable(g, v1))  # true
println(is_factor(g, f1))    # true

# Get neighbors
var_neighbors = variable_neighbors(g, f1)  # Get variable neighbors of factor f1
fac_neighbors = factor_neighbors(g, v2)    # Get factor neighbors of variable v2

# Count nodes
println("Variables: ", num_variables(g))
println("Factors: ", num_factors(g))

# Get data
var_data = get_variable_data(g, v1)  # 1.0
fac_data = get_factor_data(g, f1)    # "sum"
edge_data = get_edge_data(g, v1, f1) # 10
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
g = BipartiteFactorGraph{VariableData, FactorData, EdgeData}()

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
g = BipartiteFactorGraph{Float64, String, Int}(Dictionary)
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
g = BipartiteFactorGraph{Vector{Float64}, Function, Matrix{Float64}}()

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