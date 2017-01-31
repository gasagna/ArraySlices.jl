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
@generated function slices{T, N, D}(array::AbstractArray{T, N}, ::Type{Val{D}})
    # checks
    1 <= D <= N || error("invalid slice dimension")

    # construct incomplete type of slice, then fill
    # example: SubArray{Float64, 1, Array{Float64,2}, Tuple{Int64, Colon}, true}
    F = :(SubArray{$T, $(N-1), $array})
    
    # construct tuple of indices
    tupexpr = :(Tuple{})
    for i = 1:N 
        push!(tupexpr.args, :Colon)
    end
    tupexpr.args[1+D] = :Int
    push!(F.args, tupexpr)
    
    # add L/LD parameter
    push!(F.args, _get_L(D, N))

    # build and return iterator
    :(SliceIterator{$F, $D, $array}(array))
end

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
    push!(expr.args, :view)
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