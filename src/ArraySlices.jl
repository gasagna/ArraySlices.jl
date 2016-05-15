module ArraySlices

import Base: start, next, done, length, size, eltype, getindex

export slices, columns, rows

# Type parameters
# 
# F : a SubArray
# N : ndims of the slices
# D : indexed dimension of the parent
# P : parent array type
# 
immutable SliceIterator{F, N, D, P<:AbstractArray} <: AbstractVector{F}
    parent::P
end

@generated function slices{T, N, D}(parent::AbstractArray{T, N}, ::Type{Val{D}})
    1 <= D <= N || error("invalid slice dimension")
    
    # ~~~ Construct type of slice - incomplete, then fill
    F = :(SubArray{$T, $N-1, typeof(parent)})
    
    # construct tuple of indexes 
    tupexpr = :(Tuple{})
    for i = 1:N 
        push!(tupexpr.args, :Colon)
    end
    tupexpr.args[1+D] = Int
    push!(F.args, tupexpr)
    
    # add LD parameter
    D == 1 ? push!(F.args, N) : push!(F.args, D)

    # build and return iterator
    :(SliceIterator{$F, $N-1, $D, typeof(parent)}(parent))
end
# allow creating slices without the Val{d} business
slices(parent::AbstractArray, d::Integer) = slices(parent, Val{d})

# Array interface
eltype{F}(s::SliceIterator{F}) = F
length{F, N, D}(s::SliceIterator{F, N, D}) = size(s.parent, D)
size{F, N, D}(s::SliceIterator{F, N, D}) = (size(s.parent, D), )
@generated function getindex{F, N, D}(s::SliceIterator{F, N, D}, i::Integer)
    # Build code that produces slices with the correct indexing
    expr = :()
    expr.head = :call                        
    push!(expr.args, :slice)
    push!(expr.args, :(getfield(s, :parent)))
    for i = 1:(N+1) # fill in with `Colon`s
        push!(expr.args, Colon())
    end
    expr.args[2 + D] = :i # replace the indexed dimension
    expr
end

# convenience functions for 2D arrays
columns(parent::AbstractMatrix) = slices(parent, Val{2})
rows(parent::AbstractMatrix) = slices(parent, Val{1})

end