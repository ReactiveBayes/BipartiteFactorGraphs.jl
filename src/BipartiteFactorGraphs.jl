module BipartiteFactorGraphs

using Graphs
import Graphs:
    AbstractGraph,
    vertices,
    has_vertex,
    add_edge!,
    has_edge,
    edges,
    neighbors,
    nv,
    ne,
    all_neighbors,
    inneighbors,
    outneighbors,
    degree,
    indegree,
    outdegree,
    density,
    is_bipartite,
    is_directed

export BipartiteFactorGraph,
    add_variable!,
    add_factor!,
    get_variable_data,
    get_factor_data,
    get_edge_data,
    is_variable,
    is_factor,
    variables,
    factors,
    variable_neighbors,
    factor_neighbors,
    num_variables,
    num_factors,
    # Reexport used Graphs functions
    vertices,
    has_vertex,
    add_edge!,
    has_edge,
    edges,
    neighbors,
    nv,
    ne,
    all_neighbors,
    inneighbors,
    outneighbors,
    degree,
    indegree,
    outdegree,
    density,
    is_bipartite,
    is_directed

struct UnorderedPair{T}
    a::T
    b::T
end

Base.hash(p::UnorderedPair) = hash(p.a) + hash(p.b)
Base.:(==)(p1::UnorderedPair, p2::UnorderedPair) = (p1.a == p2.a && p1.b == p2.b) || (p1.a == p2.b && p1.b == p2.a)

"""
    BipartiteFactorGraph

A type-stable bipartite undirected factor graph implementation that stores data for variables, factors, and edges.
Users are responsible for maintaining the bipartite structure.

After the graph is constructed, the user can use `Graphs.is_bipartite(graph.graph)` to check if the graph is actually bipartite.
Certain functions may work incorrectly and produce unexpected results if the underlying graph is not bipartite.

# Fields
- `graph`: The underlying graph structure
- `variable_data`: A dictionary of data for variable nodes where the keys are elements of type `Int` and the values are of type `TVar`
- `factor_data`: A dictionary of data for factor nodes where the keys are elements of type `Int` and the values are of type `TFac`
- `edge_data`: A dictionary of data for edges between variables and factors where the keys are elements of type `UnorderedPair` and the values are of type `E`

!!! note
    Edge data keys are stored as `UnorderedPair`s to avoid duplicate entries or access errors. 
    This means that `get_edge_data(g, v1, v2)` is equivalent to `get_edge_data(g, v2, v1)`.
    This also implies that the graph is undirected.

To construct an empty BipartiteFactorGraph with specified variable, factor and edge data types use the following constructor:

```julia
BipartiteFactorGraph(::Type{TVar}, ::Type{TFac}, ::Type{E}, dict_type::Type{D}=Dict) where {TVar,TFac,E,D}
```

# Arguments
- `TVar`: The type of the variable data
- `TFac`: The type of the factor data
- `E`: The type of the edge data
- `dict_type`: The type of the dictionary used to store the variable, factor and edge data (defaults to Base.Dict)

As an alternative to the constructor, you can use `BipartiteFactorGraph()` as an alias to `BipartiteFactorGraph(Any, Any, Any, Dict)`.

# Example
```jldoctest
julia> g = BipartiteFactorGraph(Int, Float64, String, Dict)
BipartiteFactorGraph{Int64, Float64, String} with 0 variables, 0 factors, and 0 edges

julia> add_variable!(g, 1);

julia> add_factor!(g, 2.0);

julia> add_edge!(g, 1, 2, "Hello");

julia> g
BipartiteFactorGraph{Int64, Float64, String} with 1 variables, 1 factors, and 1 edges
```

"""
struct BipartiteFactorGraph{
    TVar,
    TFac,
    E,
    DVars <: AbstractDict{Int, TVar},
    DFacs <: AbstractDict{Int, TFac},
    DE <: AbstractDict{UnorderedPair{Int}, E}
} <: AbstractGraph{Int}
    graph::SimpleGraph{Int}
    variable_data::DVars
    factor_data::DFacs
    edge_data::DE
