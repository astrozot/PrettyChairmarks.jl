# PrettyChairmarks

[![Build Status](https://github.com/astrozot/PrettyChairmarks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/astrozot/PrettyChairmarks.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package extends
[Chairmarks](https://github.com/LilithHafner/Chairmarks.jl) by defining a new
macro `@bs` that shows statistical results of the execution, much like the
`@benchmark` macro from
[BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl).

In fact, the code is just an adaptation of the BenchmarkTools code.

Note that this package re-export the `@b` and `@be` macros of Chairmarks:
therefore, there is no need to load also Chairmarks.

## Example

```julia-repl
julia> using PrettyChairmarks

julia> @bs (rand(10)) sort(_) seconds=3
Chairmarks.Benchmark: 101378 samples with 356 evaluations.
 Range (min … max):  55.671 ns …  1.567 μs  ┊ GC (min … max): 0.00% … 89.48%
 Time  (median):     73.284 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   77.698 ns ± 32.088 ns  ┊ GC (mean ± σ):  0.09% ±  2.82%

       ▅█▇▆▄▁
  ▁▁▂▅███████▆▄▃▂▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▂
  55.7 ns         Histogram: frequency by time         189 ns <

 Memory estimate: 144.0 bytes, allocs estimate: 1.
 ```
