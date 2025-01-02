module PrettyChairmarks

using Chairmarks
using Printf
import Statistics

export @b, @be, @bs, @bcomp

prettypercent(p) = string(@sprintf("%.2f", p * 100), "%")

function prettytime(t)
    # @@@ ChairMarks.print_time(io, t)
    if t < 1e-6
        value, units = t * 1e9, "ns"
    elseif t < 1e-3
        value, units = t * 1e6, "μs"
    elseif t < 1
        value, units = t * 1e3, "ms"
    else
        value, units = t, "s"
    end
    return string(@sprintf("%.3f", value), " ", units)
end

function prettymemory(b)
    # @@@ ChairMarks.print_allocs(io, allocs, bytes)
    if b < 1024
        return string(b, " bytes")
    elseif b < 1024^2
        value, units = b / 1024, "KiB"
    elseif b < 1024^3
        value, units = b / 1024^2, "MiB"
    else
        value, units = b / 1024^3, "GiB"
    end
    return string(@sprintf("%.2f", value), " ", units)
end

function withtypename(f, io, t)
    needtype = get(io, :typeinfo, Nothing) !== typeof(t)
    if needtype
        print(io, nameof(typeof(t)), '(')
    end
    f()
    if needtype
        print(io, ')')
    end
end

function bindata(sorteddata, nbins, min, max)
    Δ = (max - min) / nbins
    bins = zeros(nbins)
    lastpos = 0
    for i in 1:nbins
        pos = searchsortedlast(sorteddata, min + i * Δ)
        bins[i] = pos - lastpos
        lastpos = pos
    end
    return bins
end
bindata(sorteddata, nbins) = bindata(sorteddata, nbins, first(sorteddata), last(sorteddata))

function asciihist(bins, height=1)
    histbars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█']
    if minimum(bins) == 0
        barheights =
            2 .+ round.(Int, (height * length(histbars) - 2) * bins ./ maximum(bins))
        barheights[bins .== 0] .= 1
    else
        barheights =
            1 .+ round.(Int, (height * length(histbars) - 1) * bins ./ maximum(bins))
    end
    heightmatrix = [
        min(length(histbars), barheights[b] - (h - 1) * length(histbars)) for
        h in height:-1:1, b in 1:length(bins)
    ]
    return map(height -> if height < 1
        ' '
    else
        histbars[height]
    end, heightmatrix)
end

struct PrettyBenchmark
    b::Chairmarks.Benchmark
end

postprocess(b::Chairmarks.Benchmark) = PrettyBenchmark(b)
postprocess(bmarks::Tuple{Vararg{Chairmarks.Benchmark}}) = PrettyBenchmark.(bmarks)

macro bs(args...)
    call = Chairmarks.process_args(args)
    :(postprocess($call))
end

_summary(io, t, args...) = withtypename(() -> print(io, args...), io, t)

Base.summary(io::IO, t::PrettyBenchmark) = _summary(io, t, prettytime(minimum(t -> t.time, t.b.samples)))

_show(io, t) =
    if get(io, :compact, true)
        summary(io, t)
    else
        show(io, MIME"text/plain"(), t)
    end

Base.show(io::IO, t::PrettyBenchmark) = _show(io, t)

