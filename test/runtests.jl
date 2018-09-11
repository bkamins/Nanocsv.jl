using Test, Random, DataFrames
using Nanocsv

@testset "basic read and write" begin
    Random.seed!(1)
    df = DataFrame(rand(Int, 100, 100))
    write_csv("test.csv", df)
    df2 = read_csv("test.csv")
    @test df == df2
    rm("test.csv")
end

@testset "some more complex test" begin
    df = DataFrame(i = [1,2,missing], f=[missing,1.0, 2.0], m=missing,
                   d=Date("2000-01-01"), t=DateTime("2000-01-01"),
                   c='c', s=["s",missing,missing])
    write_csv("test.csv", df)
    df2 = read_csv("test.csv")
    @test df == df2
    rm("test.csv")
end
