using PrettyChairmarks
using Test

@testset "Pretty output" begin
    buf = IOBuffer()
    Base.show(buf, MIME("text/plain"), @bs sin(3.0))
    s = String(take!(buf))
    @test startswith(s, r"Chairmarks\.Benchmark: [0-9]* samples? with [0-9]* evaluations?\.")
    @test endswith(s, "allocs estimate: 0.")
    @test occursin(r"Histogram: (log\()?frequency\)? by time", s)
end
