using TriangularIndices
using Test

@testset "OffsetEnumerate{UpperTriangularIndices}" begin
    iter = enumerate(UpperTriangularIndices(3))
    @test first(iter) == (1, (1,1))
    @test last(iter) == (6, (3,3))
    @test iter[3] == (3, (2,2))
    @test length(iter) == 6
    @test collect(iter) == collect(enumerate(Iterators.filter(ij-><=(ij...), Iterators.product(1:3, 1:3))))
    @test collect(iter[2:end-1]) == [(2, (1, 2)), (3, (2, 2)), (4, (1, 3)), (5, (2, 3))]
    @test [iter[i] for i in 1:6] == collect(iter)
end
