# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# Vendored MINIMAL STUB of AcceleratorGate.jl
# ===========================================
# AcceleratorGate.jl is the hyperpolymath estate's intended shared
# coprocessor-dispatch package, but it is not yet published/registered. This
# vendored stub provides exactly the API surface that Cliometrics' coprocessor
# layer (src/backends/abstract.jl, src/coprocessors/*.jl) references, so the
# package instantiates, precompiles and tests with no registry dependency.
#
# It is intentionally minimal: the backend type hierarchy, a permissive
# DeviceCapabilities record, and the four extension points
# (device_capabilities, estimate_cost, register_operation!,
# generate_self_healing_hooks). Replace this stub with the real AcceleratorGate
# once it is published. See hyperpolymath/Cliometrics.jl#17.

module AcceleratorGate

export AbstractBackend, JuliaBackend, CoprocessorBackend, GPUBackend,
       TPUBackend, NPUBackend, FPGABackend, VPUBackend, QPUBackend,
       DSPBackend, PPUBackend, MathBackend, CryptoBackend,
       CUDABackend, ROCmBackend, MetalBackend,
       DeviceCapabilities, device_capabilities, estimate_cost,
       register_operation!, generate_self_healing_hooks, _record_diagnostic!

"Root of the backend type hierarchy."
abstract type AbstractBackend end

"Pure-Julia fallback backend."
struct JuliaBackend <: AbstractBackend end

"Backends that dispatch to a dedicated coprocessor hook."
abstract type CoprocessorBackend <: AbstractBackend end

"GPU backends (concrete implementations live in package extensions)."
abstract type GPUBackend <: AbstractBackend end

struct TPUBackend    <: CoprocessorBackend end
struct NPUBackend    <: CoprocessorBackend end
struct FPGABackend   <: CoprocessorBackend end
struct VPUBackend    <: CoprocessorBackend end
struct QPUBackend    <: CoprocessorBackend end
struct DSPBackend    <: CoprocessorBackend end
struct PPUBackend    <: CoprocessorBackend end
struct MathBackend   <: CoprocessorBackend end
struct CryptoBackend <: CoprocessorBackend end

struct CUDABackend  <: GPUBackend end
struct ROCmBackend  <: GPUBackend end
struct MetalBackend <: GPUBackend end

"""
    DeviceCapabilities(backend, cores, clock_mhz, memory_total, memory_available,
                       simd_width, supports_fp16, supports_fp32, supports_fp64,
                       vendor, model)

Static description of a backend device. Field types match the capability
tables in `src/coprocessors/*.jl`.
"""
struct DeviceCapabilities
    backend::AbstractBackend
    cores::Int
    clock_mhz::Int
    memory_total::Int64
    memory_available::Int64
    simd_width::Int
    supports_fp16::Bool
    supports_fp32::Bool
    supports_fp64::Bool
    vendor::String
    model::String
end

"Extension point: per-backend device capabilities. Overloaded by consumers."
function device_capabilities end

"Extension point: per-backend cost model `(backend, op::Symbol, data_size)`."
function estimate_cost end

const _REGISTERED_OPS = Dict{DataType,Set{Symbol}}()

"""
    register_operation!(BackendType, op::Symbol)

Record that `BackendType` supports operation `op`. Called at load time by the
coprocessor files. Returns `nothing`.
"""
function register_operation!(::Type{B}, op::Symbol) where {B<:AbstractBackend}
    push!(get!(_REGISTERED_OPS, B, Set{Symbol}()), op)
    return nothing
end

"Diagnostic sink (no-op in the stub); referenced by the GPU extensions."
_record_diagnostic!(args...; kwargs...) = nothing

"""
    generate_self_healing_hooks(mod, pairs)

In the real AcceleratorGate this synthesises fallback methods so an
unspecialised `CoprocessorBackend` degrades to its Julia implementation. The
consumer's coprocessor files already provide concrete methods for every backend
they define and the test suite never dispatches through an unspecialised
backend, so the stub is a no-op.
"""
generate_self_healing_hooks(mod::Module, pairs) = nothing

end # module AcceleratorGate
