@testitem "Using external dictionary types - wrong type" begin
    using BipartiteFactorGraphs, Dictionaries

    # Test with Base.Dict (default)
    @test_throws ArgumentError BipartiteFactorGraph(Float64, String, Bool, Int)
end

@testitem "Using external dictionary types - Dict from Base.jl" begin
    using BipartiteFactorGraphs

    # Test with Base.Dict (default)
    g = BipartiteFactorGraph(Float64, String, Bool, Dict)

    v1 = add_variable!(g, 1.0)
    f1 = add_factor!(g, "factor1")
    add_edge!(g, v1, f1, true)

    @test get_variable_data(g, v1) == 1.0
    @test get_factor_data(g, f1) == "factor1"
    @test get_edge_data(g, v1, f1) === true
end

@testitem "Using external dictionary types - Dictionary from Dictionaries.jl" begin
    using Dictionaries
    using BipartiteFactorGraphs

    # Test with Base.Dict (default)
    g = BipartiteFactorGraph(Float64, String, Bool, Dictionary)

    v1 = add_variable!(g, 1.0)
    f1 = add_factor!(g, "factor1")
    add_edge!(g, v1, f1, true)

    @test get_variable_data(g, v1) == 1.0
    @test get_factor_data(g, f1) == "factor1"
    @test get_edge_data(g, v1, f1) === true
end

@testitem "Adding variables and factors with Dictionary from Dictionaries.jl" begin
    using Dictionaries
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool, Dictionary)

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

@testitem "Adding edges with Dictionary from Dictionaries.jl" begin
    using Dictionaries
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool, Dictionary)

    # Add nodes
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    # Add edges
    e1 = add_edge!(g, v1, f1, true)
    e2 = add_edge!(g, v2, f1, false)
    e3 = add_edge!(g, v2, f2, true)

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
    e3 = add_edge!(g, f3, v3, false)  # Note order: factor, variable
    @test has_edge(g, v3, f3)
    @test has_edge(g, f3, v3)
    @test get_edge_data(g, e3) === false
    @test get_edge_data(g, v3, f3) === false

    # Test duplicate edge addition
    @test e1 == add_edge!(g, v1, f1, false) 
end

@testitem "Neighbors with Dictionary from Dictionaries.jl" begin
    using Dictionaries
    using BipartiteFactorGraphs

    g = BipartiteFactorGraph(Float64, String, Bool, Dictionary)

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

    @test neighbors(g, f1) == variable_neighbors(g, f1)
    @test neighbors(g, f2) == variable_neighbors(g, f2)

    @test Set(factor_neighbors(g, v1)) == Set([f1])
    @test Set(factor_neighbors(g, v2)) == Set([f1, f2])
    @test Set(factor_neighbors(g, v3)) == Set([f2])

    @test neighbors(g, v1) == factor_neighbors(g, v1)
    @test neighbors(g, v2) == factor_neighbors(g, v2)
    @test neighbors(g, v3) == factor_neighbors(g, v3)

    # Test isolated nodes
    v4 = add_variable!(g, 4.0)
    f3 = add_factor!(g, "factor3")
    @test isempty(neighbors(g, v4))
    @test isempty(neighbors(g, f3))
    @test isempty(factor_neighbors(g, v4))
    @test isempty(variable_neighbors(g, f3))
end
