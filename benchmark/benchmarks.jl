using BipartiteFactorGraphs
using BenchmarkTools
using Random
using Dictionaries

# Set up the benchmark suite
SUITE = BenchmarkGroup()

# Define different graph configurations for benchmarking
const GRAPH_SIZES = [
    (name = :small, vars = 100, facts = 50),
    (name = :medium, vars = 1000, facts = 500),
    (name = :large, vars = 10000, facts = 5000)
]

const EDGE_DENSITIES = [
    (name = :sparse, connections = 2),   # average connections per node
    (name = :medium, connections = 5),   # average connections per node  
    (name = :dense, connections = 10)    # average connections per node
]

const DICT_TYPES = [
    (name = :Dict, dict_type = Dict),
    (name = :Dictictionary, dict_type = Dictionaries.Dictionary),
    (name = :UnorderedDictictionary, dict_type = Dictionaries.UnorderedDictionary)
]

# Helper functions for benchmarking
function create_test_graph(nvars::Int, nfacts::Int, avg_edges_per_node::Int, dict_type)
    g = BipartiteFactorGraph(Float64, String, Int, dict_type)

    # Add variables and factors
    for i in 1:nvars
        add_variable!(g, float(i))
    end

    for i in 1:nfacts
        add_factor!(g, "factor_$i")
    end

    # Add edges with controlled density
    total_edges = min(nvars * nfacts, (nvars + nfacts) * avg_edges_per_node ÷ 2)
    edges_added = 0

    # Use set to avoid adding duplicate edges
    added_edges = Set{Tuple{Int, Int}}()

    while edges_added < total_edges
        var = rand(1:nvars)
        fac = rand((nvars + 1):(nvars + nfacts))

        if (var, fac) ∉ added_edges
            push!(added_edges, (var, fac))
            add_edge!(g, var, fac, edges_added)
            edges_added += 1
        end
    end

    return g
end

function get_random_nodes(g, n, node_type = :variable)
    if node_type == :variable
        return rand(collect(variables(g)), min(n, num_variables(g)))
    else
        return rand(collect(factors(g)), min(n, num_factors(g)))
    end
end

# Setup functions to avoid scope issues
function setup_empty_graph(dict_type)
    return BipartiteFactorGraph(Float64, String, Int, dict_type)
end

function setup_graph_with_vars(nvars, dict_type)
    g = BipartiteFactorGraph(Float64, String, Int, dict_type)
    for i in 1:nvars
        add_variable!(g, float(i))
    end
    return g
end

function setup_graph_with_factors(nfacts, dict_type)
    g = BipartiteFactorGraph(Float64, String, Int, dict_type)
    for i in 1:nfacts
        add_factor!(g, "factor_$i")
    end
    return g
end

function setup_graph_with_vars_and_factors(nvars, nfacts, dict_type)
    g = BipartiteFactorGraph(Float64, String, Int, dict_type)
    for i in 1:nvars
        add_variable!(g, float(i))
    end
    for i in 1:nfacts
        add_factor!(g, "factor_$i")
    end
    return g
end