end

function BipartiteFactorGraph()
    return BipartiteFactorGraph(Any, Any, Any, Dict)
end

function BipartiteFactorGraph(::Type{TVar}, ::Type{TFac}, ::Type{E}, dict_type::Type{D} = Dict) where {TVar, TFac, E, D}
    VariableDictType = make_dict_type(dict_type, Int, TVar)
    FactorDictType = make_dict_type(dict_type, Int, TFac)
    EdgeDictType = make_dict_type(dict_type, UnorderedPair{Int}, E)
    return BipartiteFactorGraph{TVar, TFac, E, VariableDictType, FactorDictType, EdgeDictType}(
        SimpleGraph{Int}(), VariableDictType(), FactorDictType(), EdgeDictType()
    )
end

make_dict_type(::Type{D}, ::Type{K}, ::Type{V}) where {D <: AbstractDict, K, V} = D{K, V}
make_dict_type(::Type{D}, ::Type{K}, ::Type{V}) where {D, K, V} = throw(
    ArgumentError("Unsupported dictionary type: $D. Must be a subtype of AbstractDict.")
)

function Base.show(io::IO, g::BipartiteFactorGraph{TVar, TFac, E}) where {TVar, TFac, E}
    n_variables = length(g.variable_data)
    n_factors = length(g.factor_data)
    n_edges = length(g.edge_data)

    print(io, "BipartiteFactorGraph{$TVar, $TFac, $E} with ")
    print(io, "$n_variables variables, $n_factors factors, and $n_edges edges")
end

Base.broadcastable(g::BipartiteFactorGraph) = Ref(g)

"""
    add_variable!(g::BipartiteFactorGraph{TVar}, data::TVar) where {TVar}

Add a variable node to the graph with associated data and return its ID.
"""
function add_variable!(g::BipartiteFactorGraph{TVar}, data::TVar) where {TVar}
    Graphs.add_vertex!(g.graph)
    v = Graphs.nv(g.graph)
    g.variable_data[v] = data
    return v
end

"""
    add_factor!(g::BipartiteFactorGraph{TVar,TFac}, data::TFac) where {TVar,TFac}

Add a factor node to the graph with associated data and return its ID.
"""
function add_factor!(g::BipartiteFactorGraph{TVar, TFac}, data::TFac) where {TVar, TFac}
    Graphs.add_vertex!(g.graph)
    v = Graphs.nv(g.graph)
    g.factor_data[v] = data
    return v
end

"""
    add_edge!(g::BipartiteFactorGraph{TVar,TFac,E}, var::Int, fac::Int, data::E) where {TVar,TFac,E}

Add an edge between variable node `var` and factor node `fac` with associated data.
User must ensure that `var` is a variable node and `fac` is a factor node.
Edge data is stored with the original order of vertices (var, fac), but can be accessed
in either order using get_edge_data.
"""
function add_edge!(g::BipartiteFactorGraph{TVar, TFac, E}, var::Int, fac::Int, data::E) where {TVar, TFac, E}
    if Graphs.add_edge!(g.graph, var, fac)
        p = UnorderedPair(var, fac)
        g.edge_data[p] = data
        return true
    end
    return false
end

"""
    get_variable_data(g::BipartiteFactorGraph{TVar}, v::Int) where {TVar}

Get data associated with variable node v.
"""
function get_variable_data(g::BipartiteFactorGraph{TVar}, v::Int) where {TVar}
    return g.variable_data[v]
end

"""
    get_factor_data(g::BipartiteFactorGraph{TVar,TFac}, v::Int) where {TVar,TFac}

Get data associated with factor node v.
"""
function get_factor_data(g::BipartiteFactorGraph{TVar, TFac}, v::Int) where {TVar, TFac}
    return g.factor_data[v]
end

