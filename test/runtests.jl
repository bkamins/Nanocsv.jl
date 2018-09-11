using Test, Random, DataFrames, Dates
using Nanocsv

function rwtest(df; sep=',', na="")
    fname = "nanocsv_test.txt"
    try
        write_csv("test.csv", df, sep=sep, na=na)
        df2 = read_csv("test.csv", sep=sep, na=na)
        @test isequal(df, df2)
    finally
        isfile(fname) && rm(fname)
    end
end

@testset "basic read and write" begin
    Random.seed!(1)
    rwtest(DataFrame(rand(Int, 5, 5)))
    rwtest(DataFrame(rand(Int, 5, 5)), sep=';' na="NA")
end

@testset "some more complex test" begin
    df = DataFrame(i = [1,2,missing], f=[missing,1.0, 2.0], m=missing,
                   d=Date("2000-01-01"), t=DateTime("2000-01-01"),
                   s1=["s1",",",";"] s2=["s2",missing,missing])
    rwtest(df)
    rwtest(df, sep=';' na="NA")
end

@testset "minimal DataFrames" begin
    rwtest(DataFrame())
    rwtest(DataFrame(), sep=';' na="NA")
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]))
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]), sep=';' na="NA")
    rwtest(DataFrame(Symbol("")=>missing))
    rwtest(DataFrame(Symbol("")=>missing), sep=';' na="NA")
    rwtest(DataFrame(Symbol("")=>["",missing,""]))
    rwtest(DataFrame(Symbol("")=>["",missing,""]), sep=';' na="NA")
end
