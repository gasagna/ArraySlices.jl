__precompile__()
module ArraySlices

import Base: length, size, eltype, getindex

export slices, columns, rows

# Type parameters
# 
# F : type of SubArray
# D : indexed dimension of the array
# A : array type
# 
immutable SliceIterator{F, D, A<:AbstractArray} <: AbstractVector{F}
    array::A
end

# ensure compatibility between versions
if VERSION < v"0.5-dev"
    _get_L(D, N) = D == 1 ? N : D
else
    _get_L(D, N) = D == 1 || D == N ? true : false
end

"""
    slices(array, dim)

Return a `SliceIterator` object to loop over the slices of `array` along
dimension `dim`. 

"""
function slices{T, N, D}(array::AbstractArray{T, N}, ::Type{Val{D}})
    # checks
    1 <= D <= N || error("invalid slice dimension")

    # construct type of slice
    # example: SubArray{Float64, 1, Array{Float64,2}, Tuple{Int64, Colon}, true}
    F = SubArray{T, 
                 N-1, 
                 typeof(array), 
                 Tuple{[j == D ? Int : Colon for j = 1:N]...},
                 _get_L(D, N)}
    
    # build and return iterator
    SliceIterator{F, D, typeof(array)}(array)
end

# ~~~ Array interface ~~~
eltype{F}(s::SliceIterator{F}) = F
length{F, D}(s::SliceIterator{F, D}) = size(s.array, D)
size(s::SliceIterator) = (length(s), )

# build code that produces slices with the correct indexing
@generated function getindex{F, D, A}(s::SliceIterator{F, D, A}, i::Integer)
    args = [j == D ? :(i) : :(Colon()) for j = 1:ndims(A)]
    return :(view(s.array, $(args...)))
end


# ~~~ Convenience functions for 2D arrays ~~~

"""
    columns(array)

Return a `SliceIterator` object to loop over the columns of `array`.

"""
columns(array::AbstractMatrix) = slices(array, Val{2})

"""
    rows(array)

Return a `SliceIterator` object to loop over the rows of `array`.

"""
rows(array::AbstractMatrix) = slices(array, Val{1})

end