module person

using Agents
using StatsBase
using Random

include("../disease/progression.jl")
using .progression
include("../input.jl")
using .input
include("../disease/stages_enum.jl")

export Person, add_people!

@agent Person GraphAgent begin

	# Born is the number of hours prior to the start of the simulation that the person was born.
	Born::Float64

	# Demographic categorizes the Person into a risk category based on demograpics.
	Demographic::Tuple{Int64,Int64}

	# Prognosis is the pre-determined prognosis of the Person the disease is contracted.
	Prognosis::Dict{String, Float64}

	# HospitalNeed is a fixed feature of the Person and determines what resources of the hospital
	# the Person will use if the disease symptoms are severe.
	HospitalNeed::Dict{String, Float64}

	# Susceptability is how susceptable the person is to being exposed.
	# This could be changed to, for instance, model the use of masks.
	Susceptability::Float64

	# selfIsolating determines if the Person is presently self-isolating to avoid contact.
	# This stops the Person from transmitting to social and community networks.
	selfIsolating::Bool

	# The simulation hour when the Person should stop self-isolating.
	stopIsolating::Float64

	# TODO: people have a natural lifespan as well.
	# TODO: people birth new people

	# StartingStage is the starting disease stage of the Person.
	# This is for recording purposes only and does not affect the model.
	StartingStage::Int64

	# stage is the progression of the disease in the Person.
	stage::Int64

	# DiseaseProgression predetermines the amount of time the Person will spend in each stage
	# of the disease.
	# This bit is important to avoid collisions during a particular time step.
	# If A is infected and B is not, and A and B are connected in a network, then:
	#   - if A is processed first, A might transmit to B, then B might transmit to its network, and so on;
	#   - if B is processed first, then B will not transmit to its network.
	# To remove this potential ambiguity, the transition happens at the beginning of each Tick.
	DiseaseProgression::disease_schedule

	# lastTransition is when the last disease transition occured
	lastTransition::Float64

end

Person(id, pos; Born,Demographic,Prognosis,HospitalNeed,Susceptability,selfIsolating,stopIsolating,StartingStage,stage,DiseaseProgression,lastTransition) = Person(id, pos, Born,Demographic,Prognosis,HospitalNeed,Susceptability,selfIsolating,stopIsolating,StartingStage,stage,DiseaseProgression,lastTransition)



function set_age(age_cat::Tuple{Int64,Int64})::Float64
    # Return hours born before simulation
    years_old = rand(age_cat[1]:age_cat[2])
    return -years_old*365.25*24
end


function add_people!(model::AgentBasedModel)
	
    demoweights = StatsBase.weights([demo.Weight for demo in model.inputs.Demographics])
    stages_map = stage_enum.stages_map
    for (stage, count) in pairs(model.inputs.InitialConditions.StageCounts)
        stage_id = stages_map[stage]
        for n in 1:count
            # Sample a demographic
            demo = model.inputs.Demographics[StatsBase.sample(demoweights)]

            add_agent!(
                n, 
                model,
                Born = set_age(demo.Category),
                Demographic = demo.Category,
                Prognosis = demo.Prognosis,
                HospitalNeed = demo.HospitalNeeds,
                Susceptability = demo.Susceptibility,
                selfIsolating = false,
                stopIsolating = 0,
                StartingStage = stage_id,
                stage = stage_id,
                # TODO: figure out how the stage length works
                DiseaseProgression = disease_schedule(0,stage_id),
                lastTransition = 0
                )
        end
    end
end



function agent_step!(agent::Person, model::Agents.ABM)
	# Advance a person by a step in the simulation


	
end


end  