"""
    get_edge_data(g::BipartiteFactorGraph{TVar,TFac,E}, v1::Int, v2::Int) where {TVar,TFac,E}

Get data associated with edge between nodes `v1` and `v2`.
Since the graph is undirected, the order of `v1` and `v2` doesn't matter.
"""
function get_edge_data(g::BipartiteFactorGraph{TVar, TFac, E}, v1::Int, v2::Int) where {TVar, TFac, E}
    # Try both orderings since we're dealing with an undirected graph
    p = UnorderedPair(v1, v2)
    return g.edge_data[p]
end

"""
    neighbors(g::BipartiteFactorGraph, v::Int)

Get all neighbors of node v.
"""
function neighbors(g::BipartiteFactorGraph, v::Int)
    return Graphs.neighbors(g.graph, v)
end

"""
    is_variable(g::BipartiteFactorGraph, v::Int)

Check if node v is a variable node.
"""
function is_variable(g::BipartiteFactorGraph, v::Int)
    return haskey(g.variable_data, v)
end

"""
    is_factor(g::BipartiteFactorGraph, v::Int)

Check if node v is a factor node.
"""
function is_factor(g::BipartiteFactorGraph, v::Int)
    return haskey(g.factor_data, v)
end

"""
    variables(g::BipartiteFactorGraph)

Get all variable nodes in the graph.
"""
variables(g::BipartiteFactorGraph) = keys(g.variable_data)

"""
    factors(g::BipartiteFactorGraph)

Get all factor nodes in the graph.
"""
factors(g::BipartiteFactorGraph) = keys(g.factor_data)

"""
    variable_neighbors(g::BipartiteFactorGraph, v::Int)

Get all variable neighbors of factor node v.
Returns only neighbors that are variable nodes.
Note that this is equivalent to `neighbors(g, v)` with extra check that the node is a factor.
Use `neighbors(g, v)` for a version that does not check the node type.
"""
function variable_neighbors(g::BipartiteFactorGraph, v::Int)
    if !is_factor(g, v)
        throw(ArgumentError("Node $v is not a factor node"))
    end
    return neighbors(g, v)
end

"""
    factor_neighbors(g::BipartiteFactorGraph, v::Int)

Get all factor neighbors of variable node v.
Returns only neighbors that are factor nodes.
Note that this is equivalent to `neighbors(g, v)` with extra check that the node is a variable.
Use `neighbors(g, v)` for a version that does not check the node type.
"""
function factor_neighbors(g::BipartiteFactorGraph, v::Int)
    if !is_variable(g, v)
        throw(ArgumentError("Node $v is not a variable node"))
    end
    return neighbors(g, v)
end

"""
    num_variables(g::BipartiteFactorGraph)

Get the number of variable nodes in the graph.
"""
num_variables(g::BipartiteFactorGraph) = length(g.variable_data)

"""
    num_factors(g::BipartiteFactorGraph)

Get the number of factor nodes in the graph.
"""
num_factors(g::BipartiteFactorGraph) = length(g.factor_data)

"""
    vertices(g::BipartiteFactorGraph)

Get all vertices in the graph. Note, that it returns vertices that represent both variable and factor nodes.
Use [`variables`](@ref) and [`factors`](@ref) to get only variable or factor nodes.
"""
function Graphs.vertices(g::BipartiteFactorGraph)
    return Graphs.vertices(g.graph)
end

"""
    has_vertex(g::BipartiteFactorGraph, v::Int)

Check if vertex `v` is in the graph. Note, that it returns true for both variable and factor nodes.
Use [`is_variable`](@ref) and [`is_factor`](@ref) to check existence of a node with a specific type.
"""
function Graphs.has_vertex(g::BipartiteFactorGraph, v::Int)
    return Graphs.has_vertex(g.graph, v)
end

"""
    has_edge(g::BipartiteFactorGraph, var::Int, fac::Int)

Check if there is an edge between variable node `var` and factor node `fac`.
"""
function has_edge(g::BipartiteFactorGraph, var::Int, fac::Int)
    return Graphs.has_edge(g.graph, var, fac)
