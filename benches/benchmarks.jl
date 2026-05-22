# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for Cliometrics.jl
# Measures growth accounting, institutional analysis, and interpolation performance.

using BenchmarkTools
using Cliometrics
using DataFrames

# ── Helper: generate synthetic economic data of given length ──────────────────

function make_econ_data(n::Int)
    DataFrame(
        year    = collect(1900:(1900+n-1)),
        gdp     = [100.0 * (1.03)^i for i in 0:(n-1)],
        capital = [300.0 * (1.02)^i for i in 0:(n-1)],
        labor   = [50.0  * (1.01)^i for i in 0:(n-1)],
    )
end

data_small  = make_econ_data(20)   # 20 years
data_medium = make_econ_data(100)  # 100 years
data_large  = make_econ_data(500)  # 500 years

# ── Growth decomposition benchmarks ──────────────────────────────────────────

println("=== decompose_growth (small: 20 years) ===")
@benchmark decompose_growth($data_small; alpha=0.3)

println("=== decompose_growth (medium: 100 years) ===")
@benchmark decompose_growth($data_medium; alpha=0.3)

println("=== decompose_growth (large: 500 years) ===")
@benchmark decompose_growth($data_large; alpha=0.3)

# ── Solow residual benchmarks ─────────────────────────────────────────────────

output_large  = data_large.gdp
capital_large = data_large.capital
labor_large   = data_large.labor

println("=== solow_residual (small: 20 obs) ===")
@benchmark solow_residual($data_small.gdp, $data_small.capital, $data_small.labor; alpha=0.3)

println("=== solow_residual (medium: 100 obs) ===")
@benchmark solow_residual($data_medium.gdp, $data_medium.capital, $data_medium.labor; alpha=0.3)

println("=== solow_residual (large: 500 obs) ===")
@benchmark solow_residual($output_large, $capital_large, $labor_large; alpha=0.3)

# ── Historical data interpolation benchmark ───────────────────────────────────

# Insert 20% missing values
function make_sparse_data(n::Int)
    data = Vector{Union{Float64,Missing}}([100.0 * (1.03)^i for i in 0:(n-1)])
    for i in rand(2:(n-1), div(n, 5))
        data[i] = missing
    end
    data
end

sparse_small  = make_sparse_data(50)
sparse_medium = make_sparse_data(300)
sparse_large  = make_sparse_data(1000)

println("=== clean_historical_series :linear (small: 50 obs) ===")
@benchmark clean_historical_series($sparse_small; method=:linear)

println("=== clean_historical_series :linear (medium: 300 obs) ===")
@benchmark clean_historical_series($sparse_medium; method=:linear)

println("=== clean_historical_series :forward_fill (large: 1000 obs) ===")
@benchmark clean_historical_series($sparse_large; method=:forward_fill)
