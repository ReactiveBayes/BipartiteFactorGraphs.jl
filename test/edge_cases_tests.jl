@testitem "Error handling for non-existent nodes" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    # Test accessing non-existent variable
    @test_throws KeyError get_variable_data(g, 1)

    # Test accessing non-existent factor
    @test_throws KeyError get_factor_data(g, 1)

    # Add one variable and one factor
    v1 = add_variable!(g, 1.0)
    f1 = add_factor!(g, "factor1")

    # Test accessing valid nodes
    @test get_variable_data(g, v1) == 1.0
    @test get_factor_data(g, f1) == "factor1"

    # Test accessing node with wrong type
    @test_throws ArgumentError factor_neighbors(g, f1)
    @test_throws ArgumentError variable_neighbors(g, v1)
end

@testitem "Edge data error handling" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")

    add_edge!(g, v1, f1, true)

    # Test accessing non-existent edge
    @test_throws KeyError get_edge_data(g, v2, f1)

    # Test adding duplicate edge (should return false)
    @test !add_edge!(g, v1, f1, false)

    # Original edge data should remain unchanged
    @test get_edge_data(g, v1, f1) === true
end

@testitem "Empty graph operations" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    # Test collections on empty graph
    @test isempty(variables(g))
    @test isempty(factors(g))

    # Test counts on empty graph
    @test num_variables(g) == 0
    @test num_factors(g) == 0
end

@testitem "Self-loops and variable-variable/factor-factor edges" begin
    using BipartiteFactorGraphs
    using Graphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    # While the BipartiteFactorGraph is supposed to maintain bipartite structure,
    # the underlying implementation allows any edge. Let's test what happens:

    # Variable to variable edge
    @test Graphs.add_edge!(g.graph, v1, v2)
    @test BipartiteFactorGraphs.has_edge(g, v1, v2)

    # Factor to factor edge
    @test Graphs.add_edge!(g.graph, f1, f2)
    @test BipartiteFactorGraphs.has_edge(g, f1, f2)

    # Self-loop on variable
    @test Graphs.add_edge!(g.graph, v1, v1)
    @test BipartiteFactorGraphs.has_edge(g, v1, v1)

    # These should not crash but note they don't maintain proper bipartite structure
    # The explicit add_edge! function in BipartiteFactorGraphs should be used to maintain bipartite structure
end

@testitem "Performance with larger graphs" begin
    using BipartiteFactorGraphs

    # Create a larger graph
    g = BipartiteFactorGraph(Float64, String, Bool)

    # Add many variables and factors
    num_nodes = 1000
    variables_array = [add_variable!(g, Float64(i)) for i in 1:num_nodes]
    factors_array = [add_factor!(g, "factor$i") for i in 1:num_nodes]

    # Add some edges
    for i in 1:num_nodes
        # Connect each variable to a few factors
        for j in max(1, i - 2):min(num_nodes, i + 2)
            add_edge!(g, variables_array[i], factors_array[j], i < j)
        end
    end

    # Basic sanity checks
    @test num_variables(g) == num_nodes
    @test num_factors(g) == num_nodes

    # Performance is not directly testable in a unit test,
    # but we can verify the operations complete successfully
    @test length(collect(variables(g))) == num_nodes
    @test length(collect(factors(g))) == num_nodes

    # Check a few random connections
    for i in 1:10:num_nodes
        @test !isempty(factor_neighbors(g, variables_array[i]))
    end
end

@testitem "Unusual data types" begin
    using BipartiteFactorGraphs

    # Test with more complex data types

    # Variables store arrays
    # Factors store dictionaries
    # Edges store custom types
    struct CustomEdgeData
        value::Any
        metadata::Dict{Symbol, Any}
    end

    g = BipartiteFactorGraph(Vector{Float64}, Dict{String, Any}, CustomEdgeData)

    # Add variable with array data
    v1 = add_variable!(g, [1.0, 2.0, 3.0])
    v2 = add_variable!(g, Float64[])  # Empty array

    # Add factor with dictionary data
    f1 = add_factor!(g, Dict("name" => "factor1", "value" => 42))
    f2 = add_factor!(g, Dict{String, Any}())  # Empty dict

    # Add edge with custom data
    edge_data = CustomEdgeData("connection", Dict(:weight => 0.5, :active => true))
    add_edge!(g, v1, f1, edge_data)

    # Test retrieval
    @test get_variable_data(g, v1) == [1.0, 2.0, 3.0]
    @test get_variable_data(g, v2) == Float64[]

    @test get_factor_data(g, f1)["name"] == "factor1"
    @test get_factor_data(g, f1)["value"] == 42
    @test isempty(get_factor_data(g, f2))

    retrieved_edge_data = get_edge_data(g, v1, f1)
    @test retrieved_edge_data.value == "connection"
    @test retrieved_edge_data.metadata[:weight] == 0.5
    @test retrieved_edge_data.metadata[:active] == true
end
