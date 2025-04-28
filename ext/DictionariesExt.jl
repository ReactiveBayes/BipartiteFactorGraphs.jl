module DictionariesExt

using BipartiteFactorGraphs
using Dictionaries
using Base: AbstractDict, getindex, setindex!, delete!, haskey, get, get!, isempty, length, iterate, keys, values

"""
    DictionariesJLWrapper{K,V,D <: AbstractDictionary{K,V}} <: AbstractDict{K,V}

A wrapper around Dictionaries.jl's `AbstractDictionary` type that implements the `AbstractDict` interface.
This allows using Dictionaries.jl's performance benefits while maintaining compatibility with
Julia's standard dictionary interface.
"""
struct DictionariesJLWrapper{K, V, D <: AbstractDictionary{K, V}} <: AbstractDict{K, V}
    dict::D
end

function DictionariesJLWrapper{K, V, D}() where {K, V, D <: AbstractDictionary{K, V}}
    return DictionariesJLWrapper{K, V, D}(D())
end

# AbstractDict interface implementation
Base.getindex(d::DictionariesJLWrapper, key) = getindex(d.dict, key)
Base.setindex!(d::DictionariesJLWrapper, value, key) = set!(d.dict, key, value)
Base.delete!(d::DictionariesJLWrapper, key) = delete!(d.dict, key)
Base.haskey(d::DictionariesJLWrapper, key) = haskey(d.dict, key)
Base.get(d::DictionariesJLWrapper, key, default) = get(d.dict, key, default)
Base.get!(d::DictionariesJLWrapper, key, default) = get!(d.dict, key, default)
Base.isempty(d::DictionariesJLWrapper) = isempty(d.dict)
Base.length(d::DictionariesJLWrapper) = length(d.dict)

# Iteration
function Base.iterate(d::DictionariesJLWrapper)
    state = iterate(d.dict)
    state === nothing && return nothing
    (k, v), next_state = state
    return (k => v, next_state)
end

function Base.iterate(d::DictionariesJLWrapper, state)
    state = iterate(d.dict, state)
    state === nothing && return nothing
    (k, v), next_state = state
    return (k => v, next_state)
end

# Keys and values
Base.keys(d::DictionariesJLWrapper) = keys(d.dict)
Base.values(d::DictionariesJLWrapper) = values(d.dict)

# Show
Base.show(io::IO, d::DictionariesJLWrapper) = show(io, d.dict)
Base.show(io::IO, ::MIME"text/plain", d::DictionariesJLWrapper) = show(io, MIME"text/plain"(), d.dict)

BipartiteFactorGraphs.make_dict_type(::Type{D}, ::Type{K}, ::Type{V}) where {D <: Dictionaries.AbstractDictionary, K, V} = DictionariesJLWrapper{
    K, V, D{K, V}
}

end # module DictionariesExt
