using Base.Test
using ArraySlices

# check iteration and values
let 
    X = [1  2  3; 
         4  8 12; 
         9 18 27]
    for (i, col) in enumerate(columns(X))
        @test col == [i, 4i, 9i]
    end 
    for (i, row) in enumerate(rows(X))
        @test row == i^2*[1, 2, 3]
    end 

    for (c1, c2) in zip(columns(X), rows(X'))
        @test c1 == c2
    end
end

# check getindexing
let 
    X = [1  2  3; 
         4  8 12; 
         9 18 27]
    cols = columns(X)
    @test cols[1] == [1, 4, 9]
end

# constructor checks for indexed dimension
let 
    for nd = 2:5
        X = randn(rand(1:10, nd)...)
        @test_throws ErrorException slices(X, Val{0})
        @test_throws ErrorException slices(X, Val{nd+1})
    end
end

# check length and size
let 
    X = randn(1, 2, 3, 4, 5, 6)
    for i = 1:ndims(X)
        @test length(slices(X, Val{i})) == i
        @test size(slices(X, Val{i})) == (i, )
    end
end

# eltype should match that of built in slice function
let 
    X = randn(5, 5, 5, 5, 5)
    @test typeof(view(X, 1, :, :, :, :)) == eltype(slices(X, Val{1}))
    @test typeof(view(X, :, 1, :, :, :)) == eltype(slices(X, Val{2}))
    @test typeof(view(X, :, :, 1, :, :)) == eltype(slices(X, Val{3}))
    @test typeof(view(X, :, :, :, 1, :)) == eltype(slices(X, Val{4}))
    @test typeof(view(X, :, :, :, :, 1)) == eltype(slices(X, Val{5}))
end