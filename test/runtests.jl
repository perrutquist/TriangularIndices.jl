using TriangularIndices
using Test
using SplittablesTesting

using TriangularIndices: triu_ij2k, triu_k2ij

@testset "UpperTriangularIndices" begin
    iter = UpperTriangularIndices(3)
    @test iter == UpperTriangularIndices(rand(3,3))
    @test first(iter) == (1,1)
    @test last(iter) == (3,3)
    @test iter[3] == (2,2)
    @test length(iter) == 6
    @test collect(iter) == collect(Iterators.filter(ij-><=(ij...), Iterators.product(1:3, 1:3)))
    @test collect(iter) == [(1, 1), (1, 2), (2, 2), (1, 3), (2, 3), (3, 3)]
    @test collect(iter[2:end-1]) == [(1, 2), (2, 2), (1, 3), (2, 3)]
    @test [iter[i] for i in 1:6] == collect(iter)

    iv = iter[2:5]
    civ = collect(iv)
    for i=1:3, j=1:3
        @test findfirst(==((i,j)), iv) === findfirst(==((i,j)), civ)
    end
end

@testset "AllUpperTriangularIndices" begin
    aui = TriangularIndices.AllUpperTriangularIndices()
    nui = UpperTriangularIndices(4)

    @test UpperTriangularIndices() === aui
    @test aui[4] === nui[4]
    @test aui[2:5] === nui[2:5]
    @test aui[Base.OneTo(7)] === nui[Base.OneTo(7)]
    for (a,n) in zip(aui, nui)
        @test a == n
    end
end

@testset "Splittables - UpperTriangularIndices" begin
    i1 = UpperTriangularIndices(1)
    i3 = UpperTriangularIndices(3)
    i9 = UpperTriangularIndices(9)
    iv = i9[3:23]
    SplittablesTesting.test_ordered([i1,i3,i9,iv])
    SplittablesTesting.test_ordered(enumerate.([i1,i3,i9,iv]))
end

@testset "Extensive indexing tests" begin
    r = 1:17:2^30
    
    @test all(triu_ij2k(triu_k2ij(k)) == k for k in r)
    @test all(triu_k2ij(triu_ij2k(i, i)) == (i, i) for i in r)
    @test all(triu_k2ij(triu_ij2k(1, i)) == (1, i) for i in r)
    @test all(triu_k2ij(triu_ij2k(i-1, i)) == (i-1, i) for i = r[2:end])
end

include("test_enumerated.jl")
