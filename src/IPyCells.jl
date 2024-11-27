"""
Created in April, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This softwcell.idare is MIT-licensed.
### IPyCells.jl
IPyCells is a multi-format cell-reader for Julia with parametric `Cell` types. This 
package is able to read `.jl` (Pluto, Olive, and Julia) and `.ipynb` files into a `Vector{Cell}` as well as
save them to a `.jl` or `.ipynb` file. There are also quick conversion methods for quickly converting 
a `.ipynb` or `.jl` file.
```julia
using IPyCells: ipyjl, jlipy
# ipython to julia:
ipyjl("sourcefile.ipynb", "outputfile.jl")

# julia back to ipython, using our output file.
jlipy("outputfile.jl", "outputfile2.ipynb")
```
###### contents
```julia
# * means "exported"
# Cells
AbstractCell
Cell*
string(cell::Cell{<:Any})*
string(cell::Cell{:markdown})*
getindex(v::Vector{Cell{<:Any}}, s::String)*
# RW
plto_cell_lines(raw::String)
parse_pluto(raw::String)
read_pluto(uri::String)
parse_olive(str::String)
read_olive(uri::String)
parse_julia(raw::String)
# read JL discerns whether or not the `.jl` file is `Pluto` or `Olive`. It will work with any 
#   `.jl` file and calls `parse_pluto`/`parse_olive`/`parse_julia`.
read_jl(uri::String)
# saves to `.jl` -- `Olive` cells by default. `raw` will enable regular Julia source cells.
save(cells::Vector{<:AbstractCell}, path::String; raw::Bool = false)
# saves to .ipynb for `IJulia`
save_ipynb(cells::Vector{<:AbstractCell}, path::String)
read_ipynb(f::String)
ipyjl(ipynb_path::String, output_path::String)*
jlipy(jl_path::String, output_path::String)*
```
"""
module IPyCells
import Base: string, read, getindex
using JSON
using UUIDs
using Random

__precompile__()

"""
```julia
abstract type AbstractCell
```
A `Cell` is a type created to hold cell-data for various different types of notebooks. 
The largest consistencies amongst abstract cells is that they contain source, ID, and outputs --
and are able to be indexed by ID.
- id::String
- source::String
- outputs::Any
"""
abstract type AbstractCell end

"""
```julia
Cell{T <: Any} <: AbstractCell
```
- id::String
- outputs::Any - Output of the cell
- type::String - Cell type (code/md)
- source::String - The content of the cell
- n::Integer - The execution position of the cell.
```julia
Cell{T}(source::String = "", outputs::Any = ""; id::String = "") where {T <: Any}
```
"""
mutable struct Cell{T <: Any} <: AbstractCell
    id::String
    source::String
    outputs::Any
    function Cell{T}(source::String = "", outputs::Any = ""; id::String = "") where {T <: Any}
        if id == ""
            Random.seed!(rand(1:100000))
            id = randstring(5)
        end
        new{Symbol(T)}(id, source, outputs)::Cell{T}
    end
    Cell(ctype::String = "code", source::String = "", outputs::Any = ""; id::String = "") = begin
        Cell{Symbol(ctype)}(source, outputs, id = id)
    end
end

"""
```julia
string(cell::Cell{<:Any}) -> ::String
```
Converts a cell to a `String`. Used by `IPy.save` to write different cell types.
### example
```julia
cells = read_plto("myfile.jl")

cells_as_strings = join(string(cell) for cell in cells)
```
"""
function string(cell::Cell{<:Any})
    celltype::String = string(typeof(cell).parameters[1])
    return(*(cell.source, "\n#==output[$celltype]\n$(string(cell.outputs))\n==#\n#==|||==#\n"))::String
end

function string(cell::Cell{:markdown})
    "\"\"\"$(cell.source)\"\"\"\n#==|||==#\n"::String
end

function string(cell::Cell{:doc})
        "\"\"\"\n$(cell.source)\n\"\"\""
end

function getindex(v::Vector{Cell{<:Any}}, s::String)
        v[findall(c -> c.id == s, v)[1]]
end

include("IPyRW.jl")

export ipyjl, jlipy
end # module
