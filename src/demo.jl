
using Revise
include("./agent/person.jl")
include("./input.jl")
include("./space/network.jl")

using .person
using .input
using Agents
using Graphs

function main()
    inputs = ReadInputs("./user_inputs_model.yaml")
    total_people = sum(values(inputs.InitialConditions.StageCounts))
    space = GraphSpace(SimpleGraph(total_people))
    properties = Dict(
        :inputs => inputs,
        :Time => 0.0,
        :Time_Increment => 1.0
        )
    model = ABM(Person, space; properties)

    add_people!(model)
    println("Added people")
    network.communitynetwork!(model, 2, 6, 1)

    adata = [:stage]

    agent_df = run!(
        model, 
        person.agent_step!, 
        network.model_step!, 
        100; 
        adata=adata, 
        agents_first=false)
    
    return agent_df
end

agent_df = main()

