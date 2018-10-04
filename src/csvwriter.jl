function str_quote(str::AbstractString, delim::Char, na::AbstractString)::String
    do_quote = false
    for c in str
        if c in [QUOTE_CHAR, delim, '\n', '\r']
            do_quote = true
            break
        end
    end

    do_quote || str == na || return str

    io = IOBuffer(sizehint=sizeof(str)+8)
    write(io, QUOTE_CHAR)
    for c in str
        write(io, c)
        if c == QUOTE_CHAR
            write(io, QUOTE_CHAR)
            had_q = true
        end
    end
    write(io, QUOTE_CHAR)
    String(take!(io))
end

quote_with_missing(val, delim, na) =
    ismissing(val) ? na : str_quote(string(val), delim, na)

"""
    write_csv(io::IO, df::DataFrame;
          delim::Char=',', na::AbstractString="")
    write_csv(filename::AbstractString, df::DataFrame;
              delim::Char=',', na::AbstractString="")

    Writes `df` to `io` stream or to file `filename` as CSV using
    `delim` separator and `na` as string for representing missing value.

    `"` character is used for quoting fields. In quoted field use `""` to
    represent `"`.

    `na` is written to CSV verbatim when `DataFrame` contains `missing`.
    If a string is equal to `na` then it is written to CSV quoted as `"na"`.
"""
function write_csv(io::IO, df::DataFrame;
                   delim::Char=',', na::AbstractString="")
    if delim in [QUOTE_CHAR, '\n', '\r']
        throw(ArgumentError("delim is a quote char or a newline"))
    end
    if any(occursin.([QUOTE_CHAR, delim, '\n', '\r'], na))
        throw(ArgumentError("na contains quote, separator or a newline"))
    end
    if length(names(df)) > 0
        println(io, join(str_quote.(string.(names(df)), delim, na), delim))
        for i in 1:nrow(df)
            line = [quote_with_missing(df[i,j], delim, na) for j in 1:ncol(df)]
            println(io, join(line, delim))
        end
    end
end

function write_csv(filename::AbstractString, df::DataFrame;
                   delim::Char=',', na::AbstractString="")
    open(filename, "w") do io
        write_csv(io, df; delim=delim, na=na)
    end
end
