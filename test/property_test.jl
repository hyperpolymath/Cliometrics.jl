# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# Property-based tests for Cliometrics.jl
# Verifies economic measurement invariants across random historical datasets.

using Test
using Cliometrics
using DataFrames

@testset "Property-Based Tests" begin

    @testset "Invariant: Solow residual satisfies growth accounting identity" begin
        for _ in 1:50
            n = rand(5:15)
            # Generate random monotonically increasing economic series
            output  = cumsum(rand(n) .* 5 .+ 100.0)
            capital = cumsum(rand(n) .* 10 .+ 200.0)
            labor   = cumsum(rand(n) .* 1  .+ 50.0)
            alpha = rand(0.2:0.05:0.4)

            tfp = solow_residual(output, capital, labor; alpha=alpha)
            @test length(tfp) == n - 1

            # Verify identity: TFP = g_Y - alpha*g_K - (1-alpha)*g_L
            for i in 2:n
                g_Y = log(output[i]  / output[i-1])
                g_K = log(capital[i] / capital[i-1])
                g_L = log(labor[i]   / labor[i-1])
                expected_tfp = g_Y - alpha * g_K - (1 - alpha) * g_L
                @test tfp[i-1] ≈ expected_tfp atol=1e-10
            end
        end
    end

    @testset "Invariant: growth decomposition components sum to total" begin
        for _ in 1:50
            n = rand(4:10)
            base = 100.0
            data = DataFrame(
                year    = collect(2000:(2000+n-1)),
                gdp     = [base * (1 + 0.03)^i for i in 0:(n-1)],
                capital = [300.0 * (1 + 0.02)^i for i in 0:(n-1)],
                labor   = [50.0 * (1 + 0.01)^i for i in 0:(n-1)],
            )
            alpha = rand(0.25:0.05:0.45)
            decomp = decompose_growth(data; alpha=alpha)

            for i in 1:nrow(decomp)
                total = decomp.capital_contribution[i] + decomp.labor_contribution[i] +
                        decomp.tfp_contribution[i]
                @test total ≈ decomp.output_growth[i] atol=1e-10
            end
        end
    end

    @testset "Invariant: institutional quality index in [0, 1]" begin
        for _ in 1:50
            n = rand(3:8)
            k = rand(2:4)
            cols = [Symbol("ind$j") for j in 1:k]
            d = DataFrame(country=["C$i" for i in 1:n])
            for c in cols
                d[!, c] = rand(n)
            end
            idx = institutional_quality_index(d, cols)
            @test length(idx) == n
            @test all(0.0 .<= idx .<= 1.0)
        end
    end

    @testset "Invariant: cleaned series has no missing/NaN after interpolation" begin
        for _ in 1:50
            n = rand(5:20)
            data = Vector{Union{Float64, Missing}}(rand(n))
            # Introduce random missings (but keep first and last non-missing)
            n_missing = rand(0:div(n,3))
            for _ in 1:n_missing
                idx = rand(2:(n-1))
                data[idx] = missing
            end
            cleaned = clean_historical_series(data, method=:linear)
            @test length(cleaned) == n
            @test all(isfinite.(cleaned))
        end
    end

    @testset "Invariant: geometric growth rates have consistent sign" begin
        for _ in 1:50
            n = rand(4:10)
            # Strictly increasing series → all positive growth rates
            base = 100.0
            gdp  = [base * (1.03)^i for i in 0:(n-1)]
            data = DataFrame(year=collect(2000:(2000+n-1)), gdp=gdp)
            gr = calculate_growth_rates(data, :gdp; method=:geometric)
            @test all(gr .> 0.0)
        end
    end

end
