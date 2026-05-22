# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for Cliometrics.jl
# Tests the full historical econometrics workflow: data cleaning → growth accounting →
# institutional analysis → convergence → treatment effect estimation.

using Test
using Cliometrics
using DataFrames

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: post-war growth accounting study" begin
        # 1. Build a synthetic post-war dataset with missing values
        raw = DataFrame(
            year    = collect(1950:1975),
            gdp     = vcat([100.0], [missing], collect(110.0:5.0:225.0)),
            capital = vcat([300.0, missing], collect(305.0:5.0:420.0)),
            labor   = collect(50.0:0.5:62.5),
        )

        # 2. Clean the GDP series (linear interpolation)
        cleaned_gdp = clean_historical_series(Vector{Union{Float64,Missing}}(raw.gdp),
                                               method=:linear)
        @test all(isfinite.(cleaned_gdp))
        @test length(cleaned_gdp) == nrow(raw)

        # 3. Build a clean DataFrame for growth decomposition
        data = DataFrame(
            year    = raw.year,
            gdp     = cleaned_gdp,
            capital = clean_historical_series(Vector{Union{Float64,Missing}}(raw.capital),
                                              method=:forward_fill),
            labor   = raw.labor,
        )

        # 4. Solow residual
        tfp = solow_residual(data.gdp, data.capital, data.labor, alpha=0.35)
        @test length(tfp) == nrow(data) - 1
        @test all(isfinite.(tfp))

        # 5. Growth decomposition
        decomp = decompose_growth(data, alpha=0.35)
        @test nrow(decomp) == nrow(data) - 1
        @test "tfp_contribution" in names(decomp)
        for i in 1:nrow(decomp)
            total = decomp.capital_contribution[i] + decomp.labor_contribution[i] +
                    decomp.tfp_contribution[i]
            @test total ≈ decomp.output_growth[i] atol=1e-10
        end

        # 6. Calculate growth rates
        gr = calculate_growth_rates(data, :gdp, method=:geometric)
        @test length(gr) == nrow(data) - 1
        @test all(isfinite.(gr))
    end

    @testset "Full pipeline: cross-country convergence and institutions" begin
        # 1. Build convergence dataset
        conv_data = DataFrame(
            country    = ["UK", "France", "Germany", "Japan", "Korea"],
            gdp_1950   = [5000.0, 4000.0, 3000.0, 2000.0, 1000.0],
            growth_rate = [0.024, 0.028, 0.032, 0.038, 0.044],
        )

        result = convergence_analysis(conv_data, :gdp_1950, :growth_rate)
        @test result.beta < 0      # Convergence: poorer countries grow faster
        @test result.converging    # Should detect beta-convergence
        @test isfinite(result.half_life)

        # 2. Institutional quality index
        inst_data = DataFrame(
            country           = ["UK", "France", "Germany", "Japan", "Korea"],
            rule_of_law       = [0.85, 0.80, 0.82, 0.78, 0.70],
            property_rights   = [0.88, 0.82, 0.84, 0.80, 0.72],
            corruption_control = [0.80, 0.75, 0.80, 0.76, 0.68],
        )
        idx = institutional_quality_index(inst_data,
                                          [:rule_of_law, :property_rights, :corruption_control])
        @test length(idx) == 5
        @test all(0.0 .<= idx .<= 1.0)

        # 3. Trajectory comparison
        traj_data = DataFrame(
            year   = repeat(1950:1974, 2),
            region = repeat(["Europe", "Asia"], inner=25),
            gdp_per_capita = vcat(
                [5000.0 * (1.03)^i for i in 0:24],  # Europe 3% growth
                [2000.0 * (1.05)^i for i in 0:24],  # Asia  5% growth
            ),
        )
        comparison = compare_historical_trajectories(traj_data, ["Europe", "Asia"])
        asia = comparison[comparison.region .== "Asia", :]
        euro = comparison[comparison.region .== "Europe", :]
        @test asia.avg_growth[1] > euro.avg_growth[1]
    end

    @testset "Error handling: invalid inputs" begin
        data = DataFrame(year=2000:2004, gdp=[100.0, 110.0, 121.0, 133.1, 146.41])
        @test_throws ErrorException counterfactual_scenario(data, :gdp, 1999)
        @test_throws ErrorException counterfactual_scenario(data, :gdp, 2002; method=:invalid)
        @test_throws ErrorException clean_historical_series([1.0, 2.0], method=:invalid)
        @test_throws ErrorException calculate_growth_rates(data, :gdp, method=:invalid)
    end

    @testset "Round-trip consistency: counterfactual scenario" begin
        data = DataFrame(year=2000:2009,
                         gdp=[100.0*(1.04)^i for i in 0:9])
        # Multiplicative then additive: both should return 10-row DataFrames
        res_m = counterfactual_scenario(data, :gdp, 2005; adjustment=0.95, method=:multiplicative)
        res_a = counterfactual_scenario(data, :gdp, 2005; adjustment=-5.0, method=:additive)
        @test nrow(res_m) == 10
        @test nrow(res_a) == 10
        # Before break year: actual == counterfactual
        @test res_m.counterfactual[1] ≈ res_m.actual[1]
        @test res_a.counterfactual[1] ≈ res_a.actual[1]
    end

end
