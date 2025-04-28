using BipartiteFactorGraphs
using BenchmarkTools
using Random

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

# Helper functions for benchmarking
function create_test_graph(nvars::Int, nfacts::Int, avg_edges_per_node::Int)
    g = BipartiteFactorGraph(Float64, String, Int)

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
function setup_empty_graph()
    return BipartiteFactorGraph(Float64, String, Int)
end

function setup_graph_with_vars(nvars)
    g = BipartiteFactorGraph(Float64, String, Int)
    for i in 1:nvars
        add_variable!(g, float(i))
    end
    return g
end

function setup_graph_with_factors(nfacts)
    g = BipartiteFactorGraph(Float64, String, Int)
    for i in 1:nfacts
        add_factor!(g, "factor_$i")
    end
    return g
end

function setup_graph_with_vars_and_factors(nvars, nfacts)
    g = BipartiteFactorGraph(Float64, String, Int)
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

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    # Graph creation
    SUITE["creation"]["empty_$size_name"] = @benchmarkable BipartiteFactorGraph(Float64, String, Int)

    # Adding single variable/factor
    SUITE["creation"]["add_variable_$size_name"] = @benchmarkable add_variable!(g, 1.0) setup = (
        g = setup_empty_graph()
    )
    SUITE["creation"]["add_factor_$size_name"] = @benchmarkable add_factor!(g, "factor") setup = (
        g = setup_empty_graph()
    )

    # Building full graphs
    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections

        SUITE["creation"]["build_$(size_name)_$(density_name)"] = @benchmarkable create_test_graph(
            $nvars, $nfacts, $avg_edges
        )
    end
end

