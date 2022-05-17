module stage_enum
include("../utils.jl")
export stage_name, stage_idx
const stages = (
    "Susceptable",
    "Exposed" ,
    "Asymptomatic" ,
    "Symptomatic" ,
    "Severe" ,
    "Recovered",
    "Dead"
)

const infectious = (
    "Asymptomatic" ,
    "Symptomatic" 
)

"Get the stage string from an index of the stage_enum"
stage_name(s::Int64)::String = stage_enum.stages[s]
"Get the index of a stage from its name."
stage_idx(s::String)::Int64 = utils.indexin(s,stage_enum.stages)


end