# 1. Graph creation and basic operations
SUITE["creation"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        # Graph creation
        SUITE["creation"][dict_type_name]["empty_$size_name"] = @benchmarkable BipartiteFactorGraph(
            Float64, String, Int, $dict_type_type
        )

        # Adding single variable/factor
        SUITE["creation"][dict_type_name]["add_variable_$size_name"] = @benchmarkable add_variable!(g, 1.0) setup = (
            g = setup_empty_graph($dict_type_type)
        )
        SUITE["creation"][dict_type_name]["add_factor_$size_name"] = @benchmarkable add_factor!(g, "factor") setup = (
            g = setup_empty_graph($dict_type_type)
        )

        # Building full graphs
        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections

            SUITE["creation"][dict_type_name]["build_$(size_name)_$(density_name)"] = @benchmarkable create_test_graph(
                $nvars, $nfacts, $avg_edges, $dict_type_type
            )
        end
    end
end

# 2. Bulk operations
SUITE["bulk"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        # Bulk variable addition
        SUITE["bulk"][dict_type_name]["add_variables_$size_name"] = @benchmarkable begin
            for i in 1:nvars
                add_variable!(g, float(i))
            end
        end setup = (g = setup_empty_graph($dict_type_type); nvars = $nvars)

        # Bulk factor addition
        SUITE["bulk"][dict_type_name]["add_factors_$size_name"] = @benchmarkable begin
            for i in 1:nfacts
                add_factor!(g, "factor_$i")
            end
        end setup = (g = setup_empty_graph($dict_type_type); nfacts = $nfacts)

        # Bulk edge addition for different densities
        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections
            total_edges = min(nvars * nfacts, (nvars + nfacts) * avg_edges ÷ 2)

            SUITE["bulk"][dict_type_name]["add_edges_$(size_name)_$(density_name)"] = @benchmarkable begin
                edges_added = 0
                added_edges = Set{Tuple{Int, Int}}()

                while edges_added < total_edges
                    var = rand(1:nvars)
                    fac = rand((nvars + 1):(nvars + nfacts))

                    if (var, fac) ∉ added_edges
                        push!(added_edges, (var, fac))
                        add_edge!(g, var, fac, edges_added)
                        edges_added += 1
                    end
                end
            end setup = (g = setup_graph_with_vars_and_factors($nvars, $nfacts, $dict_type_type);
            nvars = $nvars;
            nfacts = $nfacts;
            total_edges = $total_edges)
        end
    end
end

# 3. Iterating over nodes
SUITE["iteration"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections

            # Iterate over all variables
            SUITE["iteration"][dict_type_name]["variables_$(size_name)_$(density_name)"] = @benchmarkable collect(
                variables(g)
            ) setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            # Iterate over all factors
            SUITE["iteration"][dict_type_name]["factors_$(size_name)_$(density_name)"] = @benchmarkable collect(
                factors(g)
            ) setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            # Iterate over all variable neighbors for a random factor
            SUITE["iteration"][dict_type_name]["var_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
                for f in factors_sample
                    variable_neighbors(g, f)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            factors_sample = get_random_nodes(g, 100, :factor))

            # Iterate over all factor neighbors for a random variable
            SUITE["iteration"][dict_type_name]["fac_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in vars_sample
                    factor_neighbors(g, v)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            vars_sample = get_random_nodes(g, 100, :variable))
        end
    end
end

# 4. Random access patterns
SUITE["random_access"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections

            # Random access to variable data
            SUITE["random_access"][dict_type_name]["var_data_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in vars_sample
                    get_variable_data(g, v)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            vars_sample = get_random_nodes(g, 1000, :variable))

            # Random access to factor data
            SUITE["random_access"][dict_type_name]["fac_data_$(size_name)_$(density_name)"] = @benchmarkable begin
                for f in facts_sample
                    get_factor_data(g, f)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            facts_sample = get_random_nodes(g, 1000, :factor))

            # Random access to edge data
            SUITE["random_access"][dict_type_name]["edge_data_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in vars_sample
                    facs = factor_neighbors(g, v)
                    if !isempty(facs)
                        f = first(facs)
                        get_edge_data(g, v, f)
                    end
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            vars_sample = get_random_nodes(g, 1000, :variable))
        end
    end
end

# 5. Sequential access patterns
SUITE["sequential_access"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections

            # Sequential access to variable data
            SUITE["sequential_access"][dict_type_name]["vars_data_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in variables(g)
                    get_variable_data(g, v)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            # Sequential access to factor data
            SUITE["sequential_access"][dict_type_name]["facs_data_$(size_name)_$(density_name)"] = @benchmarkable begin
                for f in factors(g)
                    get_factor_data(g, f)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            # Sequential access to all variable neighbors
            SUITE["sequential_access"][dict_type_name]["all_var_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
                for f in factors(g)
                    variable_neighbors(g, f)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            # Sequential access to all factor neighbors
            SUITE["sequential_access"][dict_type_name]["all_fac_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in variables(g)
                    factor_neighbors(g, v)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))
        end
    end
end

# 6. Graph properties and queries
SUITE["queries"] = BenchmarkGroup()

for dict_type in DICT_TYPES
    dict_type_name = dict_type.name
    dict_type_type = dict_type.dict_type

    for size in GRAPH_SIZES
        size_name = size.name
        nvars, nfacts = size.vars, size.facts

        for density in EDGE_DENSITIES
            density_name = density.name
            avg_edges = density.connections

            # Setup for edge check
            SUITE["queries"][dict_type_name]["has_edge_$(size_name)_$(density_name)"] = @benchmarkable begin
                for v in vars_sample
                    for f in facts_sample
                        has_edge(g, v, f)
                    end
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type);
            vars_sample = get_random_nodes(g, 10, :variable);
            facts_sample = get_random_nodes(g, 10, :factor)) evals = 1

            # Check node types - use separate setup expressions to avoid variable conflicts
            SUITE["queries"][dict_type_name]["is_variable_$(size_name)_$(density_name)"] = @benchmarkable begin
                for node_idx in 1:($nvars + $nfacts)
                    is_variable(g, node_idx)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))

            SUITE["queries"][dict_type_name]["is_factor_$(size_name)_$(density_name)"] = @benchmarkable begin
                for node_idx in 1:($nvars + $nfacts)
                    is_factor(g, node_idx)
                end
            end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges, $dict_type_type))
        end
    end
end
