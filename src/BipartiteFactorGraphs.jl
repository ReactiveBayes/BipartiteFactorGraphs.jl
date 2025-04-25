module BipartiteFactorGraphs

using Graphs
import Graphs: add_edge!, has_edge, neighbors, nv, ne, all_neighbors, degree, indegree, outdegree, density

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
    add_edge!,
    has_edge,
    neighbors,
    nv,
    ne,
    all_neighbors,
    degree,
    indegree,
    outdegree,
    density

struct UnorderedPair{T}
    a::T
    b::T
end

Base.hash(p::UnorderedPair) = hash(p.a) + hash(p.b)
Base.:(==)(p1::UnorderedPair, p2::UnorderedPair) = (p1.a == p2.a && p1.b == p2.b) || (p1.a == p2.b && p1.b == p2.a)

"""
    BipartiteFactorGraph{TVar,TFac,E,DVars<:AbstractDict{Int,TVar},DFacs<:AbstractDict{Int,TFac},DE<:AbstractDict{Tuple{Int,Int},E}}

A type-stable bipartite factor graph implementation that stores data for variables, factors, and edges.
Users are responsible for maintaining the bipartite structure.

# Fields
- `graph::SimpleGraph{Int}`: The underlying graph structure
- `variable_data::DVars`: Data for variable nodes
- `factor_data::DFacs`: Data for factor nodes
- `edge_data::DE`: Data for edges between variables and factors
"""
struct BipartiteFactorGraph{
    TVar,
    TFac,
    E,
    DVars <: AbstractDict{Int, TVar},
    DFacs <: AbstractDict{Int, TFac},
    DE <: AbstractDict{UnorderedPair, E}
}
    graph::SimpleGraph{Int}
    variable_data::DVars
    factor_data::DFacs
    edge_data::DE
end

"""
    BipartiteFactorGraph{TVar,TFac,E}(dict_type=Dict) where {TVar,TFac,E}

Construct an empty BipartiteFactorGraph with specified variable, factor and edge data types.
Optionally specify a dictionary type (defaults to Base.Dict).
"""
function BipartiteFactorGraph{TVar, TFac, E}(dict_type = Dict) where {TVar, TFac, E}
    return BipartiteFactorGraph{TVar, TFac, E, dict_type{Int, TVar}, dict_type{Int, TFac}, dict_type{UnorderedPair, E}}(
        SimpleGraph{Int}(), dict_type{Int, TVar}(), dict_type{Int, TFac}(), dict_type{UnorderedPair, E}()
    )
end

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
"""
function variable_neighbors(g::BipartiteFactorGraph, v::Int)
    if !is_factor(g, v)
        throw(ArgumentError("Node $v is not a factor node"))
    end
    return filter(n -> is_variable(g, n), neighbors(g, v))
end

"""
    factor_neighbors(g::BipartiteFactorGraph, v::Int)

Get all factor neighbors of variable node v.
Returns only neighbors that are factor nodes.
"""
function factor_neighbors(g::BipartiteFactorGraph, v::Int)
    if !is_variable(g, v)
        throw(ArgumentError("Node $v is not a variable node"))
    end
    return filter(n -> is_factor(g, n), neighbors(g, v))
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
    has_edge(g::BipartiteFactorGraph, var::Int, fac::Int)

Check if there is an edge between variable node `var` and factor node `fac`.
"""
function has_edge(g::BipartiteFactorGraph, var::Int, fac::Int)
    return Graphs.has_edge(g.graph, var, fac)
end

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

end # module
