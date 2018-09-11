function str_quote(str::AbstractString, sep::Char, na::AbstractString)::String
    do_quote = false
    for c in str
        if c in [QUOTE_CHAR, sep, '\n', '\r']
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

quote_with_missing(val, sep, na) =
    ismissing(val) ? na : str_quote(string(val), sep, na)

"""
    write_csv(filename::AbstractString, df::DataFrame;
              sep::Char=',', na::AbstractString="")

    Writes `df` to disk as `filename` CSV file using `sep` separator
    and `na` as string for representing missing value.

    `"` character is used for quoting fields. In quoted field use `""` to
    represent `"`.

    `na` is written to CSV verbatim when `DataFrame` contains `missing`.
    If a string is equal to `na` then it is written to CSV quoted as `"na"`.
"""
function write_csv(filename::AbstractString, df::DataFrame;
                   sep::Char=',', na::AbstractString="")
    if sep in [QUOTE_CHAR, '\n', '\r']
        throw(ArgumentError("sep is a quote char or a newline"))
    end
    if any(occursin.([QUOTE_CHAR, sep, '\n', '\r'], na))
        throw(ArgumentError("na contains quote, separator or a newline"))
    end
    open(filename, "w") do io
        if !isempty(df)
            println(io, join(str_quote.(string.(names(df)), sep, na), sep))
            for i in 1:nrow(df)
                line = [quote_with_missing(df[i,j], sep, na) for j in 1:ncol(df)]
                println(io, join(line, sep))
            end
        end
    end
end
