function io_next_token(io::IO, delim::Char, na::AbstractString,
                       line::Int, hasheader::Bool)
    isheader = line == 1 && hasheader
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
                elseif c == delim
                    break
                elseif c == '\n'
                    newline = true
                    break
                elseif c == '\r'
                    newline = true
                    !eof(f) && Base.peek(io) == Int('\n') && read(io, Char)
                    break
                else
                    throw(ArgumentError("separator or newline expected "*
                                        "after closing quote in line $line"))
                end
            else
                write(buf, c)
            end
        end
    else
        if c == delim
            return (val = !isheader && na == "" ? missing : "", newline=false)
        end
        if c == '\n'
            return (val = !isheader && na == "" ? missing : "", newline=true)
        end
        if c == '\r'
            !eof(f) && Base.peek(io) == Int('\n') && read(io, Char)
            return (val = !isheader && na == "" ? missing : "", newline=true)
        end
        write(buf, c)
        while !eof(io)
            c = read(io, Char)
            c == delim && break
            if c == '\n'
                newline = true
                break
            end
            if c == '\r'
                newline = true
                eof(io) && break
                Base.peek(io) == Int('\n') && read(io, Char)
                break
            end
            write(buf, c)
        end
    end
    val = String(take!(buf))
    (val= !is_quoted && !isheader && val == na ? missing : val, newline=newline)
end

function ingest_csv(io::IO, delim::Char, na::AbstractString, hasheader::Bool)
    local line
    line_idx = 0
    data = Vector{Union{Missing,String}}[]
    newline = true
    while !eof(io)
        if newline
            line_idx += 1
            line = Union{Missing,String}[]
            push!(data, line)
        end
        val, newline = io_next_token(io, delim, na, line_idx, hasheader)
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
                        parsers::Vector)
    for parser in parsers
        new_col = try_parser(col, parser)
        new_col === nothing || return new_col
    end
    any(ismissing.(col)) ? col : Vector{String}(col)
end

"""
    read_csv(filename::AbstractString;
             delim::Char=',', header::Bool=true, na::AbstractString="",
             parsers::Vector = [Int, Float64])

    Reads from `filename` CSV file to a `DataFrame` using `delim` separator
    and `na` as string for representing missing value.

    If `header` is `true` then first line of the file is assumed to contain
    column names. In such a case it is assumed that verbatim value `na` is allowed
    and is parsed as column name.

    `"` character is used for quoting fields. In quoted field use `""` to
    represent `"`.

    If `na` is read from CSV verbatim then `DataFrame` will contain `missing`
    in that entry. If a string equal to `na` should be read as `na` then then
    it should be quoted in source file as `"na"`.

    `parsers` controls what conversions `read_csv` tries to perform on
    data that is read in. Conversion is performed using `parse` function and
    `parsers` gives information in which sequence different types should be tried.

    Additionally you can control how much data is read in using the parameters:
    * `skiphead`: number of lines to skip on top of the file
    * `nrows`: if `nothing`: all lines are read in,
               if negative: number of parsed data lines to remove from the tail,
               if positive: number of parsed data lines to keep at head
"""
function read_csv(filename::AbstractString;
                  delim::Char=',', header::Bool=true, na::AbstractString="",
                  parsers::Vector = [Int, Float64],
                  skiphead::Int=0, nrows::Union{Int, Nothing}=nothing)
    if delim in [QUOTE_CHAR, '\n', '\r']
        throw(ArgumentError("delim is a quote char or a newline"))
    end
    if any(occursin.([QUOTE_CHAR, delim, '\n', '\r'], na))
        throw(ArgumentError("na contains quote, separator or a newline"))
    end
    open(filename) do io
        for i in 1:skiphead
            readline(io)
        end
        data = ingest_csv(io, delim, na, header)
        if header
            if isempty(data)
                throw(ArgumentError("$filename has zero rows and header" *
                                    " was requested"))
            end
            if any(ismissing.(data[1]))
                @error "Unexpected error when parsing header of $filename"
            end
            names = Symbol.(popfirst!(data))
        end
        if !(nrows === nothing)
            if nrows < 0
                data = data[1:(end-nrows)]
            else
                data = data[1:nrows]
            end
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
            throw(ArgumentError("data in line 2 has different number of " *
                                "columns than header"))
        end
        for (i, data_line) in enumerate(data)
            if length(data_line) != ref_length
                throw(ArgumentError("data in line $(i+header) has different " *
                                    "number of columns than data in line $(i+header)"))
            end
        end
        cols = [rep_try_parser(getindex.(data, i), parsers) for i in 1:ref_length]
        header ? DataFrame(cols, names) : DataFrame(cols)
    end
end

