

const OPTIONS = [
	"NoSpecialNeeds",
	"NeedsICU",
	"NeedsVentilator"
]

function HospitalNeed(need::String)::String
	if occursin(need, OPTIONS)
		return need
	else throw(DomainError(need, "Need must be one of the $OPTIONS")) end
end

