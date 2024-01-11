using VideoIO
using FileIO
using NaturalSort
using ProgressMeter

function get_png_files(path::String)
    png_files_unsorted =filter(x -> endswith(x, ".png"), readdir(path; join=true))
    isempty(png_files_unsorted) && error("No png files in path:\n$path\n")
    png_files = sort(png_files_unsorted; lt=natural)
    return png_files
end

"""
    make_video(videoname::String, png_files::Vector{String}; fps::Int=24)

Create a MP4-video with the name `videoname` of the png files in `png_files`.
Optionally specify the frames per second with the `fps` keyword.
"""
function make_video(videoname::String, png_files::Vector{String}; fps::Int=24)

    # check if videoname has .mp4 extension
    _, ext = splitext(videoname)
    if ext !== ".mp4"
        error("Invalid file extension! Should be .mp4, instead got: ", ext, "\n")
    end

    # check if all files are valid
    for file in png_files
        !isfile(file) && error("Invalid path! The file\n", file, "\ndoes not exist!\n")
    end

    # if video exists, delete!
    if isfile(videoname)
        rm(videoname)
        @info "Deleted video: $videoname"
    end

    # set encoding options to good defaults
    encoder_options = (crf=23, preset="medium")

    # progress logging
    @info "Encoding PNG-series to MP4-video:" videoname fps
    p = Progress(length(png_files); color=:normal, barlen=40)

    # write the video
    open_video_out(videoname, load(first(png_files));
        framerate=fps,
        encoder_options=encoder_options,
        target_pix_fmt=VideoIO.AV_PIX_FMT_YUV420P,
    ) do writer
        for file in png_files
            write(writer, load(file))
            next!(p)
        end
    end
    finish!(p)

    return nothing
end
