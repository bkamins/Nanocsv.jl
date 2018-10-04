using Test, Random, DataFrames
using Nanocsv

function rwtest(df; delim=',', na="")
    fname = "nanocsv_test.txt"
    try
        write_csv(fname, df, delim=delim, na=na)
        df2 = read_csv(fname, delim=delim, na=na)
        @test isequal(df, df2)
    finally
        isfile(fname) && rm(fname)
    end
end

function rwthrows(df; err=ArgumentError, delim=',', na="")
    fname = "nanocsv_test.txt"
    try
        write_csv(fname, df, delim=delim, na=na)
        @test_throws err read_csv(fname, delim=delim, na=na)
    finally
        isfile(fname) && rm(fname)
    end
end

@testset "basic read and write" begin
    Random.seed!(1)
    rwtest(DataFrame(rand(Int, 5, 5)))
    rwtest(DataFrame(rand(Int, 5, 5)), delim=';', na="NA")
end

@testset "some more complex test" begin
    df = DataFrame(i = [1,2,missing], f=[missing,1.0, 2.0], m=missing,
                   s1=["s1",",",";"], s2=["s2",missing,missing])
    rwtest(df)
    rwtest(df, delim=';', na="NA")
end

@testset "minimal DataFrames" begin
    rwthrows(DataFrame())
    rwthrows(DataFrame(), delim=';', na="NA")
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]))
    rwtest(DataFrame(:a=>[], :b=>[], Symbol("")=>[]), delim=';', na="NA")
    rwtest(DataFrame(Symbol("")=>missing))
    rwtest(DataFrame(Symbol("")=>missing), delim=';', na="NA")
    rwtest(DataFrame(Symbol("")=>["",missing,""]))
    rwtest(DataFrame(Symbol("")=>["",missing,""]), delim=';', na="NA")
end

