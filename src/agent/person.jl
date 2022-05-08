module person

using Agents
using StatsBase
using Random
using Graphs

include("../disease/progression.jl")
using .progression
include("../input.jl")
using .input
include("../disease/stages_enum.jl")
using .stage_enum
include("../utils.jl")
include("../input.jl")

export Person, add_people!

@agent Person GraphAgent begin

	# Born is the number of hours prior to the start of the simulation that the person was born.
	Born::Float64

	# Demographic categorizes the Person into a risk category based on demograpics.
	Demographic::Tuple{Int64,Int64}

	# Mortality is the mortality for this demographic
	Mortality::Float64

	# Prognosis is the pre-determined prognosis of the Person the disease is contracted.
	Prognosis::String

	# HospitalNeed is a fixed feature of the Person and determines what resources of the hospital
	# the Person will use if the disease symptoms are Severe.
	HospitalNeed::String

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

Person(id, pos; Born,Demographic,Mortality,Prognosis,HospitalNeed,Susceptability,selfIsolating,stopIsolating,StartingStage,stage,DiseaseProgression,lastTransition) = Person(id, pos, Born,Demographic,Mortality,Prognosis,HospitalNeed,Susceptability,selfIsolating,stopIsolating,StartingStage,stage,DiseaseProgression,lastTransition)


"Pick a random age within a category band"
function set_age(age_cat::Tuple{Int64,Int64})::Float64
    # Return hours born before simulation
    years_old = rand(age_cat[1]:age_cat[2])
    return -years_old*365.25*24
end

"Take a dictionary of category => weight pairs and return a random choice from a
weighted sample."
function pick_key_by_weights(cats::Dict{String, Float64})
	sample(collect(keys(cats)),StatsBase.Weights(collect(values(cats))))
end


"Load a model with Person agents according to the Input file."
function add_people!(model::AgentBasedModel)
	
	# Build the weights for each demographic group
    demoweights = StatsBase.weights([demo.Weight for demo in model.inputs.Demographics])
	# Get the Disease stage names
    stages = stage_enum.stages

	# Iterate through each stage that has counts at the beginning of the simulation
    for (stage, count) in pairs(model.inputs.InitialConditions.StageCounts)
		# Convert stage to an Int based on its index
        stage_id = utils.indexin(stage, stages)

        for n in 1:count
            # Set up prereq characteristics
            demo = model.inputs.Demographics[StatsBase.sample(demoweights)]
			prognosis = pick_key_by_weights(demo.Prognosis)
			next_stage = get_next_stage(stage, prognosis, demo.Mortality)
			start_progression = disease_schedule(
				pickduration(stage, next_stage, model.inputs.Disease.Duration),
				next_stage
			)
			# Plug characteristics into a new person
            add_agent!(
                n, 
                model,
                Born = set_age(demo.Category),
                Demographic = demo.Category,
				Mortality = demo.Mortality,
                Prognosis = prognosis,
                HospitalNeed = pick_key_by_weights(demo.HospitalNeeds),
                Susceptability = demo.Susceptibility,
                selfIsolating = false,
                stopIsolating = 0,
                StartingStage = stage_id,
                stage = stage_id,
                DiseaseProgression = start_progression,
                lastTransition = 0
                )
        end
    end
end


"Step the agent forward in the simulation"
function agent_step!(agent::Person, model::Agents.ABM)
	# Advance a person by a step in the simulation
	stage = stage_name(agent.stage)

	# No action needed for dead or recovered agents
	if stage in ["Dead", "Recovered"]
		return
	end

	# Check to see if suscpetable agent gets infected
	if stage == "Susceptable" && infect!(agent, model)
		setprogression!(agent, model)
		return
	end

	# Move the agent forward in progression if it is time
	if agent.DiseaseProgression.When >= model.Time
		setprogression!(agent,model)
	end

end


"Check neighbors for sick people, randomly choose to infect"
function infect!(agent::Person, model::Agents.ABM)::Bool
	agent_neighbors = neighbors(model.space.graph, agent.pos)
	infect = false
	for an in agent_neighbors
		if in(model[an].stage, stage_enum.infectious) && ~model[an].selfIsolating
			probabilty::Float64 = agent.Susceptability * model.inputs.Disease.TransmissionProbabilities.Social
			infect = infect | utils.boolsample(probabilty, 1.0 - probabilty)
		end
	end	
	if infect
		agent.stage += 1
	end

	return infect
end


"Use a current stage and a next stage to randomly choose a duration for this stage"
function pickduration(from_stage::String, to_stage::String, durationmodels::Vector)::Float64
	if from_stage == "Susceptable" && to_stage == "Exposed"
		return Inf
	end

	model = get_duration_model(from_stage, to_stage, durationmodels)
	
	if model.Kind == "LogNormalDelay"
		# [TODO] actually sample from the correct distribution shape
		return model.Mean
	end
	
	throw(ErrorException("No match for distribution type in $model"))
end
function pickduration(from_stage::String, to_stage::Int64, durationmodels::Vector)
	pickduration(from_stage, stage_name(to_stage), durationmodels)
end


"Search through the list of duration models to find the one that matches this
pair of stages"
# TODO This would be much more efficient if this was a dictionary that mapped
# To and from stages to duration details
function get_duration_model(from_stage::String, to_stage::String, durationmodels::Vector)
	for dur in durationmodels
		if dur.From == from_stage && dur.To == to_stage
			return dur.Model
		end
	end
	throw(ErrorException(
			"No duration model for progressing from $from_stage to $to_stage"
		))
end


"Find the upcoming stage based on the current stage"
function get_next_stage(current_stage::String, prognosis::String, mortality::Float64)::Int64
	if current_stage == "Susceptable"
		return stage_idx("Exposed")
	elseif current_stage == "Exposed"
		return stage_idx("Asymptomatic")
	elseif current_stage == "Asymptomatic"
		return stage_idx(prognosis)
	elseif current_stage == "Severe" || current_stage == "Symptomatic"
		new_status = utils.boolsample(mortality) ? "Dead" : "Recovered"
		return stage_idx(new_status)
	end
end


"Move the person to the next stage in the disease"
function setprogression!(agent::Person, model::Agents.ABM)
	# Get the predetermined upcoming stage
	next_stage = stage_name(agent.DiseaseProgression.Stage)

	if next_stage == "Recovered"
		updateagent!(agent, next_stage, model.Time, Inf, stage_idx("Recovered"))
		return
	end
	# Get the stage that we will change to next
	target_stage = get_next_stage(next_stage, agent.Prognosis, agent.Mortality)
	# Set a time for the next progression
	nextprogression = model.Time + pickduration(next_stage,target_stage,model.inputs.Disease.Duration)
	updateagent!(agent, next_stage, model.Time, nextprogression, target_stage)
end


function updateagent!(agent::Person, stage::String, time::Float64, nextprogression::Float64, target_stage::Int64)
	agent.stage = stage_idx(stage)
	agent.lastTransition = time
	agent.DiseaseProgression = progression.disease_schedule(nextprogression, target_stage)
end


end  