# 2. Bulk operations
SUITE["bulk"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    # Bulk variable addition
    SUITE["bulk"]["add_variables_$size_name"] = @benchmarkable begin
        for i in 1:nvars
            add_variable!(g, float(i))
        end
    end setup = (g = setup_empty_graph(); nvars = $nvars)

    # Bulk factor addition
    SUITE["bulk"]["add_factors_$size_name"] = @benchmarkable begin
        for i in 1:nfacts
            add_factor!(g, "factor_$i")
        end
    end setup = (g = setup_empty_graph(); nfacts = $nfacts)

    # Bulk edge addition for different densities
    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections
        total_edges = min(nvars * nfacts, (nvars + nfacts) * avg_edges ÷ 2)

        SUITE["bulk"]["add_edges_$(size_name)_$(density_name)"] = @benchmarkable begin
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
        end setup = (
            g = setup_graph_with_vars_and_factors($nvars, $nfacts);
            nvars = $nvars;
            nfacts = $nfacts;
            total_edges = $total_edges
        )
    end
end

# 3. Iterating over nodes
SUITE["iteration"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections

        # Iterate over all variables
        SUITE["iteration"]["variables_$(size_name)_$(density_name)"] = @benchmarkable collect(variables(g)) setup = (
            g = create_test_graph($nvars, $nfacts, $avg_edges)
        )

        # Iterate over all factors
        SUITE["iteration"]["factors_$(size_name)_$(density_name)"] = @benchmarkable collect(factors(g)) setup = (
            g = create_test_graph($nvars, $nfacts, $avg_edges)
        )

        # Iterate over all variable neighbors for a random factor
        SUITE["iteration"]["var_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
            for f in factors_sample
                variable_neighbors(g, f)
            end
        end setup =
            (g = create_test_graph($nvars, $nfacts, $avg_edges); factors_sample = get_random_nodes(g, 100, :factor))

        # Iterate over all factor neighbors for a random variable
        SUITE["iteration"]["fac_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in vars_sample
                factor_neighbors(g, v)
            end
        end setup =
            (g = create_test_graph($nvars, $nfacts, $avg_edges); vars_sample = get_random_nodes(g, 100, :variable))
    end
end

# 4. Random access patterns
SUITE["random_access"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections

        # Random access to variable data
        SUITE["random_access"]["var_data_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in vars_sample
                get_variable_data(g, v)
            end
        end setup =
            (g = create_test_graph($nvars, $nfacts, $avg_edges); vars_sample = get_random_nodes(g, 1000, :variable))

        # Random access to factor data
        SUITE["random_access"]["fac_data_$(size_name)_$(density_name)"] = @benchmarkable begin
            for f in facts_sample
                get_factor_data(g, f)
            end
        end setup =
            (g = create_test_graph($nvars, $nfacts, $avg_edges); facts_sample = get_random_nodes(g, 1000, :factor))

        # Random access to edge data
        SUITE["random_access"]["edge_data_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in vars_sample
                facs = factor_neighbors(g, v)
                if !isempty(facs)
                    f = first(facs)
                    get_edge_data(g, v, f)
                end
            end
        end setup =
            (g = create_test_graph($nvars, $nfacts, $avg_edges); vars_sample = get_random_nodes(g, 1000, :variable))
    end
end

# 5. Sequential access patterns
SUITE["sequential_access"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections

        # Sequential access to variable data
        SUITE["sequential_access"]["vars_data_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in variables(g)
                get_variable_data(g, v)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))

        # Sequential access to factor data
        SUITE["sequential_access"]["facs_data_$(size_name)_$(density_name)"] = @benchmarkable begin
            for f in factors(g)
                get_factor_data(g, f)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))

        # Sequential access to all variable neighbors
        SUITE["sequential_access"]["all_var_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
            for f in factors(g)
                variable_neighbors(g, f)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))

        # Sequential access to all factor neighbors
        SUITE["sequential_access"]["all_fac_neighbors_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in variables(g)
                factor_neighbors(g, v)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))
    end
end

# 6. Graph properties and queries
SUITE["queries"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections

        # Setup for edge check
        SUITE["queries"]["has_edge_$(size_name)_$(density_name)"] = @benchmarkable begin
            for v in vars_sample
                for f in facts_sample
                    has_edge(g, v, f)
                end
            end
        end setup = (
            g = create_test_graph($nvars, $nfacts, $avg_edges);
            vars_sample = get_random_nodes(g, 10, :variable);
            facts_sample = get_random_nodes(g, 10, :factor)
        ) evals = 1

        # Check node types - use separate setup expressions to avoid variable conflicts
        SUITE["queries"]["is_variable_$(size_name)_$(density_name)"] = @benchmarkable begin
            for node_idx in 1:($nvars + $nfacts)
                is_variable(g, node_idx)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))

        SUITE["queries"]["is_factor_$(size_name)_$(density_name)"] = @benchmarkable begin
            for node_idx in 1:($nvars + $nfacts)
                is_factor(g, node_idx)
            end
        end setup = (g = create_test_graph($nvars, $nfacts, $avg_edges))
    end
end

# 7. Edge addition with callback
SUITE["edge_callbacks"] = BenchmarkGroup()

for size in GRAPH_SIZES
    size_name = size.name
    nvars, nfacts = size.vars, size.facts

    for density in EDGE_DENSITIES
        density_name = density.name
        avg_edges = density.connections
        total_edges = min(nvars * nfacts, (nvars + nfacts) * avg_edges ÷ 2)

        SUITE["edge_callbacks"]["add_edges_with_callback_$(size_name)_$(density_name)"] = @benchmarkable begin
            edges_added = 0
            added_edges = Set{Tuple{Int, Int}}()

            while edges_added < total_edges
                var = rand(1:nvars)
                fac = rand((nvars + 1):(nvars + nfacts))

                if (var, fac) ∉ added_edges
                    push!(added_edges, (var, fac))
                    add_edge!(g, var, fac, edges_added) do node_id, node_data, edge_data
                        # Empty callback that does nothing
                    end
                    edges_added += 1
                end
            end
        end setup = (
            g = setup_graph_with_vars_and_factors($nvars, $nfacts);
            nvars = $nvars;
            nfacts = $nfacts;
            total_edges = $total_edges
        )
    end
end
