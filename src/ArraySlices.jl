module ArraySlices

import Base: start, next, done, length, size, eltype

export slices, columns, rows

#=
# T : data eltype
# N : dimension of slices
# D : indexed dimension
# P : parent array
=#
immutable SliceIterator{T, N, D, P<:AbstractArray}
    parent::P
    function SliceIterator(parent::AbstractArray{T}, d::Integer)
        1 <= d <= ndims(parent) || error("invalid slice dimension")
        new(parent)
    end
end
slices{T, N}(parent::AbstractArray{T, N}, d::Integer) = 
    SliceIterator{T, N-1, d, typeof(parent)}(parent, d)

length{T, N, D}(s::SliceIterator{T, N, D}) = size(s.parent, D)
size{T, N, D}(s::SliceIterator{T, N, D}) = (size(s.parent, D), )

# Iteration interface
start(s::SliceIterator) = 1
done{T, N, D}(s::SliceIterator{T, N, D}, state) = (state == size(s.parent, D)+1)

# Build code that produces slices with the correct indexing
@generated function next{T, N, D}(s::SliceIterator{T, N, D}, state)
    # index over columns of a matrix -> slice(s.parent, :, state)
    # index over rows    of a matrix -> slice(s.parent, state, :)
    expr = :()
    expr.head = :call                        
    push!(expr.args, :slice)
    push!(expr.args, :(getfield(s, :parent)))
    for i = 1:(N+1)
        push!(expr.args, Colon())
    end
    expr.args[2 + D] = :state # replace the indexed dimension
    :($expr, state + 1)
end

@generated function eltype{T, N, D}(s::SliceIterator{T, N, D})
    # :(SubArray{T, N, Array{T, N+1}, NTuple{N+1, Union{Int, Colon}}}, LD})
    expr = :()
    expr.head = :curly
    push!(expr.args, :SubArray)
    push!(expr.args, T)
    push!(expr.args, N)
    push!(expr.args, Array{T, N+1})
    tupexpr = :()
    tupexpr.head = :curly
    push!(tupexpr.args, :Tuple)
    for i = 1:(N+1) 
        push!(tupexpr.args, :Colon)
    end
    tupexpr.args[1+D] = Int
    push!(expr.args, tupexpr)
    D == 1 ? push!(expr.args, N+1) : push!(expr.args, D)
    expr
end

# convenience functions for 2D arrays
columns(parent::AbstractMatrix) = slices(parent, 2)
rows(parent::AbstractMatrix) = slices(parent, 1)

end