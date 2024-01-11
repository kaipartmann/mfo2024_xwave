using Peridynamics
using CairoMakie
using CairoMakie.Makie.Colors
using NaturalSort
using FileIO
using ProgressMeter

function find_limits(results::Vector{Dict{String, VecOrMat{Float64}}}, field::String,
                     dim::Int)

    # check if field is written in results
    if !in(field, keys(first(results)))
        error("VTK files do not contain field '$field'!\n")
    end

    # check if dim is either 1, 2, or 3
    if !in(dim, 1:3)
        error("Wrong dimension! dim ∈ 1:3, but is dim=$dim\n")
    end

    # minimum and maximum value
    minval = typemax(Float64) # biggest possible value of Float64
    maxval = typemin(Float64) # smallest possible value of Float64

    # loop over all time steps
    for result in results

        # minimum and maximum of this time step
        minval_t = @views minimum(result[field][dim,:])
        maxval_t = @views maximum(result[field][dim,:])

        # update xmin if new value is smaller
        if minval_t < minval
            minval = minval_t
        end

        # update xmax if new value is bigger
        if maxval_t > maxval
            maxval = maxval_t
        end
    end

    # leave some margins for the plots
    y_len = maxval - minval
    ymin = isapprox(minval, 0; atol = 1e-8) ? -0.1y_len : minval * 1.05
    ymax = isapprox(maxval, 0; atol = 1e-8) ? 0.1y_len : maxval * 1.05

    return ymin, ymax
end

function ux_plot(img_file::String, result::Dict{String, VecOrMat{Float64}},
                 ylimits::Tuple{Float64, Float64})
    fig = Figure(size=(600, 300))
    ax = Axis(fig[1,1];
        xlabel="x-position [m]",
        ylabel="x-displacement [μm]",
        limits=(nothing, nothing, ylimits[1] * 1e6, ylimits[2] * 1e6),
        topspinevisible=false,
        rightspinevisible=false,
    )
    @views x = result["Position"][1,:]
    @views y = 1e6 .* result["Displacement"][1,:]
    scatter!(ax, x, y; markersize=4)
    save(img_file, fig; px_per_unit=3)
    return fig
end

function postproc(path::AbstractString, imgpath::AbstractString)
    ispath(path) || error("no results to process in path:\n$path\n")

    # get all the VTK files
    vtk_files_unsorted = filter(x -> endswith(x, ".vtu"), readdir(path; join=true))
    isempty(vtk_files_unsorted) && error("No vtu-files in path:\n$path\n")
    vtk_files = sort(vtk_files_unsorted; lt=natural)

    # import the results -> very RAM intensive!
    results = read_vtk.(vtk_files)

    # img directory
    if ispath(imgpath)
        rm(imgpath; recursive=true)
        @info "Deleted image folder: $imgpath"
    end
    mkpath(imgpath)

    # find y-limits over all time steps
    ylimits = find_limits(results, "Displacement", 1)

    # image paths for each time step
    imgfiles = [joinpath(imgpath, string("img_", i, ".png")) for i in eachindex(results)]

    # loop over the results and create a plot for every time step
    @info "Creating images..."
    p = Progress(length(results); color=:normal, barlen=40)
    for i in eachindex(results)
        ux_plot(imgfiles[i], results[i], ylimits)
        next!(p)
    end
    finish!(p)

    return nothing
end
