__precompile__()
module ArraySlices

import Base: start, next, done, length, size, eltype, getindex

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

"""
    slices(array, dim)

Return a `SliceIterator` object to loop over the slices of `array` along
dimension `dim`. 

"""
@generated function slices{T, N, D}(array::AbstractArray{T, N}, ::Type{Val{D}})
    # checks
    1 <= D <= N || error("invalid slice dimension")
    
    # construct incomplete type of slice, then fill
    F = :(SubArray{$T, $N-1, typeof(array)})
    
    # construct tuple of indices
    tupexpr = :(Tuple{})
    for i = 1:N 
        push!(tupexpr.args, :Colon)
    end
    tupexpr.args[1+D] = Int
    push!(F.args, tupexpr)
    
    # add LD parameter
    D == 1 ? push!(F.args, N) : push!(F.args, D)

    # build and return iterator
    :(SliceIterator{$F, $D, typeof(array)}(array))
end

# allow creating slices without the Val{d} business
slices(array::AbstractArray, d::Integer) = slices(array, Val{d})



# ~~~ Array interface ~~~
eltype{F}(s::SliceIterator{F}) = F
length{F, D}(s::SliceIterator{F, D}) = size(s.array, D)
size(s::SliceIterator) = (length(s), )

# build code that produces slices with the correct indexing
@generated function getindex{F, D}(s::SliceIterator{F, D}, i::Integer)
    # get ndims of parent array
    N = s.parameters[1].parameters[3].parameters[2]
    expr = :()
    expr.head = :call
    push!(expr.args, :slice)
    push!(expr.args, :(getfield(s, :array)))
    # fill in with `Colon`s
    for i = 1:N 
        push!(expr.args, Colon())
    end
    # then replace the indexed dimension
    expr.args[2 + D] = :i 
    expr
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