function Base.show(io::IO, ::MIME"text/plain", t1::PrettyBenchmark; histmax::Union{T,Nothing} = nothing, histmin::Union{T,Nothing} = nothing) where {T<:AbstractFloat}
    t = t1.b
    pad = get(io, :pad, "")
    print(
        io,
        "Chairmarks.Benchmark: ",
        length(t.samples),
        " sample",
        if length(t.samples) > 1
            "s"
        else
            ""
        end,
        " with ",
        Int(t.samples[1].evals),
        " evaluation",
        if t.samples[1].evals > 1
            "s"
        else
            ""
        end,
        ".\n",
    )

    perm = sortperm(t.samples; by=x -> x.time)
    times = [x.time for x ∈ t.samples[perm]]
    gcfracs = [x.gc_fraction for x ∈ t.samples[perm]]

    if length(t.samples) > 1
        medtime, medgc = prettytime(Statistics.median(times)), prettypercent(Statistics.median(gcfracs))
        avgtime, avggc = prettytime(Statistics.mean(times)), prettypercent(Statistics.mean(gcfracs))
        stdtime, stdgc = prettytime(Statistics.std(times)), prettypercent(Statistics.std(gcfracs))
        mintime, mingc = prettytime(minimum(times)), prettypercent(minimum(gcfracs))
        maxtime, maxgc = prettytime(maximum(times)), prettypercent(maximum(gcfracs))
        memorystr = prettymemory(minimum(x -> x.bytes, t.samples))
        allocsstr = string(round(Int, minimum(x -> x.allocs, t.samples)))
    elseif length(t.samples) == 1
        print(io, pad, " Single result which took ")
        printstyled(io, prettytime(times[1]); color=:blue)
        print(io, " (", prettypercent(gcfracs[1]), " GC) ")
        print(io, "to evaluate,\n")
        print(io, pad, " with a memory estimate of ")
        printstyled(io, prettymemory(t.samples[1].bytes); color=:yellow)
        print(io, ", over ")
        printstyled(io, round(Int, t.samples[1].allocs); color=:yellow)
        print(io, " allocations.")
        return nothing
    else
        print(io, pad, " No results.")
        return nothing
    end

    lmaxtimewidth = maximum(length.((medtime, avgtime, mintime)))
    rmaxtimewidth = maximum(length.((stdtime, maxtime)))
    lmaxgcwidth = maximum(length.((medgc, avggc, mingc)))
    rmaxgcwidth = maximum(length.((stdgc, maxgc)))

    # Main stats

    print(io, pad, " Range ")
    printstyled(io, "("; color=:light_black)
    printstyled(io, "min"; color=:cyan, bold=true)
    print(io, " … ")
    printstyled(io, "max"; color=:magenta)
    printstyled(io, "):  "; color=:light_black)
    printstyled(io, lpad(mintime, lmaxtimewidth); color=:cyan, bold=true)
    print(io, " … ")
    printstyled(io, lpad(maxtime, rmaxtimewidth); color=:magenta)
    print(io, "  ")
    printstyled(io, "┊"; color=:light_black)
    print(io, " GC ")
    printstyled(io, "("; color=:light_black)
    print(io, "min … max")
    printstyled(io, "): "; color=:light_black)
    print(io, lpad(mingc, lmaxgcwidth), " … ", lpad(maxgc, rmaxgcwidth))

    print(io, "\n", pad, " Time  ")
    printstyled(io, "("; color=:light_black)
    printstyled(io, "median"; color=:blue, bold=true)
    printstyled(io, "):     "; color=:light_black)
    printstyled(
        io,
        lpad(medtime, lmaxtimewidth),
        rpad(" ", rmaxtimewidth + 5);
        color=:blue,
        bold=true,
    )
    printstyled(io, "┊"; color=:light_black)
    print(io, " GC ")
    printstyled(io, "("; color=:light_black)
    print(io, "median")
    printstyled(io, "):    "; color=:light_black)
    print(io, lpad(medgc, lmaxgcwidth))

    print(io, "\n", pad, " Time  ")
    printstyled(io, "("; color=:light_black)
    printstyled(io, "mean"; color=:green, bold=true)
    print(io, " ± ")
    printstyled(io, "σ"; color=:green)
    printstyled(io, "):   "; color=:light_black)
    printstyled(io, lpad(avgtime, lmaxtimewidth); color=:green, bold=true)
    print(io, " ± ")
    printstyled(io, lpad(stdtime, rmaxtimewidth); color=:green)
    print(io, "  ")
    printstyled(io, "┊"; color=:light_black)
    print(io, " GC ")
    printstyled(io, "("; color=:light_black)
    print(io, "mean ± σ")
    printstyled(io, "):  "; color=:light_black)
    print(io, lpad(avggc, lmaxgcwidth), " ± ", lpad(stdgc, rmaxgcwidth))

    # Histogram

    histquantile = 0.99
    # The height and width of the printed histogram in characters.
    histheight = 2
    histwidth = 42 + lmaxtimewidth + rmaxtimewidth

    histtimes = times[1:round(Int, histquantile * end)]
    if histmin === nothing 
        histmin = get(io, :histmin, first(histtimes))
    end
    if histmax === nothing
        histmax = get(io, :histmax, last(histtimes))
    end
    logbins = get(io, :logbins, nothing)
    bins = bindata(histtimes, histwidth - 1, histmin, histmax)
    append!(bins, [1, floor((1 - histquantile) * length(times))])
    # if median size of (bins with >10% average data/bin) is less than 5% of max bin size, log the bin sizes
    if logbins === true || (
        logbins === nothing &&
        Statistics.median(filter(b -> b > 0.1 * length(times) / histwidth, bins)) / maximum(bins) <
        0.05
    )
        bins, logbins = log.(1 .+ bins), true
    else
        logbins = false
    end
    hist = asciihist(bins, histheight)
    hist[:, end - 1] .= ' '
    maxbin = maximum(bins)

    delta1 = (histmax - histmin) / (histwidth - 1)
    if delta1 > 0
        medpos = 1 + round(Int, (histtimes[length(times) ÷ 2] - histmin) / delta1)
        avgpos = 1 + round(Int, (Statistics.mean(times) - histmin) / delta1)
    else
        medpos, avgpos = 1, 1
    end

    print(io, "\n")
    for r in axes(hist, 1)
        print(io, "\n", pad, "  ")
        for (i, bar) in enumerate(view(hist, r, :))
            color = :default
            if i == avgpos
                color = :green
            end
            if i == medpos
                color = :blue
            end
            printstyled(io, bar; color=color)
        end
    end

    remtrailingzeros(timestr) = replace(timestr, r"\.?0+ " => " ")
    minhisttime, maxhisttime =
        remtrailingzeros.(prettytime.(round.([histmin, histmax], sigdigits=3)))

    print(io, "\n", pad, "  ", minhisttime)
    caption = "Histogram: " * (logbins ? "log(frequency)" : "frequency") * " by time"
    if logbins
        printstyled(
            io,
            " "^((histwidth - length(caption)) ÷ 2 - length(minhisttime));
            color=:light_black,
        )
        printstyled(io, "Histogram: "; color=:light_black)
        printstyled(io, "log("; bold=true, color=:light_black)
        printstyled(io, "frequency"; color=:light_black)
        printstyled(io, ")"; bold=true, color=:light_black)
        printstyled(io, " by time"; color=:light_black)
    else
        printstyled(
            io,
            " "^((histwidth - length(caption)) ÷ 2 - length(minhisttime)),
            caption;
            color=:light_black,
        )
    end
    print(io, lpad(maxhisttime, ceil(Int, (histwidth - length(caption)) / 2) - 1), " ")
    printstyled(io, "<"; bold=true)

    # Memory info

    print(io, "\n\n", pad, " Memory estimate")
    printstyled(io, ": "; color=:light_black)
    printstyled(io, memorystr; color=:yellow)
    print(io, ", allocs estimate")
    printstyled(io, ": "; color=:light_black)
    printstyled(io, allocsstr; color=:yellow)
    return print(io, ".")
end

function Base.show(io::IO, m::MIME"text/plain", bmks::Tuple{Vararg{PrettyBenchmark}})
    # set the min and max for the hist
    histquantile = 0.99
    _hmin = minimum(t -> minimum(s -> s.time, t.b.samples), bmks)
    _hmax = maximum(t -> maximum(sort([s.time for s in t.b.samples])[1:round(Int, histquantile * end)]), bmks)

    for b in bmks 
        show(io, m, b; histmax = _hmax, histmin = _hmin)
        print(io, "\n")
    end
end

end
