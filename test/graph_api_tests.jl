@testitem "Basic Graphs.jl API compatibility" begin
    using BipartiteFactorGraphs
    using Graphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    # Test empty graph properties
    @test Graphs.nv(g) == 0
    @test Graphs.ne(g) == 0
    @test Graphs.density(g) == 0.0

    # Add some nodes and edges
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    v3 = add_variable!(g, 3.0)

    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    @test length(edges(g)) == 0

    add_edge!(g, v1, f1, true)
    add_edge!(g, v2, f1, true)
    add_edge!(g, v2, f2, false)
    add_edge!(g, v3, f2, true)

    @test length(edges(g)) == 4

    # Test graph properties
    @test Graphs.nv(g) == 5  # 3 variables + 2 factors
    @test Graphs.ne(g) == 4  # 4 edges

    # Test degree functions
    @test Graphs.degree(g, v1) == 1
    @test Graphs.degree(g, v2) == 2
    @test Graphs.degree(g, f1) == 2
    @test Graphs.degree(g, f2) == 2

    # Since our graph is undirected, indegree and outdegree should be the same as degree
    @test Graphs.indegree(g, v1) == Graphs.degree(g, v1)
    @test Graphs.outdegree(g, v1) == Graphs.degree(g, v1)

    # Test all_neighbors (should be same as neighbors for undirected graphs)
    @test Set(Graphs.all_neighbors(g, v1)) == Set(Graphs.neighbors(g, v1))
    @test Set(Graphs.all_neighbors(g, f1)) == Set(Graphs.neighbors(g, f1))

    # Test density
    # We have 3 variables, 2 factors, 4 edges
    # Maximum possible edges = 3 * 2 = 6
    # Density = 4/6 = 2/3
    @test Graphs.density(g) == 4 / 6

    # Test with larger graph
    h = BipartiteFactorGraph(Int, String, Bool)

    # Add 10 variables and 5 factors
    for i in 1:10
        add_variable!(h, i)
    end

    for i in 1:5
        add_factor!(h, "factor$i")
    end

    @test length(edges(h)) == 0

    # Add 20 edges
    for i in 1:10
        # Connect each variable to 2 random factors
        f_idx1 = rand(1:5)
        f_idx2 = (f_idx1 % 5) + 1  # Ensure different from f_idx1

        add_edge!(h, i, 10 + f_idx1, true)
        add_edge!(h, i, 10 + f_idx2, false)
    end

    @test length(edges(h)) == 20

    # Test properties
    @test Graphs.nv(h) == 15  # 10 variables + 5 factors
    @test Graphs.ne(h) == 20  # 20 edges
    @test Graphs.density(h) == 20 / (10 * 5)  # 20 edges out of 50 possible

    # Degree vectors should have correct length
    @test length(Graphs.degree(h)) == Graphs.nv(h)
    @test length(Graphs.indegree(h)) == Graphs.nv(h)
    @test length(Graphs.outdegree(h)) == Graphs.nv(h)
end

@testitem "Special cases for graph properties" begin
    using BipartiteFactorGraphs
    using Graphs

    # Test with only variables, no factors
    g1 = BipartiteFactorGraph(Float64, String, Bool)
    for i in 1:5
        add_variable!(g1, Float64(i))
    end

    @test Graphs.nv(g1) == 5
    @test Graphs.ne(g1) == 0
    @test Graphs.density(g1) == 0.0  # No factors means no possible edges

    # Test with only factors, no variables
    g2 = BipartiteFactorGraph(Float64, String, Bool)
    for i in 1:5
        add_factor!(g2, "factor$i")
    end

    @test Graphs.nv(g2) == 5
    @test Graphs.ne(g2) == 0
    @test Graphs.density(g2) == 0.0  # No variables means no possible edges

    # Test fully connected bipartite graph
    g3 = BipartiteFactorGraph(Float64, String, Bool)
    for i in 1:3
        add_variable!(g3, Float64(i))
    end

    for i in 1:2
        add_factor!(g3, "factor$i")
    end

    # Connect every variable to every factor
    for v in 1:3
        for f in 4:5
            add_edge!(g3, v, f, true)
        end
    end

    @test Graphs.nv(g3) == 5
    @test Graphs.ne(g3) == 6  # 3 variables * 2 factors
    @test Graphs.density(g3) == 1.0  # All possible edges exist
    @test length(edges(g3)) == 6

    # Check degrees in fully connected graph
    for v in 1:3
        @test Graphs.degree(g3, v) == 2  # Each variable connected to 2 factors
    end

    for f in 4:5
        @test Graphs.degree(g3, f) == 3  # Each factor connected to 3 variables
    end
end

# Test both the Graphs namespace and direct API versions for compatibility
@testitem "Dual function interface compatibility" begin
    using BipartiteFactorGraphs
    using Graphs

    g = BipartiteFactorGraph(Float64, String, Bool)

    # Add nodes
    v1 = add_variable!(g, 1.0)
    v2 = add_variable!(g, 2.0)
    f1 = add_factor!(g, "factor1")
    f2 = add_factor!(g, "factor2")

    # Add edges using both APIs
    add_edge!(g, v1, f1, true)          # Our API
    Graphs.add_edge!(g, v2, f2, false)  # Graphs.jl API

    # Test edge existence using both APIs
    @test has_edge(g, v1, f1)           # Our API
    @test Graphs.has_edge(g, v1, f1)    # Graphs.jl API
    @test has_edge(g, v2, f2)           # Our API
    @test Graphs.has_edge(g, v2, f2)    # Graphs.jl API

    # Test neighbors using both APIs
    @test Set(neighbors(g, v1)) == Set([f1])             # Our API
    @test Set(Graphs.neighbors(g, v1)) == Set([f1])      # Graphs.jl API

    # Show that both APIs return the same result
    @test neighbors(g, v1) == Graphs.neighbors(g, v1)
    @test has_edge(g, v1, f1) == Graphs.has_edge(g, v1, f1)
end