end

"""
    edges(g::BipartiteFactorGraph)

Get all edges in the graph. 

!!! note 
    This function behaves differently from `variables` and `factors` in that it calls `Graphs.edges`. 
    The closest equivalent for nodes is the `neighbors` function.
"""
edges(g::BipartiteFactorGraph) = Graphs.edges(g.graph)

# Additional functions from Graphs.jl API

"""
    nv(g::BipartiteFactorGraph)

Return the total number of vertices in the graph.
This is the sum of variable and factor nodes.
"""
function nv(g::BipartiteFactorGraph)
    return Graphs.nv(g.graph)
end

"""
    ne(g::BipartiteFactorGraph)

Return the number of edges in the graph.
"""
function ne(g::BipartiteFactorGraph)
    return Graphs.ne(g.graph)
end

"""
    all_neighbors(g::BipartiteFactorGraph, v::Int)

Return a list of all neighbors of vertex `v` in graph `g`.
This is equivalent to `neighbors(g, v)` for undirected graphs.
"""
function all_neighbors(g::BipartiteFactorGraph, v::Int)
    return Graphs.neighbors(g.graph, v)
end

"""
    inneighbors(g::BipartiteFactorGraph, v::Int)

Return a list of all in-neighbors of vertex `v` in graph `g`.
"""
function inneighbors(g::BipartiteFactorGraph, v::Int)
    return Graphs.inneighbors(g.graph, v)
end

"""
    outneighbors(g::BipartiteFactorGraph, v::Int)

Return a list of all out-neighbors of vertex `v` in graph `g`.
"""
function outneighbors(g::BipartiteFactorGraph, v::Int)
    return Graphs.outneighbors(g.graph, v)
end

"""
    degree(g::BipartiteFactorGraph[, v])

Return a vector corresponding to the number of edges connected to each vertex in graph `g`.
If `v` is specified, only return the degree for vertex `v`.
"""
function degree(g::BipartiteFactorGraph, v::Int)
    return Graphs.degree(g.graph, v)
end

function degree(g::BipartiteFactorGraph)
    return Graphs.degree(g.graph)
end

"""
    indegree(g::BipartiteFactorGraph[, v])

For BipartiteFactorGraph this is identical to `degree` since the graph is undirected.
"""
function indegree(g::BipartiteFactorGraph, v::Int)
    return Graphs.degree(g.graph, v)
end

function indegree(g::BipartiteFactorGraph)
    return Graphs.degree(g.graph)
end

"""
    outdegree(g::BipartiteFactorGraph[, v])

For BipartiteFactorGraph this is identical to `degree` since the graph is undirected.
"""
function outdegree(g::BipartiteFactorGraph, v::Int)
    return Graphs.degree(g.graph, v)
end

function outdegree(g::BipartiteFactorGraph)
    return Graphs.degree(g.graph)
end

"""
    density(g::BipartiteFactorGraph)

Return the density of the graph. 

For bipartite graphs, density is defined as the ratio of the number of 
actual edges to the maximum possible number of edges between variable and factor nodes
(which is num_variables(g) * num_factors(g)).
"""
function density(g::BipartiteFactorGraph)
    if num_variables(g) == 0 || num_factors(g) == 0
        return 0.0
    end
    return Graphs.ne(g.graph) / (num_variables(g) * num_factors(g))
end

"""
    is_bipartite(g::BipartiteFactorGraph)

Check if the graph is bipartite.
"""
function is_bipartite(g::BipartiteFactorGraph)
    return Graphs.is_bipartite(g.graph)
end

"""
    is_directed(g::BipartiteFactorGraph)

Check if the graph is directed. For BipartiteFactorGraph this is always false since the graph is undirected.
"""
function is_directed(g::BipartiteFactorGraph)
    return false
end

end # module
