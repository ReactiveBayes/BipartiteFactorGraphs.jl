# Advanced Usage

## Custom Data Types

You can use custom types for variables, factors, and edges:

```@example advanced
using BipartiteFactorGraphs
using Test #hide

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
@test BipartiteFactorGraph(VariableData, FactorData, EdgeData) isa BipartiteFactorGraph{VariableData, FactorData, EdgeData} #hide
g = BipartiteFactorGraph(VariableData, FactorData, EdgeData)
```

```@example advanced
# Add variable with custom data
var_data = VariableData("x1", 0.5, [-1.0, 1.0])
v1 = add_variable!(g, var_data)

# Add factor with custom data
factor_data = FactorData(:gaussian, Dict(:mean => 0.0, :variance => 1.0))
f1 = add_factor!(g, factor_data)

# Add edge with custom data
edge_data = EdgeData(1.0, Dict(:message => "hello"))
add_edge!(g, v1, f1, edge_data)

@test get_variable_data(g, v1) == var_data #hide
@test get_factor_data(g, f1) == factor_data #hide
@test get_edge_data(g, v1, f1) == edge_data #hide

nothing #hide
```

### Using a Different Dictionary Type

By default, BipartiteFactorGraph uses `Dict` to store node and edge data. You can specify a different dictionary type. For example, the package implements an extension for the `Dictionaries.jl` package.

!!! note
    Dictionaries.jl do not subtype from the `AbstractDict` type, so internally `BipartiteFactorGraph` wraps the dictionary in a special wrapper type that implements the `AbstractDict` interface.

```@example advanced
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