using Test, Random, DataFrames
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

function rwthrows(df; err=ArgumentError, sep=',', na="")
    fname = "nanocsv_test.txt"
    try
        write_csv("test.csv", df, sep=sep, na=na)
        @test_throws err read_csv("test.csv", sep=sep, na=na)
    finally
        isfile(fname) && rm(fname)
    end
end

@testset "basic read and write" begin
    Random.seed!(1)
    rwtest(DataFrame(rand(Int, 5, 5)))
    rwtest(DataFrame(rand(Int, 5, 5)), sep=';', na="NA")
end

@testset "some more complex test" begin
    df = DataFrame(i = [1,2,missing], f=[missing,1.0, 2.0], m=missing,
                   s1=["s1",",",";"], s2=["s2",missing,missing])
    rwtest(df)
    rwtest(df, sep=';', na="NA")
end

@testset "minimal DataFrames" begin
    rwthrows(DataFrame())
    rwthrows(DataFrame(), sep=';', na="NA")
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]))
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]), sep=';', na="NA")
    rwtest(DataFrame(Symbol("")=>missing))
    rwtest(DataFrame(Symbol("")=>missing), sep=';', na="NA")
    rwtest(DataFrame(Symbol("")=>["",missing,""]))
    rwtest(DataFrame(Symbol("")=>["",missing,""]), sep=';', na="NA")
end

