module input
using YAML

export ReadInputs, Inputs

struct simulation
    Duration::              Float64 #yaml:"duration" flag:"duration|4320.|Length of simulation in hours"
    Seed::                  UInt64  #yaml:"seed" flag:"seed|0|Random seed"
    MinimumActiveAgents::   Int64   #yaml:"minimumActiveAgents"
    Patience::              Int64   #yaml:"patience"
end # yaml:"simulation"


struct world
    step::      Float64             #yaml:"step" flag:"step|24.|Simulation time step in hours"
    Resources:: Dict{String,Int64}  #yaml:"resources"
end


struct initialconditions 
    StageCounts::Dict{String,Int64} # yaml:"stageCounts"
end # yaml:"initialConditions"

struct durationmodel
    Kind::  String
    Mean::  Float64
    Std::   Float64
end

struct duration
    From::  String  #yaml:"from"
    To::    String  #yaml:"to"
    Model:: durationmodel 
end
duration(from::String, to::String, model::Dict{Any, Any}) = duration(from, to, durationmodel(model["Kind"], model["Mean"], model["Std"]))

struct disease
    NetworkTransmissionProbabilities:: Dict{String, Float64} #yaml:"transmissionProbabilities"
    
    Duration:: Array{duration} # yaml:"durations"

end #yaml:"disease"
function disease(transprob::Dict{Any, Any}, durations::Vector{Dict{Any, Any}})
    duration_vec::Array{duration} = [duration(d["from"], d["to"], d["model"]) for d in durations]
    disease(transprob, duration_vec)
end



struct demographics
    Category::      Tuple{Int64, Int64}
    Weight::        Float64
    Susceptibility::Float64
    Prognosis::     Dict{String, Float64}
    Mortality::     Float64
    HospitalNeeds:: Dict{String, Float64}
end
function demographics(category::Vector{Int64},w,s,p,m,h)
    demographics(tuple(category...), w,s,p,m,h)
end

struct Inputs
    Simulation::simulation
    World::world
    InitialConditions::initialconditions
    Disease::disease
    Demographics::Array{demographics}
end
function Inputs(data::Dict)
    sim = simulation(
        data["simulation"]["duration"],
        data["simulation"]["seed"],
        data["simulation"]["minimumActiveAgents"],
        data["simulation"]["patience"]
    )
    wor = world(
        data["world"]["step"],
        data["world"]["resources"]
    )

    initcond = initialconditions(
        data["initialConditions"]["stageCounts"]
    )

    dis = disease(
        data["disease"]["transmissionProbabilities"],
        data["disease"]["durations"]
    )

    demos::Array{demographics} = [
        demographics(
            d["category"],
            d["weight"],
            d["susceptability"],
            d["prognosis"],
            d["mortality"],
            d["hospitalNeeds"]
         ) for d in data["demographics"]
    ]

    Inputs(
        sim,
        wor,
        initcond,
        dis,
        demos
    )
end


function  ReadInputs(fp::String)
    data = YAML.load_file(fp)
    Inputs(data)
    
end

end