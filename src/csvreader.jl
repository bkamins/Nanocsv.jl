function io_next_token(io::IO, sep::Char, na::AbstractString, line::Int)
    eof(io) && return (val="", newline=false)
    buf = IOBuffer()
    c = read(io, Char)
    is_quoted = (c == QUOTE_CHAR)

    newline = false
    if is_quoted
        while true
            if eof(io)
                throw(ArgumentError("unexpected end of file in line $line"))
            end
            c = read(io, Char)
            if c == QUOTE_CHAR
                eof(io) && break
                c = read(io, Char)
                if c == QUOTE_CHAR
                    write(buf, QUOTE_CHAR)
                elseif c == sep
                    break
                elseif c == '\n'
                    newline = true
                    break
                elseif c == '\r'
                    newline = true
                    eof(f) && break
                    Base.peek(io) == Int('\n') && read(io, Char)
                    break
                else
                    throw(ArgumentError("separator or newline expected"*
                                        "after closing quote in line $line"))
                end
            else
                write(buf, c)
            end
        end
    else
        c == sep && return (val="", newline=false)
        write(buf, c)
        while !eof(io)
            c = read(io, Char)
            c == sep && break
            if c == '\n'
                newline = true
                break
            end
            if c == '\r'
                newline = true
                eof(io) && break
                Base.peek(io) == Int(`\n`) && read(io, Char)
                break
            end
            write(buf, c)
        end
    end
    val = String(take!(buf))
    (val= (!is_quoted) && val == na ? missing : val, newline=newline)
end

function ingest_csv(io::IO, sep::Char, na::AbstractString)
    local line
    line_idx = 0
    data = Vector{String}[]
    newline = true
    while !eof(io)
        if newline
            line_idx += 1
            line = String[]
            push!(data, line)
        end
        val, newline = io_next_token(io, sep, na, line_idx)
        push!(line, val)
    end
    data
end

lift_parse(val::Union{Missing, String}, parser::DataType) =
    ismissing(val) ? missing : tryparse(parser, val)

function try_parser(col::Vector{<:Union{Missing, String}}, parser::DataType)
    new_col = lift_parse.(col, parser)
    pos = findfirst(x -> x === nothing, new_col)
    pos === nothing && return new_col
    nothing
end

function rep_try_parser(col::Vector{<:Union{Missing, String}},
                        parsers::Vector{DataType})
    for parser in parsers
        new_col = try_parser(col, parser)
        new_col === nothing || return new_col
    end
    col
end

"""
    read_csv(filename::AbstractString;
             sep::Char=',', header::Bool=true, na::String="",
             parsers::Vector{DataType} = [Int, Float64, Date, DateTime])

    Reads `df` from `filename` CSV file to a `DataFrame` using `sep` separator
    and `na` as string for representing missing value.

    If `header` is `true` then first line of the file is assumed to contain
    column names. In such a case it is assumed that verbatim value `na` is not
    present in this line (a warning will be printed). If column name is equal to
    `na` it should be quoted in source file as `"na"`.

    `"` character is used for quoting fields. In quoted field use `""` to
    represent `"`.

    If `na` is read from CSV verbatim then `DataFrame` will contain `missing`
    in that entry. If a string equal to `na` should be read as `na` then then
    it should be quoted in source file as `"na"`.

    `parsers` controls what conversions `read_csv` tries to perform on
    data that is read in. Conversion is performed using `parse` function and
    `parsers` gives information in which sequence different types should be tried.
"""
function read_csv(filename::AbstractString;
                  sep::Char=',', header::Bool=true, na::String="",
                  parsers::Vector{DataType} = [Int, Float64, Date, DateTime])
    if sep in [QUOTE_CHAR, '\n', '\r']
        throw(ArgumentError("sep is a quote char or a newline"))
    end
    if any(occursin.([QUOTE_CHAR, sep, '\n', '\r'], na))
        throw(ArgumentError("na contains quote, separator or a newline"))
    end
    open(filename) do io
        data = ingest_csv(io, sep, na)
        if header
            if isempty(data)
                throw(ArgumentError("$filename has zero rows and header" *
                                    " was requested"))
            end
            if any(ismissing.(data[1]))
                @warn "$filename had unquoted na in header, " *
                      "parsing as \"missing\" column name"
            end
            names = Symbol.(popfirst!(data))
        end
        if isempty(data)
            if header
                return DataFrame([[] for i in 1:length(names)], names)
            else
                return DataFrame()
            end
        end

        ref_length = length(data[1])
        if header && length(names) != ref_length
            throw(ArgumentError("data in line 1 has different number of " *
                                "columns than header"))
        end
        for (i, data_line) in enumerate(data)
            if length(data_line) != ref_length
                throw(ArgumentError("data in line $i has different " *
                                    "number of columns than data in line 1"))
            end
        end
        cols = [rep_try_parser(getindex.(data, i), parsers) for i in 1:ref_length]
        header ? DataFrame(cols, names) : DataFrame(cols)
    end
end

