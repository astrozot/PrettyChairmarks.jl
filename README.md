# PrettyChairmarks

[![Build Status](https://github.com/astrozot/PrettyChairmarks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/astrozot/PrettyChairmarks.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package extends
[Chairmarks](https://github.com/LilithHafner/Chairmarks.jl) by defining a new
macro `@bs` that shows statistical results of the execution, much like the
`@benchmark` macro from
[BenchmarkTools](https://github.com/JuliaCI/BenchmarkTools.jl).
The macro `@bs` supports benchmarking single as well as multiple expressions (see examples below).

In fact, the code is just an adaptation of the BenchmarkTools code.

Note that this package re-export the `@b` and `@be` macros of Chairmarks:
therefore, there is no need to load also Chairmarks.

## Example

### Benchmarking a single expression

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

### Comparing multiple expressions

```julia-repl
julia> using PrettyChairmarks

julia> bb = @bs 500 rand(_), rand(_^2)
Chairmarks.Benchmark: 888 samples with 1 evaluation.
 Range (min … max):  291.000 ns …  1.041 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     375.000 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   409.350 ns ± 99.203 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  █                                                             
  █▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▂
  291 ns          Histogram: frequency by time         1.14 ms <

 Memory estimate: 4.06 KiB, allocs estimate: 3.
Chairmarks.Benchmark: 888 samples with 1 evaluation.
 Range (min … max):  124.625 μs …   1.139 ms  ┊ GC (min … max): 0.00% … 88.21%
 Time  (median):     178.646 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   204.882 μs ± 107.588 μs  ┊ GC (mean ± σ):  4.37% ± 16.51%

        ▅  █▆▄▁                                                  
  ▁▁▁▁▁▁█▇▅████▇▄▁▁▁▁▁▅▁▅▅▅▆▆▆▇▅▅▅▅▄▆▅▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ ▇
  291 ns        Histogram: log(frequency) by time       1.14 ms <

 Memory estimate: 1.91 MiB, allocs estimate: 3.
 ```