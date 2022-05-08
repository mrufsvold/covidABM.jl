
using Revise
include("./agent/person.jl")
include("./input.jl")
include("./space/network.jl")

using .person
using .input
using Agents
using Graphs

const inputs = ReadInputs("./user_inputs_model.yaml")
const total_people = sum(values(inputs.InitialConditions.StageCounts))
space = GraphSpace(SimpleGraph(total_people))
properties = Dict(
    :inputs => inputs,
    :Time => 0.0
    )
model = ABM(Person, space; properties)

add_people!(model)
println("Added people")
network.communitynetwork!(model, 2, 6, 1)

