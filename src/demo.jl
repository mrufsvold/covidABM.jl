
include("./agent/person.jl")
include("./input.jl")

using .person
using .input
using Agents
using Graphs

const inputs = ReadInputs("./user_inputs_model.yaml")
const total_people = sum(values(inputs.InitialConditions.StageCounts))
space = GraphSpace(SimpleGraph(total_people))
properties = Dict(:inputs => inputs)
model = ABM(Person, space; properties)
