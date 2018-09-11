using Test, Random, DataFrames
using Nanocsv

@testset "basic read and write" begin
    Random.seed!(1)
    df = DataFrame(rand(Int, 100, 100))
    write_csv("test.csv", df)
    df2 = read_csv("test.csv")
    @test df == df
    rm("test.csv")
end

