@testitem "BipartiteFactorGraph construction" begin
    using BipartiteFactorGraphs

    # Test basic construction
    g = BipartiteFactorGraph{Float64, String, Bool}()
    @test num_variables(g) == 0
    @test num_factors(g) == 0

    # Test construction with specified dictionary type
    g2 = BipartiteFactorGraph{Int, String, Float64}(Dict)
    @test num_variables(g2) == 0
    @test num_factors(g2) == 0
end

@testitem "Adding variables and factors" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Add variables
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    @test num_variables(g) == 2
    @test is_variable(g, v1)
    @test is_variable(g, v2)
    @test !is_factor(g, v1)

    # Add factors
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")
    @test num_factors(g) == 2
    @test is_factor(g, f1)
    @test is_factor(g, f2)
    @test !is_variable(g, f1)

    # Test data retrieval
    @test get_variable_data(g, v1) == 1.0
    @test get_variable_data(g, v2) == 2.0
    @test get_factor_data(g, f1) == "factor1"
    @test get_factor_data(g, f2) == "factor2"

    # Test sequential IDs
    v3 = add_variable!(g, 3.0)
    f3 = add_factor!(g, "factor3")
    @test v3 > v2
    @test f3 > f2

    # Test variables and factors collections
    @test Set(variables(g)) == Set([v1, v2, v3])
    @test Set(factors(g)) == Set([f1, f2, f3])
end

@testitem "Adding edges" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Add nodes
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    # Add edges
    @test add_edge!(g, v1, f1, true)
    @test add_edge!(g, v2, f1, false)
    @test add_edge!(g, v2, f2, true)

    # Test edge existence
    @test has_edge(g, v1, f1)
    @test has_edge(g, v2, f1)
    @test has_edge(g, v2, f2)
    @test !has_edge(g, v1, f2)

    # Test edge data retrieval
    @test get_edge_data(g, v1, f1) === true
    @test get_edge_data(g, v2, f1) === false
    @test get_edge_data(g, v2, f2) === true

    # Test adding edge in reversed order
    v3 = add_variable!(g, 3.0)
    f3 = add_factor!(g, "factor3")
    @test add_edge!(g, f3, v3, false)  # Note order: factor, variable
    @test has_edge(g, v3, f3)
    @test has_edge(g, f3, v3)
    @test get_edge_data(g, v3, f3) === false

    # Test duplicate edge addition
    @test !add_edge!(g, v1, f1, false)  # Should return false for existing edge
end

@testitem "Neighbors" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Create a simple factor graph
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    v3 = add_variable!(g, 3.0)

    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    add_edge!(g, v1, f1, true)
    add_edge!(g, v2, f1, true)
    add_edge!(g, v2, f2, true)
    add_edge!(g, v3, f2, true)

    # Test neighbors
    @test Set(neighbors(g, v1)) == Set([f1])
    @test Set(neighbors(g, v2)) == Set([f1, f2])
    @test Set(neighbors(g, v3)) == Set([f2])

    @test Set(neighbors(g, f1)) == Set([v1, v2])
    @test Set(neighbors(g, f2)) == Set([v2, v3])

    # Test variable_neighbors and factor_neighbors
    @test Set(variable_neighbors(g, f1)) == Set([v1, v2])
    @test Set(variable_neighbors(g, f2)) == Set([v2, v3])

    @test Set(factor_neighbors(g, v1)) == Set([f1])
    @test Set(factor_neighbors(g, v2)) == Set([f1, f2])
    @test Set(factor_neighbors(g, v3)) == Set([f2])

    # Test isolated nodes
    v4 = add_variable!(g, 4.0)
    f3 = add_factor!(g, "factor3")
    @test isempty(neighbors(g, v4))
    @test isempty(neighbors(g, f3))
    @test isempty(factor_neighbors(g, v4))
    @test isempty(variable_neighbors(g, f3))
end

@testitem "Collections" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Add nodes
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    # Test collections
    @test Set(variables(g)) == Set([v1, v2])
    @test Set(factors(g)) == Set([f1, f2])

    # Test collections with empty graph
    g_empty = BipartiteFactorGraph{Float64, String, Bool}()
    @test isempty(variables(g_empty))
    @test isempty(factors(g_empty))

    # Test collections after adding more nodes
    v3 = add_variable!(g, 3.0)
    f3 = add_factor!(g, "factor3")
    @test Set(variables(g)) == Set([v1, v2, v3])
    @test Set(factors(g)) == Set([f1, f2, f3])
