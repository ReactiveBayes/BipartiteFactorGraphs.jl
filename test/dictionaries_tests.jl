@testitem "Using external dictionary types - Dict" begin
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
