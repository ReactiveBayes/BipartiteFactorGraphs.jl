using BipartiteFactorGraphs
using Test
using Aqua
using JET
using TestItemRunner

@testset "BipartiteFactorGraphs.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(BipartiteFactorGraphs)
    end

    @testset "Code linting (JET.jl)" begin
        JET.test_package(PkgName; target_defined_modules = true)
    end

    TestItemRunner.@run_package_tests()
end