end

@testitem "Type stability" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Add nodes
    v = add_variable!(g, 1.0)
    f = add_factor!(g, "factor")
    add_edge!(g, v, f, true)

    # Test type stability
    @inferred get_variable_data(g, v)
    @inferred get_factor_data(g, f)
    @inferred get_edge_data(g, v, f)
    @inferred neighbors(g, v)
    @inferred is_variable(g, v)
    @inferred is_factor(g, f)
    @inferred variable_neighbors(g, f)
    @inferred factor_neighbors(g, v)

    # Additional type stability tests
    @inferred variables(g)
    @inferred factors(g)
    @inferred num_variables(g)
    @inferred num_factors(g)
    @inferred has_edge(g, v, f)
end

@testitem "Undirected edge access" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Add nodes
    v1 = add_variable!(g, 1.0)
    f1 = add_factor!(g, "factor1")

    # Add edge
    add_edge!(g, v1, f1, true)

    # Test edge existence in both directions
    @test has_edge(g, v1, f1)
    @test has_edge(g, f1, v1)

    # Test that we can get edge data regardless of order
    @test get_edge_data(g, v1, f1) === true
    @test get_edge_data(g, f1, v1) === true

    # Test edge data consistency
    v2 = add_variable!(g, 2.0)
    f2 = add_factor!(g, "factor2")

    # Add edges with different data
    add_edge!(g, v2, f1, false)  # Store false for (v2, f1)
    add_edge!(g, v2, f2, true)   # Store true for (v2, f2)

    # Verify data integrity from both directions
    @test get_edge_data(g, v2, f1) === false
    @test get_edge_data(g, f1, v2) === false
    @test get_edge_data(g, v2, f2) === true
    @test get_edge_data(g, f2, v2) === true

    # Test non-existent edge
    @test_throws KeyError get_edge_data(g, v1, f2)
    @test_throws KeyError get_edge_data(g, f2, v1)

    # Test adding edge in reversed order
    v3 = add_variable!(g, 3.0)
    f3 = add_factor!(g, "factor3")
    add_edge!(g, f3, v3, false)  # Note order: factor, variable
    @test get_edge_data(g, v3, f3) === false
    @test get_edge_data(g, f3, v3) === false
end

@testitem "Complex graph structures" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Create star-like structure: one factor connected to multiple variables
    f_center = add_factor!(g, "center")
    variables = [add_variable!(g, Float64(i)) for i in 1:5]

    for v in variables
        add_edge!(g, v, f_center, true)
    end

    # Test connectivity
    @test length(variable_neighbors(g, f_center)) == 5
    for v in variables
        @test length(factor_neighbors(g, v)) == 1
        @test first(factor_neighbors(g, v)) == f_center
    end

    # Add another structure: one variable connected to multiple factors
    v_center = add_variable!(g, 99.0)
    factors = [add_factor!(g, "factor$i") for i in 1:5]

    for f in factors
        add_edge!(g, v_center, f, false)
    end

    # Test connectivity
    @test length(factor_neighbors(g, v_center)) == 5
    for f in factors
        @test length(variable_neighbors(g, f)) == 1
        @test first(variable_neighbors(g, f)) == v_center
    end
end

@testitem "Disconnected components" begin
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph{Float64, String, Bool}()

    # Create first component
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")

    add_edge!(g, v1, f1, true)
    add_edge!(g, v2, f1, false)

    # Create second disconnected component
    v3 = add_variable!(g, 3.0)
    v4 = add_variable!(g, 4.0)
    f2 = add_factor!(g, "factor2")

    add_edge!(g, v3, f2, true)
    add_edge!(g, v4, f2, false)

    # Test that components are indeed disconnected
    @test Set(variable_neighbors(g, f1)) == Set([v1, v2])
    @test Set(variable_neighbors(g, f2)) == Set([v3, v4])

    @test Set(factor_neighbors(g, v1)) == Set([f1])
    @test Set(factor_neighbors(g, v2)) == Set([f1])
    @test Set(factor_neighbors(g, v3)) == Set([f2])
    @test Set(factor_neighbors(g, v4)) == Set([f2])

    # No connection between components
    @test !has_edge(g, v1, f2)
    @test !has_edge(g, v2, f2)
    @test !has_edge(g, v3, f1)
    @test !has_edge(g, v4, f1)
end