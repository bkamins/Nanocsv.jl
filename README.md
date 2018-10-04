Nanocsv.jl
=============

A minimal implementation of CSV reader/writer for Julia.
It reads and writes `DataFrames` from/to file on disk.

**Installation**: at the Julia REPL, `using Pkg; Pkg.add(PackageSpec(url="https://github.com/bkamins/Nanocsv.jl"))`

### Design

* always use `"` as quote character, `""` represents a quote in quoted field
* you can change field separator using `delim` keyword argument
* when data is written to disk then `string` function is used to get its representation
* by default tries to parse columns to `Int`, `Float64` using `parse` function and falls back to `String`; you can change list or sequence of tried parsers using `parsers` keyword argument
* handles missing values using `na` keyword argument; `na` is always *unquoted* when reading/writing (except if header line is present in a file as then it is read as is); if string equal to `na` is written it is always quoted; if value equal to `na` is quoted in file then it is treated as a valid value not `missing`

### Functions provided


Writing CSV to disk:
```julia
write_csv(io::IO, df::DataFrame;
          delim::Char=',', na::AbstractString="")
write_csv(filename::AbstractString, df::DataFrame;
          delim::Char=',', na::AbstractString="")
```

Reading CSV from disk:
```julia
read_csv(io::IO;
         delim::Char=',', header::Bool=true, na::String="",
         parsers::Vector{DataType} = [Int, Float64],
         skiphead::Int=0, nrows::Union{Int, Nothing}=nothing)
read_csv(filename::AbstractString;
         delim::Char=',', header::Bool=true, na::String="",
         parsers::Vector{DataType} = [Int, Float64],
         skiphead::Int=0, nrows::Union{Int, Nothing}=nothing)
```
